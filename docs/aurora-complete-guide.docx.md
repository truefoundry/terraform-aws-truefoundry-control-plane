**Aurora Global Database — Setup, Migration & DR Guide**

TrueFoundry Platform Engineering · March 2026


|          |                      |
| -------- | -------------------- |
| Version  | 1.0                  |
| Audience | Platform Engineering |
| Status   | Internal — Draft     |


# 1. Overview

The module supports two database engine modes via `truefoundry_db_engine_mode`:


| Mode            | Engine              | Use Case                                                     |
| --------------- | ------------------- | ------------------------------------------------------------ |
| `rds` (default) | Standard PostgreSQL | Single-region, cost-effective                                |
| `aurora`        | Aurora PostgreSQL   | Higher availability, read replicas, optional multi-region DR |


When `aurora` is selected, you can optionally enable Aurora Global Database with a secondary cluster in a DR region. The module also deploys an automated failover pipeline (CloudWatch → EventBridge → Lambda → SNS) in the DR region.


| Important: Switching from `rds` to `aurora` destroys the existing RDS instance. Migrate data first. |
| --------------------------------------------------------------------------------------------------- |


## 1.1 Architecture


| Component              | Description                                                   |
| ---------------------- | ------------------------------------------------------------- |
| Primary Cluster        | Writer — all application writes go here                       |
| Secondary Cluster (DR) | Read-only replica, ready to promote on failover               |
| Global Cluster         | Manages replication between primary and secondary             |
| Failover Pipeline      | CloudWatch alarm + Lambda in DR region for automated failover |


Both the primary and secondary clusters use the same master credentials. After failover, the promoted secondary keeps the same username and password.

# 2. Fresh Deployment

## 2.1 Single-Region Aurora

```hcl
module "control_plane" {
  source = "truefoundry/truefoundry-control-plane/aws"
  providers = {
    aws           = aws
    aws.secondary = aws  # unused — pass default
  }

  truefoundry_db_engine_mode             = "aurora"
  truefoundry_db_subnet_ids              = var.subnet_ids
  truefoundry_db_ingress_security_group  = var.eks_sg
  truefoundry_aurora_engine_version      = "17.4"
  truefoundry_aurora_instance_class      = "db.r6g.large"
  truefoundry_aurora_instance_count      = 2
  # ... other required variables
}
```

## 2.2 Aurora Global (Multi-Region DR)

```hcl
provider "aws" { region = "us-east-1" }
provider "aws" { alias = "dr"; region = "eu-west-1" }

module "control_plane" {
  source = "truefoundry/truefoundry-control-plane/aws"
  providers = {
    aws           = aws
    aws.secondary = aws.dr
  }

  truefoundry_db_engine_mode                = "aurora"
  truefoundry_aurora_enable_global_cluster  = true
  truefoundry_aurora_alert_email            = "oncall@yourdomain.com"

  truefoundry_aurora_secondary_config = {
    cluster_identifier  = "my-cluster-aurora-dr"
    vpc_id              = var.dr_vpc_id
    subnet_ids          = var.dr_subnet_ids
    ingress_cidr_blocks = ["10.0.0.0/16"]  # DR VPC CIDR
  }
  # ... other required variables
}
```


| Security groups are region-scoped. You cannot use primary-region SG IDs in the secondary config. Use `ingress_cidr_blocks` with the DR VPC CIDR instead. |
| -------------------------------------------------------------------------------------------------------------------------------------------------------- |


# 3. Migrating from RDS to Aurora


| Approach                      | Downtime                   | Best For              |
| ----------------------------- | -------------------------- | --------------------- |
| Option A: pg_dump/restore     | Full dump + restore time   | Small DBs, dev/test   |
| Option B: Aurora Read Replica | 2–5 minutes (cutover only) | Production, large DBs |


## Option A: pg_dump/restore

```bash
# 1. Snapshot for safety
aws rds create-db-snapshot \
  --db-instance-identifier $(terraform output -raw truefoundry_db_id) \
  --db-snapshot-identifier pre-aurora-migration-$(date +%Y%m%d)

# 2. Stop writes, export data
pg_dump -h <rds-endpoint> -U root -d ctl -F c -f backup.dump

# 3. Switch Terraform to aurora mode, apply
#    truefoundry_db_engine_mode = "aurora"
terraform apply

# 4. Restore into Aurora
pg_restore -h <aurora-endpoint> -U root -d ctl backup.dump

# 5. Validate
terraform output truefoundry_db_endpoint
```

## Option B: Aurora Read Replica (Near-Zero Downtime)


| Requirement: RDS and Aurora versions must be in the same major version family. Source must not already have an Aurora read replica. |
| ----------------------------------------------------------------------------------------------------------------------------------- |


