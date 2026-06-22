# terraform-aws-truefoundry-control-plane — Upgrade Guide

This guide helps you migrate Terraform / OpenTofu state across module versions. Keeping to the latest version is always recommended.

- [Upgrade 0.4.x to 0.5.x](#upgrade-04x-to-05x)
- [Upgrade 0.3.x to 0.4.x](#upgrade-03x-to-04x)

---

## Upgrade 0.4.x to 0.5.x

The `0.5.x` line adds Aurora PostgreSQL and Aurora Global Database support alongside the existing RDS engine. **The default engine stays `rds`, all existing RDS variables keep their names and defaults, and no `terraform state mv` is required to stay on RDS.**

There are only three things you must do to upgrade:

1. Add an `aws.secondary` provider stanza to the module call (required by the language, even if you're not using Aurora).
2. Bump your Terraform / OpenTofu and AWS provider versions.
3. Run `terraform plan` and confirm "No changes".

### What changed

| Area | 0.4.x | 0.5.x |
| --- | --- | --- |
| Default DB engine | RDS PostgreSQL | RDS PostgreSQL (unchanged) |
| Required Terraform / OpenTofu | `~> 1.4` | `~> 1.9` |
| Required AWS provider | `~> 5.57` | `~> 6.33` |
| Provider blocks needed in caller | `aws` | `aws` **and** `aws.secondary` |
| Removed variables | — | None |
| New variables (additive) | — | `truefoundry_db_engine_mode`, `truefoundry_aurora_*`, `truefoundry_db_kms_key_arn`, `truefoundry_db_master_user_secret_kms_key_arn`, `truefoundry_db_enable_monitoring` + interval + role, `truefoundry_db_postgres_parameter_group_enabled`, `truefoundry_s3_attach_cors_policy` |

No RDS-related variables were renamed or removed — your existing `truefoundry_db_*` inputs continue to work as-is.

### Step 1 — Bump Terraform / OpenTofu and the AWS provider

In the root that calls this module (not the module itself), make sure your version constraints allow:

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

If you're crossing AWS provider v5 → v6, read [the AWS provider v6 upgrade guide](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/guides/version-6-upgrade) for any provider-level behavior changes (default tags, region argument, etc.). Most v5 → v6 changes are transparent for the resources this module manages.

### Step 2 — Add the `aws.secondary` provider stanza

The module declares `configuration_aliases = [aws.secondary]` so it can wire up Aurora Global Database in a DR region. This is a Terraform language requirement: callers **must** pass a provider for that alias even when not using Aurora Global, because Terraform evaluates provider references during planning regardless of `count = 0`.

**If you're staying on RDS (or single-region Aurora)**, point the alias at your default provider — no DR resources will be created, and no second region will be configured:

```hcl
module "tfy_control_plane" {
  source  = "truefoundry/truefoundry-control-plane/aws"
  version = "0.5.0"

  providers = {
    aws           = aws
    aws.secondary = aws   # unused; reuses the default provider
  }

  # ... all your existing inputs unchanged ...
}
```

**If you intend to enable Aurora Global Database**, declare a second provider aliased to your DR region and pass it explicitly:

```hcl
provider "aws" {
  region = "<primary-region>"
}

provider "aws" {
  alias  = "dr"
  region = "<dr-region>"
}

module "tfy_control_plane" {
  source  = "truefoundry/truefoundry-control-plane/aws"
  version = "0.5.0"

  providers = {
    aws           = aws
    aws.secondary = aws.dr
  }

  # ...
}
```

### Step 3 — Plan and confirm "No changes"

```bash
terraform init -upgrade
terraform plan
```

For a stack that stays on RDS, the expected output is `No changes. Your infrastructure matches the configuration.` If you see proposed changes, they will fall into one of these categories:

- **Tag drift** from the AWS provider v6 default-tags behavior. Safe to apply; aligns state with provider defaults.
- **Parameter group ownership** if you previously managed the parameter group outside the module and `truefoundry_db_postgres_parameter_group_enabled` is now `true` (the default). Either keep using your own and set the flag to `false`, or accept module ownership.
- **Any `must be replaced` line on `aws_db_instance.truefoundry_db[0]`** — **do not apply.** Stop, compare the planned attributes against the current instance, and adjust your inputs to match (most often it's `engine_version`, `parameter_group_name`, or `kms_key_id`). RDS replacement = data loss for this path.

You should not need any `terraform state mv` commands to stay on RDS.

### Optional next steps

Once the upgrade is clean, you can opt in to Aurora or Aurora Global:

- **Switch to Aurora PostgreSQL** — see [Aurora migration guide › Option 2 / 2b](docs/aurora-migration-guide.md#option-2-migrating-from-rds-to-aurora).
- **Enable Aurora Global Database** — see [Aurora migration guide › Option 3](docs/aurora-migration-guide.md#option-3-aurora-global-database-multi-region-dr).
- **Stay on RDS with no other changes** — see [Aurora migration guide › Path 0](docs/aurora-migration-guide.md#path-0-stay-on-rds-no-migration).

---

## Upgrade 0.3.x to 0.4.x

1. Ensure you have migrated to the latest version of `0.3.x` which is `0.3.10`
2. Run a plan with `0.4.0` by executing `terraform plan` or `terragrunt plan`
3. Run the following command to perform the resource moving

```shell
# running state move of IAM role
terragrunt state mv module.truefoundry_oidc_iam.aws_iam_role.this[0] module.truefoundry_oidc_iam[0].aws_iam_role.this[0]

# running a for loop to move the related policies
for i in {0..5}
do
echo "Doing this for resource $i"
terragrunt state mv module.truefoundry_oidc_iam.aws_iam_role_policy_attachment.custom[$i] module.truefoundry_oidc_iam[0].aws_iam_role_policy_attachment.custom[$i]
echo "Resource $i is moved"
done

terragrunt state mv module.truefoundry_bucket.aws_s3_bucket.this[0] module.truefoundry_bucket[0].aws_s3_bucket.this[0]
terragrunt state mv module.truefoundry_bucket.aws_s3_bucket_cors_configuration.this[0] module.truefoundry_bucket[0].aws_s3_bucket_cors_configuration.this[0]
terragrunt state mv module.truefoundry_bucket.aws_s3_bucket_intelligent_tiering_configuration.this module.truefoundry_bucket[0].aws_s3_bucket_intelligent_tiering_configuration.this
terragrunt state mv module.truefoundry_bucket.aws_s3_bucket_lifecycle_configuration.this[0] module.truefoundry_bucket[0].aws_s3_bucket_lifecycle_configuration.this[0]
terragrunt state mv module.truefoundry_bucket.aws_s3_bucket_policy.this[0] module.truefoundry_bucket[0].aws_s3_bucket_policy.this[0]
terragrunt state mv module.truefoundry_bucket.aws_s3_bucket_public_access_block.this[0] module.truefoundry_bucket[0].aws_s3_bucket_public_access_block.this[0]
terragrunt state mv module.truefoundry_bucket.aws_s3_bucket_server_side_encryption_configuration.this[0] module.truefoundry_bucket[0].aws_s3_bucket_server_side_encryption_configuration.this[0]
terragrunt state mv module.truefoundry_bucket.aws_s3_bucket_versioning.this[0] module.truefoundry_bucket[0].aws_s3_bucket_versioning.this[0]
```
