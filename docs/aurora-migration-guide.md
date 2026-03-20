# Aurora Migration Guide

This guide covers how to use Aurora PostgreSQL with the TrueFoundry control plane module, including migrating from an existing RDS instance and setting up Aurora Global Database for disaster recovery.

## Table of Contents

- [Overview](#overview)
- [Option 1: Fresh Aurora Deployment](#option-1-fresh-aurora-deployment)
- [Option 2: Migrating from RDS to Aurora](#option-2-migrating-from-rds-to-aurora)
- [Option 3: Aurora Global Database (Multi-Region DR)](#option-3-aurora-global-database-multi-region-dr)
- [Variable Reference](#variable-reference)
- [Output Reference](#output-reference)
- [FAQ](#faq)

---

## Overview

The module supports two database engine modes controlled by `truefoundry_db_engine_mode`:


| Mode              | Engine              | Use case                                                     |
| ----------------- | ------------------- | ------------------------------------------------------------ |
| `"rds"` (default) | Standard PostgreSQL | Single-region, cost-effective                                |
| `"aurora"`        | Aurora PostgreSQL   | Higher availability, read replicas, optional multi-region DR |


When using Aurora, you can optionally enable Aurora Global Database to add a secondary cluster in a DR region.

> **Important**: Switching `truefoundry_db_engine_mode` from `"rds"` to `"aurora"` will **destroy the existing RDS instance and create a new Aurora cluster**. Data must be migrated separately before making this change. See [Option 2](#option-2-migrating-from-rds-to-aurora) for the full migration procedure.

---

## Option 1: Fresh Aurora Deployment

For new deployments where no existing RDS database exists.

### Single-Region Aurora

```hcl
module "control_plane" {
  source = "truefoundry/truefoundry-control-plane/aws"
  providers = {
    aws           = aws
    aws.secondary = aws  # pass default provider when not using global
  }

  cluster_name            = "my-cluster"
  cluster_oidc_issuer_url = var.oidc_url
  aws_region              = "us-east-1"
  aws_account_id          = var.account_id
  vpc_id                  = var.vpc_id

  truefoundry_db_enabled                 = true
  truefoundry_db_engine_mode             = "aurora"
  truefoundry_db_subnet_ids              = var.subnet_ids
  truefoundry_db_ingress_security_group  = var.eks_security_group_id
  truefoundry_aurora_engine_version      = "17.4"
  truefoundry_aurora_instance_class      = "db.r6g.large"
  truefoundry_aurora_instance_count      = 2  # writer + 1 reader

  # ... other variables
}
```

Key outputs:

- `truefoundry_db_endpoint` — connection string (host:port) for your application
- `truefoundry_aurora_cluster_reader_endpoint` — read-only endpoint for read replicas

---

## Option 2: Migrating from RDS to Aurora

This is a multi-step process. Terraform handles the infrastructure; you handle the data migration.

### Prerequisites

- An existing deployment using `truefoundry_db_engine_mode = "rds"`
- A maintenance window with acceptable downtime (or AWS DMS for near-zero downtime)
- The RDS and Aurora PostgreSQL major versions must be compatible

### Step 1: Record Current RDS Details

Before making any changes, capture your current database connection info:

```bash
terraform output truefoundry_db_endpoint
terraform output truefoundry_db_database_name
terraform output truefoundry_db_username
```

### Step 2: Create a Final RDS Snapshot

Create a manual snapshot as a safety net:

```bash
aws rds create-db-snapshot \
  --db-instance-identifier $(terraform output -raw truefoundry_db_id) \
  --db-snapshot-identifier pre-aurora-migration-$(date +%Y%m%d)
```

Wait for the snapshot to complete:

```bash
aws rds wait db-snapshot-available \
  --db-snapshot-identifier pre-aurora-migration-$(date +%Y%m%d)
```

### Step 3: Export Data from RDS

**Option A: pg_dump (simpler, requires downtime)**

```bash
# Stop your application to prevent writes
pg_dump -h <rds-endpoint> -U root -d ctl -F c -f backup.dump
```

**Option B: AWS DMS (near-zero downtime)**

Set up a DMS replication task with:

- Source: your RDS PostgreSQL instance
- Target: the Aurora cluster (created in Step 4)
- Migration type: full load + CDC (change data capture)

See [AWS DMS documentation](https://docs.aws.amazon.com/dms/latest/userguide/Welcome.html) for details.

### Step 4: Switch to Aurora

Update your Terraform configuration:

```hcl
module "control_plane" {
  # ...

  truefoundry_db_engine_mode        = "aurora"       # was "rds"
  truefoundry_aurora_engine_version = "17.4"
  truefoundry_aurora_instance_class = "db.r6g.large"
  truefoundry_aurora_instance_count = 1

  # ...
}
```

Review the plan carefully — it will show the RDS instance being destroyed and Aurora resources being created:

```bash
terraform plan
```

Verify the plan shows:

- `aws_db_instance.truefoundry_db[0]` will be **destroyed**
- `aws_rds_cluster.truefoundry_aurora[0]` will be **created**
- `aws_rds_cluster_instance.truefoundry_aurora[0]` will be **created**
- Shared resources (subnet group, security group) remain **unchanged**

Apply:

```bash
terraform apply
```

### Step 5: Restore Data into Aurora

**If you used pg_dump:**

```bash
pg_restore -h <aurora-endpoint> -U root -d ctl backup.dump
```

**If you used DMS:**

DMS handles the data transfer. Verify replication is complete, then stop the DMS task.

### Step 6: Update Application Connection String

The module outputs are mode-aware. After switching to Aurora:

- `truefoundry_db_endpoint` now returns the Aurora writer endpoint
- `truefoundry_db_address` now returns the Aurora cluster hostname

If your application reads these outputs, it will automatically point to Aurora after `terraform apply`.

### Step 7: Validate

```bash
# Verify the new endpoint
terraform output truefoundry_db_endpoint

# Connect and check data
psql -h $(terraform output -raw truefoundry_db_address) \
     -U root -d ctl -c "SELECT count(*) FROM <your_table>;"
```

---

## Option 2b: Near-Zero-Downtime Migration Using Aurora Read Replica

This method uses [AWS Aurora Read Replica migration](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.Migrating.RDSPostgreSQL.Replica.html) to migrate from RDS to Aurora with minimal downtime. The migration happens outside Terraform via the AWS Console/CLI, then you import the resulting resources into Terraform state.

**Requirements:**

- RDS and Aurora PostgreSQL versions must be in the same major version family
- Source RDS instance must not already have an Aurora read replica or cross-region read replica
- Both must be in the same AWS Region and account

### Step 1: Create Aurora Read Replica from RDS (AWS Console/CLI)

This step is done outside Terraform.

```bash
# Create the Aurora cluster as a replica of your RDS instance
aws rds create-db-cluster \
  --db-cluster-identifier my-cluster-aurora \
  --engine aurora-postgresql \
  --engine-version 17.4 \
  --db-subnet-group-name <your-existing-subnet-group> \
  --vpc-security-group-ids <your-existing-security-group> \
  --replication-source-identifier arn:aws:rds:<region>:<account>:db/<rds-instance-id>

# Create the primary instance in the Aurora cluster
aws rds create-db-instance \
  --db-cluster-identifier my-cluster-aurora \
  --db-instance-class db.r6g.large \
  --db-instance-identifier my-cluster-aurora-1 \
  --engine aurora-postgresql
```

Wait for the Aurora read replica to be available and replication lag to reach zero:

```bash
# Monitor replication lag
aws cloudwatch get-metric-statistics \
  --namespace AWS/RDS \
  --metric-name RDSToAuroraPostgreSQLReplicaLag \
  --dimensions Name=DBInstanceIdentifier,Value=my-cluster-aurora-1 \
  --start-time $(date -u -v-10M +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 60 --statistics Average
```

### Step 2: Stop Writes and Promote the Aurora Cluster

```bash
# 1. Stop all write workload on the RDS instance

# 2. Verify LSN is caught up on the Aurora replica
psql -h <aurora-endpoint> -U root -d ctl -c "SELECT pg_last_wal_replay_lsn();"

# 3. Promote the Aurora cluster
aws rds promote-read-replica-db-cluster \
  --db-cluster-identifier my-cluster-aurora
```

Wait for promotion to complete — the Aurora cluster becomes a standalone read-write cluster.

### Step 3: (Optional) Create Global Cluster and Secondary

If you want Aurora Global Database, create it from the promoted cluster:

```bash
# Create global cluster from the existing Aurora cluster
aws rds create-global-cluster \
  --global-cluster-identifier my-cluster-aurora-global \
  --source-db-cluster-identifier arn:aws:rds:<region>:<account>:cluster/my-cluster-aurora

# Create secondary cluster in DR region
aws rds create-db-cluster \
  --db-cluster-identifier my-cluster-aurora-dr \
  --engine aurora-postgresql \
  --engine-version 17.4 \
  --global-cluster-identifier my-cluster-aurora-global \
  --db-subnet-group-name <dr-subnet-group> \
  --vpc-security-group-ids <dr-security-group> \
  --region eu-west-1 \
  --storage-encrypted \
  --kms-key-id <dr-region-kms-key-arn>

# Create instance in the secondary cluster
aws rds create-db-instance \
  --db-cluster-identifier my-cluster-aurora-dr \
  --db-instance-class db.r6g.large \
  --db-instance-identifier my-cluster-aurora-dr-1 \
  --engine aurora-postgresql \
  --region eu-west-1
```

### Step 4: Point Application to Aurora

Update your application connection string to use the Aurora writer endpoint:

```bash
aws rds describe-db-clusters \
  --db-cluster-identifier my-cluster-aurora \
  --query 'DBClusters[0].Endpoint' --output text
```

### Step 5: Switch Terraform Config to Aurora Mode

Update your module configuration — do NOT apply yet:

```hcl
module "control_plane" {
  # ...

  truefoundry_db_engine_mode        = "aurora"       # was "rds"
  truefoundry_aurora_engine_version = "17.4"
  truefoundry_aurora_instance_class = "db.r6g.large"
  truefoundry_aurora_instance_count = 1

  # If you created a global cluster + secondary:
  truefoundry_aurora_enable_global_cluster = true
  truefoundry_aurora_secondary_config = {
    cluster_identifier  = "my-cluster-aurora-dr"
    vpc_id              = var.dr_vpc_id
    subnet_ids          = var.dr_subnet_ids
    ingress_cidr_blocks = ["10.0.0.0/16"]
  }

  # ...
}
```

### Step 6: Import Manually Created Resources into Terraform State

This is the critical step. You must import each resource that was created outside Terraform so that Terraform manages them going forward. The import commands use the module address prefix — adjust if your module name differs.

**Remove the old RDS instance from state** (it will be deleted by AWS after promotion):

```bash
terraform state rm 'module.control_plane.aws_db_instance.truefoundry_db[0]'
terraform state rm 'module.control_plane.aws_db_parameter_group.truefoundry_db_parameter_group[0]'
```

**Import Aurora primary cluster and instance:**

```bash
terraform import \
  'module.control_plane.aws_rds_cluster.truefoundry_aurora[0]' \
  my-cluster-aurora

terraform import \
  'module.control_plane.aws_rds_cluster_instance.truefoundry_aurora[0]' \
  my-cluster-aurora-1
```

**If you created a parameter group for Aurora:**

```bash
terraform import \
  'module.control_plane.aws_rds_cluster_parameter_group.truefoundry_aurora_parameter_group[0]' \
  my-cluster-aurora-pg
```

**If you created a global cluster:**

```bash
terraform import \
  'module.control_plane.aws_rds_global_cluster.truefoundry[0]' \
  my-cluster-aurora-global
```

**If you created a secondary cluster:**

```bash
# Secondary cluster and instance
terraform import \
  'module.control_plane.aws_rds_cluster.aurora_secondary[0]' \
  my-cluster-aurora-dr

terraform import \
  'module.control_plane.aws_rds_cluster_instance.aurora_secondary[0]' \
  my-cluster-aurora-dr-1

# Secondary networking (subnet group, security group)
terraform import \
  'module.control_plane.aws_db_subnet_group.aurora_secondary[0]' \
  my-cluster-aurora-dr-subnet

terraform import \
  'module.control_plane.aws_security_group.aurora_secondary[0]' \
  sg-xxxxxxxxxxxxxxxxx

# Secondary KMS key (if module created it)
terraform import \
  'module.control_plane.aws_kms_key.aurora_secondary[0]' \
  arn:aws:kms:eu-west-1:111122223333:key/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

# Secondary parameter group
terraform import \
  'module.control_plane.aws_rds_cluster_parameter_group.aurora_secondary[0]' \
  my-cluster-aurora-dr-pg
```

### Step 7: Verify State Matches Reality

Run a plan to check for drift between Terraform's config and the actual AWS resources:

```bash
terraform plan
```

You'll likely see some attribute differences (e.g., tags, parameter values). Review them carefully:

- **Expected changes**: Tags being added, parameter group settings aligning — these are safe to apply
- **Destructive changes**: If the plan shows `must be replaced` or `forces replacement` for any cluster resource, **do NOT apply**. Adjust your Terraform variables to match the existing resource configuration first, then re-plan

Once the plan shows only safe changes:

```bash
terraform apply
```

### Step 8: Clean Up

After confirming everything works:

```bash
# Delete the original RDS instance (if not already deleted)
aws rds delete-db-instance \
  --db-instance-identifier <original-rds-id> \
  --skip-final-snapshot
```

### Tips for a Smooth Import

- **Match identifiers exactly.** The `cluster_identifier` in your Terraform config must match what you created in AWS. Use `aws rds describe-db-clusters` and `aws rds describe-db-instances` to get the exact identifiers.
- **Match engine versions.** Set `truefoundry_aurora_engine_version` to the exact version of the Aurora cluster you created.
- **Match instance classes.** Set `truefoundry_aurora_instance_class` to the exact class you used when creating the Aurora instance.
- **Import shared resources if needed.** If the Aurora cluster reuses the same subnet group and security group as the old RDS instance (which is the default in this module), those resources are already in state — no import needed.
- **Run plan before apply.** Always review the plan after importing. Never blindly apply.

---

## Option 3: Aurora Global Database (Multi-Region DR)

Aurora Global Database replicates your primary cluster to a secondary region with typical lag under 1 second. The secondary cluster is read-only and can be promoted to a standalone read-write cluster during a regional failover.

### Provider Setup

You must configure two AWS providers — one for the primary region and one for the DR region:

```hcl
provider "aws" {
  region = "us-east-1"
}

provider "aws" {
  alias  = "dr"
  region = "eu-west-1"
}
```

### Networking: Security Groups Are Region-Scoped

Security groups exist within a single VPC in a single region. You **cannot** reference a primary-region security group ID in the secondary region's configuration. The primary and secondary clusters have completely independent security group setups:

- **Primary** — uses `truefoundry_db_ingress_security_group` (a security group ID in the primary VPC)
- **Secondary** — uses `ingress_cidr_blocks` and/or `ingress_security_group_ids` inside `truefoundry_aurora_secondary_config` (must reference resources in the DR region's VPC)

For the secondary cluster, prefer `ingress_cidr_blocks` (e.g., the DR VPC CIDR) since cross-region security group references are not possible. Only use `ingress_security_group_ids` if you have security groups in the DR region's VPC that you want to allow.

### Module Configuration

```hcl
module "control_plane" {
  source = "truefoundry/truefoundry-control-plane/aws"
  providers = {
    aws           = aws
    aws.secondary = aws.dr
  }

  cluster_name            = "my-cluster"
  cluster_oidc_issuer_url = var.oidc_url
  aws_region              = "us-east-1"
  aws_account_id          = var.account_id
  vpc_id                  = var.vpc_id

  # Aurora primary — security group is in the primary region's VPC
  truefoundry_db_enabled                 = true
  truefoundry_db_engine_mode             = "aurora"
  truefoundry_db_subnet_ids              = var.primary_subnet_ids
  truefoundry_db_ingress_security_group  = var.primary_security_group  # SG in us-east-1
  truefoundry_aurora_engine_version      = "17.4"
  truefoundry_aurora_instance_class      = "db.r6g.large"
  truefoundry_aurora_instance_count      = 2

  # Global cluster + secondary
  truefoundry_aurora_enable_global_cluster = true
  truefoundry_aurora_secondary_config = {
    cluster_identifier  = "my-cluster-aurora-dr"
    vpc_id              = var.dr_vpc_id              # VPC in eu-west-1
    subnet_ids          = var.dr_subnet_ids           # subnets in eu-west-1
    instance_class      = "db.r6g.large"
    instance_count      = 1

    # Networking — primary-region SG IDs will NOT work here
    ingress_cidr_blocks        = ["10.0.0.0/16"]     # DR VPC CIDR (recommended for cross-region)
    ingress_security_group_ids = []                   # only SGs in the DR region's VPC
  }

  # ... other variables
}
```

### Key Outputs


| Output                                                 | Description                            |
| ------------------------------------------------------ | -------------------------------------- |
| `truefoundry_aurora_global_cluster_id`                 | Global cluster identifier              |
| `truefoundry_aurora_cluster_endpoint`                  | Primary cluster writer endpoint        |
| `truefoundry_aurora_cluster_reader_endpoint`           | Primary cluster reader endpoint        |
| `truefoundry_aurora_secondary_cluster_endpoint`        | Secondary cluster endpoint (read-only) |
| `truefoundry_aurora_secondary_cluster_reader_endpoint` | Secondary cluster reader endpoint      |


### Failover Procedure

If the primary region goes down, promote the secondary cluster:

```bash
aws rds failover-global-cluster \
  --global-cluster-identifier $(terraform output -raw truefoundry_aurora_global_cluster_id) \
  --target-db-cluster-identifier $(terraform output -raw truefoundry_aurora_secondary_cluster_id) \
  --region eu-west-1
```

After failover:

1. The secondary becomes the new primary (read-write)
2. Update your application to use the secondary endpoint
3. Update Terraform state to reflect the new topology

### Secondary Config Options

All fields except `cluster_identifier`, `vpc_id`, and `subnet_ids` are optional:


| Field                           | Default          | Description                                                                                                             |
| ------------------------------- | ---------------- | ----------------------------------------------------------------------------------------------------------------------- |
| `cluster_identifier`            | *required*       | Unique name for the secondary cluster                                                                                   |
| `vpc_id`                        | *required*       | VPC in the DR region                                                                                                    |
| `subnet_ids`                    | *required*       | At least 2 subnets in the DR region                                                                                     |
| `instance_class`                | `"db.r6g.large"` | Can differ from primary                                                                                                 |
| `instance_count`                | `1`              | Number of instances in secondary                                                                                        |
| `ingress_cidr_blocks`           | `[]`             | CIDRs allowed to connect. **Recommended** for cross-region — use the DR VPC CIDR.                                       |
| `ingress_security_group_ids`    | `[]`             | Security groups allowed to connect. **Must be SGs in the DR region's VPC** — you cannot use primary-region SG IDs here. |
| `additional_security_group_ids` | `[]`             | Extra SGs to attach                                                                                                     |
| `publicly_accessible`           | `false`          | Public access                                                                                                           |
| `backup_retention_period`       | `1`              | Min 1 for global members                                                                                                |
| `kms_key_id`                    | `null`           | Region-specific KMS key for encryption                                                                                  |
| `enable_insights`               | `false`          | Performance Insights                                                                                                    |
| `enable_monitoring`             | `false`          | Enhanced monitoring                                                                                                     |
| `monitoring_interval`           | `5`              | Monitoring interval (1,5,10,15,30,60)                                                                                   |
| `monitoring_role_arn`           | `""`             | Existing monitoring IAM role                                                                                            |
| `tags`                          | `{}`             | Additional tags                                                                                                         |


---

## Variable Reference

### Engine Mode


| Variable                                    | Type           | Default          | Description                 |
| ------------------------------------------- | -------------- | ---------------- | --------------------------- |
| `truefoundry_db_engine_mode`                | `string`       | `"rds"`          | `"rds"` or `"aurora"`       |
| `truefoundry_aurora_engine_version`         | `string`       | `"17.4"`         | Aurora PostgreSQL version   |
| `truefoundry_aurora_instance_class`         | `string`       | `"db.r6g.large"` | Instance class              |
| `truefoundry_aurora_instance_count`         | `number`       | `1`              | Number of cluster instances |
| `truefoundry_aurora_cloudwatch_log_exports` | `list(string)` | `["postgresql"]` | Log exports                 |


### Global Cluster


| Variable                                   | Type     | Default | Description              |
| ------------------------------------------ | -------- | ------- | ------------------------ |
| `truefoundry_aurora_enable_global_cluster` | `bool`   | `false` | Enable global database   |
| `truefoundry_aurora_secondary_config`      | `object` | `null`  | Secondary cluster config |


---

## Output Reference

These outputs are mode-aware. They return RDS values when `engine_mode = "rds"` and Aurora values when `engine_mode = "aurora"`:


| Output                         | Description                     |
| ------------------------------ | ------------------------------- |
| `truefoundry_db_endpoint`      | Connection endpoint (host:port) |
| `truefoundry_db_address`       | Hostname only                   |
| `truefoundry_db_port`          | Port number                     |
| `truefoundry_db_database_name` | Database name                   |
| `truefoundry_db_username`      | Master username                 |
| `truefoundry_db_password`      | Master password (sensitive)     |
| `truefoundry_db_engine_mode`   | Active engine mode              |


Aurora-specific outputs (empty when engine_mode = "rds"):


| Output                                                 | Description               |
| ------------------------------------------------------ | ------------------------- |
| `truefoundry_aurora_cluster_id`                        | Cluster identifier        |
| `truefoundry_aurora_cluster_arn`                       | Cluster ARN               |
| `truefoundry_aurora_cluster_endpoint`                  | Writer endpoint           |
| `truefoundry_aurora_cluster_reader_endpoint`           | Reader endpoint           |
| `truefoundry_aurora_cluster_port`                      | Cluster port              |
| `truefoundry_aurora_global_cluster_id`                 | Global cluster ID         |
| `truefoundry_aurora_secondary_cluster_endpoint`        | Secondary endpoint        |
| `truefoundry_aurora_secondary_cluster_reader_endpoint` | Secondary reader endpoint |


---

## FAQ

### Can I switch from Aurora back to RDS?

Yes, by changing `truefoundry_db_engine_mode` back to `"rds"`. This will destroy the Aurora cluster and create an RDS instance. You must migrate data back manually before switching.

### What happens to the shared resources (subnet group, security groups)?

They are shared between RDS and Aurora. Switching engine modes does not recreate them, so there is no disruption to networking configuration.

### Can I use Aurora without a global cluster?

Yes. Set `truefoundry_aurora_enable_global_cluster = false` (the default) and pass the default provider for `aws.secondary`:

```hcl
providers = {
  aws           = aws
  aws.secondary = aws  # unused, pass default
}
```

### What PostgreSQL versions are compatible?

Aurora PostgreSQL versions are different from standard RDS PostgreSQL versions. Check [AWS Aurora PostgreSQL version compatibility](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.Updates.html) for the latest supported versions. The module defaults to `17.4`.

### Can I add more than one secondary region?

The module supports one secondary region out of the box. For additional secondaries, create them outside the module using the `truefoundry_aurora_global_cluster_id` output:

```hcl
resource "aws_rds_cluster" "additional_secondary" {
  provider                  = aws.another_region
  cluster_identifier        = "my-cluster-aurora-apac"
  global_cluster_identifier = module.control_plane.truefoundry_aurora_global_cluster_id
  engine                    = "aurora-postgresql"
  engine_version            = "17.4"
  # ... networking, etc.
}
```