```bash
# 1. Create Aurora replica from RDS (outside Terraform)
aws rds create-db-cluster \
  --db-cluster-identifier my-cluster-aurora \
  --engine aurora-postgresql --engine-version 17.4 \
  --db-subnet-group-name <existing-subnet-group> \
  --vpc-security-group-ids <existing-security-group> \
  --replication-source-identifier arn:aws:rds:<region>:<account>:db/<rds-id>

aws rds create-db-instance \
  --db-cluster-identifier my-cluster-aurora \
  --db-instance-class db.r6g.large \
  --db-instance-identifier my-cluster-aurora-1 \
  --engine aurora-postgresql

# 2. Wait for replication lag = 0, stop writes, promote
aws rds promote-read-replica-db-cluster \
  --db-cluster-identifier my-cluster-aurora

# 3. Remove old RDS from Terraform state
terraform state rm 'module.control_plane.aws_db_instance.truefoundry_db[0]'
terraform state rm 'module.control_plane.aws_db_parameter_group.truefoundry_db_parameter_group[0]'

# 4. Import the promoted Aurora cluster + instance
terraform import 'module.control_plane.aws_rds_cluster.truefoundry_aurora[0]' my-cluster-aurora
terraform import 'module.control_plane.aws_rds_cluster_instance.truefoundry_aurora[0]' my-cluster-aurora-1

# 5. Switch config to aurora, apply — module creates everything else
#    (global cluster, secondary, failover pipeline, parameter groups)
terraform apply
```


| Tip: You only need to import the Aurora cluster and instance. The module creates all other resources (global cluster, secondary, failover automation) automatically on the next apply. |
| -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |


Match `truefoundry_aurora_engine_version` and `truefoundry_aurora_instance_class` to exactly what you created in AWS. Run `terraform plan` first — never apply if any cluster resource shows "must be replaced".

# 4. Failover


| Approach                        | RTO       | RPO        | Human Required? |
| ------------------------------- | --------- | ---------- | --------------- |
| Planned switchover              | Minutes   | Zero       | Yes             |
| Manual failover                 | 14–60 min | < 1 second | Yes             |
| Automated (CloudWatch + Lambda) | ~5 min    | < 1 second | No              |


## 4.1 Planned Switchover (Zero Data Loss)

Both regions must be alive. Aurora waits for replication lag = 0 before switching.

```bash
aws rds switchover-global-cluster \
  --global-cluster-identifier $(terraform output -raw truefoundry_aurora_global_cluster_id) \
  --target-db-cluster-identifier <dr-cluster-identifier>
```

## 4.2 Unplanned Failover (Manual)

```bash
aws rds failover-global-cluster \
  --global-cluster-identifier $(terraform output -raw truefoundry_aurora_global_cluster_id) \
  --target-db-cluster-identifier $(terraform output -raw truefoundry_aurora_secondary_cluster_id) \
  --allow-data-loss --region eu-west-1
```


| After failover: Restart application pods to flush stale database connections. |
| ----------------------------------------------------------------------------- |


## 4.3 Automated Failover

Enabled automatically when `truefoundry_aurora_enable_global_cluster = true` and `truefoundry_aurora_secondary_config` is set. The pipeline runs entirely in the DR region:


| Stage        | Time          | What Happens                                                         |
| ------------ | ------------- | -------------------------------------------------------------------- |
| Detection    | T+0 to T+3min | CloudWatch detects missing replication lag metric                    |
| Trigger      | T+3min        | EventBridge fires, Lambda invoked                                    |
| Failover     | T+3 to T+5min | Lambda runs `failover-global-cluster`, waits for DR to become writer |
| Notification | T+5min        | SNS email confirms failover complete                                 |


Configure with:

```hcl
truefoundry_aurora_alert_email              = "oncall@yourdomain.com"
truefoundry_aurora_alarm_evaluation_periods = 3  # minutes before alarm fires
```

Test the Lambda safely (it skips if DR is already writer):

```bash
# Get the test command from Terraform output
terraform output -raw truefoundry_aurora_failover_test_command
```


| The alarm may fire immediately after first apply because there's no historical metric data. It resolves automatically within 2-3 minutes once Aurora starts reporting. |
| ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- |


# 5. Networking

Aurora replication uses AWS's private storage-layer backbone — it does not route through VPCs. However, your application pods need cross-region connectivity if they must reach the DR cluster after failover.

If your VPCs are already connected (Transit Gateway, existing peering, VPN), no action needed. If not, the `examples/complete/` includes optional VPC peering — enable with `create_vpc_peering = true`.

# 6. Cost


