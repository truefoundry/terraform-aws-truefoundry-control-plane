# Aurora Migration Guide

This guide covers how to use Aurora PostgreSQL with the TrueFoundry control plane module, including migrating from an existing RDS instance and setting up Aurora Global Database for disaster recovery.

## Table of Contents

- [Overview](#overview)
- [Path 0: Stay on RDS (no migration)](#path-0-stay-on-rds-no-migration)
- [Option 1: Fresh Aurora Deployment](#option-1-fresh-aurora-deployment)
- [Option 2: Migrating from RDS to Aurora](#option-2-migrating-from-rds-to-aurora)
- [Option 2b: Near-Zero-Downtime Migration Using Aurora Read Replica](#option-2b-near-zero-downtime-migration-using-aurora-read-replica)
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


When using Aurora, you can optionally add Aurora Global Database by using the separate `aurora-global` submodule for the DR region resources.

> **Important**: Switching `truefoundry_db_engine_mode` from `"rds"` to `"aurora"` will **destroy the existing RDS instance and create a new Aurora cluster**. Data must be migrated separately before making this change. See [Option 2](#option-2-migrating-from-rds-to-aurora) for the full migration procedure.



### Pick your path


| If you want…                                                       | Go to                                                                          |
| ------------------------------------------------------------------ | ------------------------------------------------------------------------------ |
| Keep running on RDS, just bump the module version                  | [Path 0](#path-0-stay-on-rds-no-migration)                                     |
| Deploy Aurora on a brand-new stack                                 | [Option 1](#option-1-fresh-aurora-deployment)                                  |
| Migrate an existing RDS instance to Aurora with downtime / DMS     | [Option 2](#option-2-migrating-from-rds-to-aurora)                             |
| Migrate an existing RDS instance to Aurora with near-zero downtime | [Option 2b](#option-2b-near-zero-downtime-migration-using-aurora-read-replica) |
| Add a DR region (Aurora Global Database)                           | [Option 3](#option-3-aurora-global-database-multi-region-dr)                   |




### What this module creates (and what you must bring)

This module manages the **data-plane** layer (databases, IAM). It does **not** create networking — VPCs, subnets, route tables, cross-region VPC peering, or NAT/Internet gateways are caller-side inputs.


| Layer                                     | This module                        | You provide                                                                                 |
| ----------------------------------------- | ---------------------------------- | ------------------------------------------------------------------------------------------- |
| VPC(s)                                    | —                                  | One VPC in each region you want to deploy to                                                |
| Subnets                                   | —                                  | At least 2 private subnets across 2 AZs per VPC (RDS/Aurora subnet groups require this)     |
| Route tables / cross-region connectivity  | —                                  | Existing route tables; optional caller-managed VPC peering (see example)                    |
| DB subnet group                           | created                            | —                                                                                           |
| DB security group                         | created (with port 5432 ingress)   | (optional) extra SG IDs or CIDR blocks to add to ingress                                    |
| RDS instance / Aurora cluster + instances | created                            | —                                                                                           |
| Aurora Global cluster + DR cluster        | created by `modules/aurora-global` | A separate VPC + subnets in the DR region                                                   |
| DR storage KMS key                        | —                                  | Region-local KMS key ARN via `truefoundry_aurora_secondary_config.kms_key_id` (optional)    |
| Cross-region VPC peering                  | —                                  | Caller-managed (see `examples/complete/vpc-peering.tf`)                                     |
| S3 bucket, IAM roles, OIDC trust          | created                            | OIDC issuer URL from your EKS cluster                                                       |




### Prerequisites at a glance


| Path                                                                           | AWS providers                               | VPCs                                                           | Subnets                 | Existing RDS? |
| ------------------------------------------------------------------------------ | ------------------------------------------- | -------------------------------------------------------------- | ----------------------- | ------------- |
| [Path 0](#path-0-stay-on-rds-no-migration)                                     | 1 (+ alias `aws.secondary` reusing default) | 1 (existing — already in use)                                  | ≥2 in ≥2 AZs (existing) | yes — keep it |
| [Option 1](#option-1-fresh-aurora-deployment)                                  | 1 (+ alias `aws.secondary` reusing default) | 1                                                              | ≥2 in ≥2 AZs            | no            |
| [Option 2](#option-2-migrating-from-rds-to-aurora)                             | 1 (+ alias `aws.secondary` reusing default) | 1 (existing, reused)                                           | ≥2 in ≥2 AZs (existing) | yes           |
| [Option 2b](#option-2b-near-zero-downtime-migration-using-aurora-read-replica) | 1 (+ alias `aws.secondary` reusing default) | 1 (existing, reused)                                           | ≥2 in ≥2 AZs (existing) | yes           |
| [Option 3](#option-3-aurora-global-database-multi-region-dr)                   | 2 (`aws` primary + `aws.secondary` DR)      | **2** (one per region — the module does NOT create the DR VPC) | ≥2 in ≥2 AZs per region | optional      |


---



## Path 0: Stay on RDS (no migration)

If you're upgrading from `0.4.x`/`0.5.x` to `0.6.0` and want to keep your existing RDS instance exactly as it is, this is the only path you need. No data migration, no destructive changes, no `terraform state mv`.

### Prerequisites

- A working deployment on `truefoundry_db_engine_mode = "rds"` (the default).
- Module version `0.4.x` or `0.5.x`. (If you're already on `0.6.0`, you're done.)
- Terraform / OpenTofu `~> 1.9` and AWS provider `~> 6.33` in your caller config.

The module is **not** creating any new networking, IAM, or KMS resources on this path. Your existing VPC, subnets, security groups, and parameter group all stay in place.

### What changes

- Default `truefoundry_db_engine_mode` is `"rds"`, so omitting it preserves your current behavior.
- No RDS variables were removed or renamed in `0.5.x` — every `truefoundry_db_*` input you already pass keeps working.
- One **caller-side** change is required: the module now declares `configuration_aliases = [aws.secondary]`, so you must pass an `aws.secondary` provider in your module call. Reuse your default provider — nothing in the DR region is created.



### Steps

1. **Bump versions** in the root that calls this module:
  ```hcl
   terraform {
     required_version = "~> 1.9"
     required_providers {
       aws = {
         source  = "hashicorp/aws"
         version = "~> 6.33"
       }
     }
   }
  ```
2. **Add the** `providers` **block** to your module call. Everything else stays the same:
  ```hcl
   module "tfy_control_plane" {
     source  = "truefoundry/truefoundry-control-plane/aws"
     version = "0.6.0"

     providers = {
       aws           = aws
       aws.secondary = aws   # unused; alias points back at the default provider
     }

     # ... all your existing truefoundry_db_*, truefoundry_s3_*, IAM, etc. unchanged ...
   }
  ```
3. **Plan and verify no destructive changes**:
  ```bash
   terraform init -upgrade
   terraform plan
  ```
   Expected: `No changes.` If you see any line containing `must be replaced` or `forces replacement` against `aws_db_instance.truefoundry_db[0]`, **stop** and read the [upgrade guide](../upgrade-guide.md#step-3--plan-and-confirm-no-changes) before applying. Tag additions (from AWS provider v6 default-tags behavior) are safe to apply.
4. **Apply**.
  ```bash
   terraform apply
  ```

That's it — your stack is now on `0.5.x` still running RDS. You can revisit [Option 2](#option-2-migrating-from-rds-to-aurora) or [Option 3](#option-3-aurora-global-database-multi-region-dr) any time later without re-upgrading the module.

---



## Option 1: Fresh Aurora Deployment

For new deployments where no existing RDS database exists.

### Prerequisites

**You provide** (this module does not create them):

- **1 VPC** in the deployment region, with `enable_dns_support = true` and `enable_dns_hostnames = true` (needed for Aurora endpoint hostnames to resolve to private IPs from within the VPC).
- **At least 2 private subnets** in **at least 2 Availability Zones** of that VPC. RDS/Aurora DB subnet groups reject anything less.
- One of:
  - A **security group ID** in the VPC whose members should be allowed to reach the database (`truefoundry_db_ingress_security_group`), or
  - A list of **CIDR blocks** (`truefoundry_db_ingress_cidr_blocks`).
- An **EKS cluster's OIDC issuer URL** if you want the module to bind IAM roles to in-cluster service accounts.

**Caller-side Terraform:**

- One AWS provider for the deployment region.
- An `aws.secondary` provider alias — pass the default provider through when you're not using Aurora Global (`aws.secondary = aws`).

**What the module creates for this path:**

- DB subnet group, DB security group (port 5432 ingress), optional parameter group.
- Aurora cluster + `truefoundry_db_instance_count` instances.
- Optional: enhanced-monitoring IAM role, Secrets-Manager-managed master password, KMS key for the master-user-secret.
- S3 bucket and IAM roles for `mlfoundry` / `servicefoundry` / `tfy-workflow-admin` / LLM gateway (toggleable).



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
  aws_region              = "<primary-region>"
  aws_account_id          = var.account_id
  vpc_id                  = var.vpc_id

  truefoundry_db_enabled                 = true
  truefoundry_db_engine_mode             = "aurora"
  truefoundry_db_subnet_ids              = var.subnet_ids
  truefoundry_db_ingress_security_group  = var.eks_security_group_id
  truefoundry_db_engine_version      = "17.4"
  truefoundry_db_instance_class      = "db.r6g.large"
  truefoundry_db_instance_count      = 2  # writer + 1 reader

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

**Existing state:**

- An existing deployment of this module using `truefoundry_db_engine_mode = "rds"`.
- The current VPC, ≥2 subnets across ≥2 AZs, and DB security group **stay in place** — Aurora reuses them. No new networking is required.

**Compatibility:**

- RDS and Aurora PostgreSQL major versions must be compatible (e.g., RDS PostgreSQL 17.x → Aurora PostgreSQL 17.x).

**Migration tooling:**

- A maintenance window with acceptable downtime **OR** AWS DMS for near-zero downtime (full load + CDC).
- `psql`, `pg_dump`, `pg_restore` of the same major version installed locally if you choose the dump/restore route.

**Caller-side Terraform:**

- One AWS provider (deployment region), plus the `aws.secondary` alias (pass the default provider through if you're not adding Aurora Global at the same time).

> **Heads-up on the master password.** This path destroys the RDS instance and creates a new Aurora cluster, which means the master password is regenerated. If your application reads the password from a stable location, set `manage_master_user_password = true` on the module so the secret is owned by AWS Secrets Manager (`master_user_secret_arn` survives the swap and applications can keep pointing at the same secret). If you rely on the module-generated `random_password`, plan to roll your application's connection string after the cutover.



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
  truefoundry_db_engine_version = "17.4"
  truefoundry_db_instance_class = "db.r6g.large"
  truefoundry_db_instance_count = 1

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

### Prerequisites

**Existing state:**

- An existing deployment of this module using `truefoundry_db_engine_mode = "rds"`.
- The current VPC, ≥2 subnets across ≥2 AZs, DB subnet group, and DB security group are reused — `aws rds create-db-cluster` will reference them by name.

**Aurora Read Replica constraints (AWS-side):**

- RDS and Aurora PostgreSQL versions must be in the same major version family.
- The source RDS instance must not already have an Aurora read replica or cross-region read replica.
- The RDS instance and the new Aurora cluster must be in the **same AWS Region and account**.

**Caller-side Terraform:**

- One AWS provider, plus the `aws.secondary` alias (pass through the default provider unless you also want Aurora Global in the same change).
- Permission to run `terraform import` — you'll be importing the manually-created Aurora cluster and instance into module state.

**Migration tooling:**

- AWS CLI v2 logged in to the same account/region as the RDS instance.
- `psql` for the LSN catch-up check (Step 2).



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
  --region <dr-region> \
  --storage-encrypted \
  --kms-key-id <dr-region-kms-key-arn>

# Create instance in the secondary cluster
aws rds create-db-instance \
  --db-cluster-identifier my-cluster-aurora-dr \
  --db-instance-class db.r6g.large \
  --db-instance-identifier my-cluster-aurora-dr-1 \
  --engine aurora-postgresql \
  --region <dr-region>
```



### Step 4: Point Application to Aurora

Update your application connection string to use the Aurora writer endpoint:

```bash
aws rds describe-db-clusters \
  --db-cluster-identifier my-cluster-aurora \
  --query 'DBClusters[0].Endpoint' --output text
```



### Step 5: Switch Terraform Config to Aurora Mode + Add Aurora Global Submodule

Update your Terraform configuration — do NOT apply yet:

```hcl
module "control_plane" {
  # ...

  truefoundry_db_engine_mode        = "aurora"       # was "rds"
  truefoundry_db_engine_version = "17.4"
  truefoundry_db_instance_class = "db.r6g.large"
  truefoundry_db_instance_count = 1

  # ...
}

# Add the Aurora Global submodule (separate from control_plane)
module "aurora_global" {
  count  = var.db_engine_mode == "aurora" && var.enable_global_cluster ? 1 : 0
  source = "../../modules/aurora-global" # replace with your chosen source

  providers = {
    aws           = aws
    aws.secondary = aws.dr
  }

  aws_account_id                  = var.account_id
  vpc_id                          = var.vpc_id
  truefoundry_aurora_unique_name  = "${var.cluster_name}-aurora"
  truefoundry_db_port             = 5432
  truefoundry_db_engine_version   = "17.4"
  truefoundry_db_deletion_protection = false
  truefoundry_db_skip_final_snapshot = true
  truefoundry_db_storage_encrypted = true
  truefoundry_db_postgres_parameter_group_enabled = true
  truefoundry_db_aurora_cloudwatch_log_exports    = ["postgresql"]
  iam_database_authentication_enabled             = false
  primary_cluster_arn                             = module.control_plane.truefoundry_aurora_cluster_arn

  truefoundry_aurora_secondary_config = {
    cluster_identifier  = "my-cluster-aurora-dr"
    vpc_id              = var.dr_vpc_id
    subnet_ids          = var.dr_subnet_ids
    ingress_cidr_blocks = ["10.0.0.0/16"]
  }

  depends_on = [module.control_plane]
}
```



### Step 6: Import Manually Created Resources into Terraform State

This is the critical step. You must import each resource that was created outside Terraform so that Terraform manages them going forward. The import commands use the module address prefix — adjust if your module name differs.

**Remove the old RDS instance from state** (it will be deleted by AWS after promotion):

```bash
terraform state rm 'module.tfy_control_plane.aws_db_instance.truefoundry_db[0]'
terraform state rm 'module.control_plane.aws_db_parameter_group.truefoundry_db_parameter_group[0]'
# or
terraform state rm 'module.tfy_control_plane.aws_db_parameter_group.truefoundry_db_parameter_group'
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
  'module.aurora_global[0].aws_rds_global_cluster.truefoundry' \
  my-cluster-aurora-global
```

**If you created a secondary cluster:**

```bash
# Secondary cluster and instance
terraform import \
  'module.aurora_global[0].aws_rds_cluster.truefoundry_aurora_secondary' \
  my-cluster-aurora-dr

terraform import \
  'module.aurora_global[0].aws_rds_cluster_instance.truefoundry_aurora_secondary[0]' \
  my-cluster-aurora-dr-1

# Secondary networking (subnet group, security group)
terraform import \
  'module.aurora_global[0].aws_db_subnet_group.truefoundry_aurora_secondary' \
  my-cluster-aurora-dr-subnet

terraform import \
  'module.aurora_global[0].aws_security_group.truefoundry_aurora_secondary' \
  sg-xxxxxxxxxxxxxxxxx

# Secondary parameter group
terraform import \
  'module.aurora_global[0].aws_rds_cluster_parameter_group.truefoundry_aurora_secondary[0]' \
  my-cluster-aurora-dr-pg
```

> If your `aurora_global` module does not use `count`, drop the `[0]` segment from the import address.



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
- **Match engine versions.** Set `truefoundry_db_engine_version` to the exact version of the Aurora cluster you created.
- **Match instance classes.** Set `truefoundry_db_instance_class` to the exact class you used when creating the Aurora instance.
- **Import shared resources if needed.** If the Aurora cluster reuses the same subnet group and security group as the old RDS instance (which is the default in this module), those resources are already in state — no import needed.
- **Run plan before apply.** Always review the plan after importing. Never blindly apply.

---



## Option 3: Aurora Global Database (Multi-Region DR)

Aurora Global Database replicates your primary cluster to a secondary region with typical lag under 1 second. The secondary cluster is read-only and can be promoted to a standalone read-write cluster during a regional failover.

In `0.6.x`, global/DR resources are managed via the separate `aurora-global` submodule (`modules/aurora-global`). The root `control_plane` module manages the primary Aurora cluster.

### Prerequisites

This is the path with the most caller-side setup. You will configure two modules: `control_plane` (primary Aurora) and `aurora_global` (global + DR resources).

**You must provide in the primary region (the module does NOT create these):**

- **1 VPC** with `enable_dns_support = true` and `enable_dns_hostnames = true`.
- **≥ 2 private subnets** across **≥ 2 AZs**.
- One of: a security group ID, or CIDR blocks, for primary-VPC clients to reach the primary cluster.

**You must provide in the DR region (the module does NOT create these):**

- **A separate VPC** in the DR region. This module will not create a VPC anywhere — you bring your own (e.g., via `terraform-aws-modules/vpc/aws`, your network module, or hand-rolled Terraform).
- **≥ 2 private subnets** across **≥ 2 AZs** in that DR-region VPC.
- The DR VPC's **CIDR block** (or a list of CIDRs) that should be allowed to reach the secondary cluster on port 5432, passed via `truefoundry_aurora_secondary_config.ingress_cidr_blocks`. Security-group IDs from the primary region's VPC **do not work** here — security groups are region-scoped.
- (Optional) An existing **KMS key ARN in the DR region** for storage encryption (`truefoundry_aurora_secondary_config.kms_key_id`). If omitted with `storage_encrypted = true`, AWS uses the default RDS encryption key in that region.

**Caller-side Terraform:**

- **Two AWS providers** — one for the primary region (default `aws`) and one for the DR region (aliased, e.g. `aws.dr`), then wired into both module calls:
  ```hcl
  providers = {
    aws           = aws
    aws.secondary = aws.dr
  }
  ```
- AWS credentials with permission to create RDS clusters and IAM roles in **both regions**.

**Aurora Global constraints (AWS-side):**

- Aurora PostgreSQL engine version that supports global databases (the module's default `17.4` does).
- Aurora Global is available in [a fixed list of regions](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/aurora-global-database.html#aurora-global-database.limitations) — confirm the DR region is on it.
- One AWS account can have multiple global clusters across regions, but the primary and any single secondary must each live in their own dedicated cluster.

**What each module creates for this path:**

- `module.control_plane` (primary region): Aurora cluster + instance(s), DB subnet group, DB security group, parameter group (optional).
- `module.aurora_global` (global + DR): `aws_rds_global_cluster`, DR Aurora cluster + instance(s), DR subnet/security groups, optional DR parameter group and monitoring IAM role.



### Provider Setup

You must configure two AWS providers — one for the primary region and one for the DR region:

```hcl
provider "aws" {
  region = "<primary-region>"
}

provider "aws" {
  alias  = "dr"
  region = "<dr-region>"
}
```



### Networking: Security Groups Are Region-Scoped

Security groups exist within a single VPC in a single region. You **cannot** reference a primary-region security group ID in the secondary region's configuration. The primary and secondary clusters have completely independent security group setups:

- **Primary** — uses `truefoundry_db_ingress_security_group` (a security group ID in the primary VPC)
- **Secondary** — uses `ingress_cidr_blocks` and/or `ingress_security_group_ids` inside `truefoundry_aurora_secondary_config` (must reference resources in the DR region's VPC)

For the secondary cluster, prefer `ingress_cidr_blocks` (e.g., the DR VPC CIDR) since cross-region security group references are not possible. Only use `ingress_security_group_ids` if you have security groups in the DR region's VPC that you want to allow.

### Cross-region VPC peering (optional, caller-managed)

Aurora Global Database replication itself does **not** require VPC peering — AWS replicates between regions over its own backbone. Create peering in your own infra when resources in one VPC must reach the database endpoint in the other VPC privately, for example:

- primary-region apps reading from the DR reader endpoint,
- operators or monitoring crossing regions over private IPs,
- a failover drill where workloads remain in the primary VPC but the writer is in DR.

**Prerequisites:**

- The primary VPC and the DR VPC (`truefoundry_aurora_secondary_config.vpc_id`) must have **non-overlapping CIDR blocks**.
- Route tables in each VPC that should learn the peer CIDR.

The `examples/complete/vpc-peering.tf` file shows a caller-side pattern using `var.create_vpc_peering`. Copy or adapt it into your network/infra repo — the `aurora-global` submodule does not manage peering.



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
  aws_region              = "<primary-region>"
  aws_account_id          = var.account_id
  vpc_id                  = var.vpc_id

  # Aurora primary — security group is in the primary region's VPC
  truefoundry_db_enabled                 = true
  truefoundry_db_engine_mode             = "aurora"
  truefoundry_db_subnet_ids              = var.primary_subnet_ids
  truefoundry_db_ingress_security_group  = var.primary_security_group  # SG in the primary region
  truefoundry_db_engine_version      = "17.4"
  truefoundry_db_instance_class      = "db.r6g.large"
  truefoundry_db_instance_count      = 2

  # ... other variables
}

module "aurora_global" {
  source = "../../modules/aurora-global"
  providers = {
    aws           = aws
    aws.secondary = aws.dr
  }

  aws_account_id                               = var.account_id
  cluster_name                                 = var.cluster_name
  secondary_cluster_name                       = "${var.cluster_name}-aurora-dr"
  truefoundry_aurora_global_cluster_identifier = "${var.cluster_name}-aurora-global"
  truefoundry_db_port                          = 5432
  truefoundry_db_engine_version                = "17.4"

  truefoundry_aurora_secondary_config = {
    cluster_identifier  = "my-cluster-aurora-dr"
    vpc_id              = var.dr_vpc_id
    subnet_ids          = var.dr_subnet_ids
    instance_class      = "db.r6g.large"
    instance_count      = 1
    ingress_cidr_blocks = ["10.0.0.0/16"] # DR VPC CIDR (recommended)
    storage_encrypted   = true
    kms_key_id          = var.dr_kms_key_arn # optional; omit for AWS default RDS key
  }

  depends_on = [module.control_plane]
}
```



### Key Outputs


| Output                                                 | Description                            |
| ------------------------------------------------------ | -------------------------------------- |
| `module.aurora_global.truefoundry_aurora_global_cluster_id`                 | Global cluster identifier              |
| `truefoundry_aurora_cluster_endpoint`                  | Primary cluster writer endpoint        |
| `truefoundry_aurora_cluster_reader_endpoint`           | Primary cluster reader endpoint        |
| `module.aurora_global.truefoundry_aurora_secondary_cluster_endpoint`        | Secondary cluster endpoint (read-only) |
| `module.aurora_global.truefoundry_aurora_secondary_cluster_reader_endpoint` | Secondary cluster reader endpoint      |




### Failover Procedure

If the primary region goes down, promote the secondary cluster manually. Pass the
secondary cluster's **ARN** to `--target-db-cluster-identifier` — for a
cross-region global failover AWS uses the ARN to locate the cluster in its
region:

```bash
aws rds failover-global-cluster \
  --global-cluster-identifier <global-cluster-id> \
  --target-db-cluster-identifier <secondary-cluster-arn> \
  --region <dr-region>
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
| `backup_retention_period`       | `14`             | Backup retention (min 1 for global members)                                                                             |
| `storage_encrypted`               | `true`           | Enable storage encryption on the secondary cluster                                                                      |
| `kms_key_id`                      | `null`           | DR-region KMS key ARN; omit for AWS default RDS key when encrypted                                                      |
| `deletion_protection`             | `true`           | Deletion protection on global + secondary cluster                                                                       |
| `skip_final_snapshot`             | `false`          | Skip final snapshot when deleting secondary cluster                                                                     |
| `postgres_parameter_group_enabled`| `true`           | Create and attach a secondary parameter group                                                                           |
| `cloudwatch_log_exports`          | `["postgresql"]` | Aurora log exports (`upgrade` is filtered out)                                                                          |
| `iam_database_authentication_enabled` | `false`      | Enable IAM DB auth on secondary cluster                                                                                 |
| `enable_insights`               | `true`           | Performance Insights                                                                                                    |
| `enable_monitoring`             | `true`           | Enhanced monitoring                                                                                                     |
| `monitoring_interval`           | `60`             | Monitoring interval (1,5,10,15,30,60)                                                                                   |
| `monitoring_role_arn`           | `""`             | Existing monitoring IAM role                                                                                            |
| `tags`                          | `{}`             | Additional tags                                                                                                         |


---



## Variable Reference



### Engine Mode


| Variable                                | Type           | Default                     | Description                                |
| --------------------------------------- | -------------- | --------------------------- | ------------------------------------------ |
| `truefoundry_db_engine_mode`            | `string`       | `"rds"`                     | `"rds"` or `"aurora"`                      |
| `truefoundry_db_engine_version`         | `string`       | `"17.5"`                    | PostgreSQL version (RDS and Aurora)        |
| `truefoundry_db_instance_class`         | `string`       | `null`                      | Instance class (defaults by engine)        |
| `truefoundry_db_instance_count`         | `number`       | `1`                         | Aurora cluster instances (ignored for RDS) |
| `truefoundry_db_cloudwatch_log_exports` | `list(string)` | `["postgresql", "upgrade"]` | Log exports (upgrade filtered for Aurora)  |




### Global Cluster (Submodule Inputs)


| Variable                                      | Type     | Default | Description                                                          |
| --------------------------------------------- | -------- | ------- | -------------------------------------------------------------------- |
| `truefoundry_aurora_global_cluster_identifier`| `string` | n/a     | Global cluster identifier                                            |
| `truefoundry_aurora_secondary_config`         | `object` | n/a     | Secondary cluster config (DR VPC, subnets, encryption, ingress, …) |
| `truefoundry_db_engine_version`               | `string` | `"17.5"`| Must match the primary Aurora cluster engine version                 |
| `truefoundry_db_port`                         | `number` | `5432`  | Database port (shared with primary)                                  |


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

Aurora Global submodule outputs (from `module.aurora_global`):

| Output                                                          | Description               |
| --------------------------------------------------------------- | ------------------------- |
| `truefoundry_aurora_global_cluster_id`                         | Global cluster ID         |
| `truefoundry_aurora_global_cluster_arn`                        | Global cluster ARN        |
| `truefoundry_aurora_secondary_cluster_endpoint`                 | Secondary endpoint        |
| `truefoundry_aurora_secondary_cluster_reader_endpoint`          | Secondary reader endpoint |
| `truefoundry_aurora_secondary_cluster_arn`                      | Secondary cluster ARN     |


---



## FAQ



### Can I switch from Aurora back to RDS?

Yes, by changing `truefoundry_db_engine_mode` back to `"rds"`. This will destroy the Aurora cluster and create an RDS instance. You must migrate data back manually before switching.

### What happens to the shared resources (subnet group, security groups)?

They are shared between RDS and Aurora. Switching engine modes does not recreate them, so there is no disruption to networking configuration.

### Can I use Aurora without a global cluster?

Yes. Keep only `module "control_plane"` and do not instantiate `module "aurora_global"`. Also pass the default provider for `aws.secondary`:

```hcl
providers = {
  aws           = aws
  aws.secondary = aws  # unused, pass default
}
```



### What PostgreSQL versions are compatible?

Aurora PostgreSQL versions are different from standard RDS PostgreSQL versions. Check [AWS Aurora PostgreSQL version compatibility](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.Updates.html) for the latest supported versions. The module defaults to `17.4`.

### Can I add more than one secondary region?

The `aurora-global` submodule supports one secondary region out of the box. For additional secondaries, create them outside the submodule using `module.aurora_global.truefoundry_aurora_global_cluster_id`:

```hcl
resource "aws_rds_cluster" "additional_secondary" {
  provider                  = aws.another_region
  cluster_identifier        = "my-cluster-aurora-apac"
  global_cluster_identifier = module.aurora_global.truefoundry_aurora_global_cluster_id
  engine                    = "aurora-postgresql"
  engine_version            = "17.4"
  # ... networking, etc.
}
```

