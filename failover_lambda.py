import json
import os
import time

import boto3

GLOBAL_CLUSTER = os.environ["GLOBAL_CLUSTER"]
DR_CLUSTER_ARN = os.environ["DR_CLUSTER_ARN"]
DR_REGION = os.environ["DR_REGION"]
SNS_TOPIC_ARN = os.environ["SNS_TOPIC_ARN"]

rds = boto3.client("rds", region_name=DR_REGION)
sns = boto3.client("sns", region_name=DR_REGION)


def publish(subject, message):
    try:
        sns.publish(TopicArn=SNS_TOPIC_ARN, Subject=subject[:100], Message=message)
    except Exception as e:
        print(f"SNS publish failed: {e}")


def handler(event, context):
    print(f"Event: {json.dumps(event)}")

    if event.get("source") == "manual-test":
        publish(
            "Failover Lambda Test",
            f"Manual test invocation. Global cluster: {GLOBAL_CLUSTER}, DR target: {DR_CLUSTER_ARN}",
        )
        return {"statusCode": 200, "body": "Test OK — no failover triggered"}

    try:
        resp = rds.describe_global_clusters(GlobalClusterIdentifier=GLOBAL_CLUSTER)
        members = resp["GlobalClusters"][0]["GlobalClusterMembers"]
        writer = next((m for m in members if m["IsWriter"]), None)

        if writer and writer["DBClusterArn"] == DR_CLUSTER_ARN:
            msg = f"DR cluster is already the writer. No failover needed."
            print(msg)
            publish("Failover Skipped", msg)
            return {"statusCode": 200, "body": msg}

    except Exception as e:
        print(f"Pre-check failed (proceeding with failover): {e}")

    try:
        print(f"Initiating failover to {DR_CLUSTER_ARN}")
        publish(
            "Aurora Failover STARTED",
            f"Initiating failover of {GLOBAL_CLUSTER} to {DR_CLUSTER_ARN} in {DR_REGION}",
        )

        rds.failover_global_cluster(
            GlobalClusterIdentifier=GLOBAL_CLUSTER,
            TargetDbClusterIdentifier=DR_CLUSTER_ARN,
        )

        for attempt in range(30):
            time.sleep(10)
            resp = rds.describe_global_clusters(
                GlobalClusterIdentifier=GLOBAL_CLUSTER
            )
            members = resp["GlobalClusters"][0]["GlobalClusterMembers"]
            writer = next((m for m in members if m["IsWriter"]), None)

            if writer and writer["DBClusterArn"] == DR_CLUSTER_ARN:
                msg = f"Failover complete. DR cluster {DR_CLUSTER_ARN} is now the writer."
                print(msg)
                publish("Aurora Failover COMPLETE", msg)
                return {"statusCode": 200, "body": msg}

            print(f"Waiting for failover... attempt {attempt + 1}/30")

        msg = "Failover initiated but did not complete within 5 minutes. Check AWS console."
        print(msg)
        publish("Aurora Failover TIMEOUT", msg)
        return {"statusCode": 202, "body": msg}

    except Exception as e:
        msg = f"Failover FAILED: {e}"
        print(msg)
        publish("Aurora Failover FAILED", msg)
        return {"statusCode": 500, "body": msg}