| Component                            | Cost                  | Notes                                |
| ------------------------------------ | --------------------- | ------------------------------------ |
| DR Aurora Cluster                    | Same as primary       | Dominant cost — doubles Aurora spend |
| Global replication                   | ~$0.20/GB replicated  | Low writes ~$6/mo, high ~$300/mo     |
| VPC Peering data transfer            | $0.02/GB cross-region | Only if app queries DR directly      |
| Automation (Lambda, CloudWatch, SNS) | ~$0.10/month total    | Negligible                           |


# 7. Variable Reference


| Variable                                      | Type         | Default          | Description                          |
| --------------------------------------------- | ------------ | ---------------- | ------------------------------------ |
| `truefoundry_db_engine_mode`                  | string       | `"rds"`          | `"rds"` or `"aurora"`                |
| `truefoundry_aurora_engine_version`           | string       | `"17.4"`         | Aurora PostgreSQL version            |
| `truefoundry_aurora_instance_class`           | string       | `"db.r6g.large"` | Instance class                       |
| `truefoundry_aurora_instance_count`           | number       | `1`              | Number of cluster instances          |
| `truefoundry_aurora_cloudwatch_log_exports`   | list(string) | `["postgresql"]` | Log exports                          |
| `truefoundry_aurora_enable_global_cluster`    | bool         | `false`          | Enable global database               |
| `truefoundry_aurora_secondary_config`         | object       | `null`           | Secondary cluster config (see below) |
| `truefoundry_aurora_alert_email`              | string       | `""`             | Email for failover alerts            |
| `truefoundry_aurora_alarm_evaluation_periods` | number       | `3`              | Minutes before alarm fires           |


**Secondary config object** (all optional except first three):


| Field                        | Default          | Description                                    |
| ---------------------------- | ---------------- | ---------------------------------------------- |
| `cluster_identifier`         | *required*       | Unique name for secondary cluster              |
| `vpc_id`                     | *required*       | VPC in DR region                               |
| `subnet_ids`                 | *required*       | At least 2 subnets in DR region                |
| `instance_class`             | `"db.r6g.large"` | Can differ from primary                        |
| `instance_count`             | `1`              | Number of secondary instances                  |
| `ingress_cidr_blocks`        | `[]`             | DR VPC CIDR — recommended for cross-region     |
| `ingress_security_group_ids` | `[]`             | Must be SGs in the DR VPC only                 |
| `kms_key_id`                 | `null`           | Region-specific KMS key (auto-created if null) |


# 8. Output Reference

**Mode-aware** (returns RDS or Aurora values depending on engine mode):


| Output                    | Description                     |
| ------------------------- | ------------------------------- |
| `truefoundry_db_endpoint` | Connection endpoint (host:port) |
| `truefoundry_db_address`  | Hostname                        |
| `truefoundry_db_port`     | Port                            |
| `truefoundry_db_username` | Master username                 |
| `truefoundry_db_password` | Master password (sensitive)     |


**Aurora-specific:**


| Output                                          | Description                       |
| ----------------------------------------------- | --------------------------------- |
| `truefoundry_aurora_cluster_endpoint`           | Writer endpoint                   |
| `truefoundry_aurora_cluster_reader_endpoint`    | Reader endpoint                   |
| `truefoundry_aurora_global_cluster_id`          | Global cluster ID                 |
| `truefoundry_aurora_secondary_cluster_endpoint` | Secondary endpoint (read-only)    |
| `truefoundry_aurora_failover_lambda_name`       | Failover Lambda function name     |
| `truefoundry_aurora_failover_alarm_name`        | CloudWatch alarm name             |
| `truefoundry_aurora_failover_test_command`      | CLI command to test Lambda safely |


# 9. FAQ

**Can I switch from Aurora back to RDS?**
Yes. Change `truefoundry_db_engine_mode` back to `"rds"`. This destroys Aurora and creates RDS. Migrate data first.

**What happens to shared resources when switching engine modes?**
Subnet groups and security groups are shared. They are not recreated when switching.

**Can I use Aurora without a global cluster?**
Yes. Set `truefoundry_aurora_enable_global_cluster = false` and pass `aws.secondary = aws` (default provider).

**Can I add more than one secondary region?**
The module supports one secondary. For additional secondaries, use the `truefoundry_aurora_global_cluster_id` output with `aws_rds_cluster` directly.

**Why does the CloudWatch alarm fire immediately after apply?**
No historical metric data exists yet. `treat_missing_data = breaching` causes it to fire. It resolves within 2-3 minutes once Aurora starts reporting.

**After failover my app gets 'cannot execute INSERT in a read-only transaction'.**
Stale connection pool. Restart application pods to flush connections and reconnect via the new writer endpoint.