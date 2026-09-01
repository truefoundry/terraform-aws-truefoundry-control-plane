locals {

  truefoundry_unique_name         = var.truefoundry_s3_enable_override ? var.truefoundry_s3_override_name : "${var.cluster_name}-truefoundry"
  truefoundry_trimmed_unique_name = trimsuffix(substr(local.truefoundry_unique_name, 0, 37), "-")

  truefoundry_db_unique_name = var.truefoundry_db_enable_override ? var.truefoundry_db_override_name : "${var.cluster_name}-db"

  svcfoundry_unique_name = "${var.cluster_name}-${var.svcfoundry_k8s_service_account}"

  rds_enabled    = var.truefoundry_db_enabled && var.truefoundry_db_engine_mode == "rds"
  aurora_enabled = var.truefoundry_db_enabled && var.truefoundry_db_engine_mode == "aurora"

  truefoundry_db_instance_class = coalesce(
    var.truefoundry_db_instance_class,
    var.truefoundry_db_engine_mode == "aurora" ? "db.r6g.large" : "db.t3.medium"
  )

  truefoundry_db_port            = 5432
  truefoundry_db_master_username = "root"

  tags = merge(
    var.disable_default_tags ? {} : {
      "truefoundry-terraform-module" = "control-plane"
      "truefoundry-managed"          = "true"
      "truefoundry-cluster-name"     = var.cluster_name
      "cluster-name"                 = var.cluster_name
    },
    var.tags
  )

  postgres_parameter_group_family = strcontains(var.truefoundry_db_engine_version, "17") ? "postgres17" : "postgres13"
  aurora_parameter_group_family   = "aurora-postgresql${split(".", var.truefoundry_db_engine_version)[0]}"

  # Aurora PostgreSQL only supports the postgresql log export type.
  truefoundry_db_aurora_cloudwatch_log_exports = [
    for log in var.truefoundry_db_cloudwatch_log_exports : log if log != "upgrade"
  ]

  truefoundry_aurora_unique_name                = var.truefoundry_db_enable_override ? var.truefoundry_db_override_name : "${var.cluster_name}-aurora"
  truefoundry_aurora_instance_identifier_prefix = local.truefoundry_aurora_unique_name

  truefoundry_iam_role_policy_prefix = var.truefoundry_iam_role_policy_prefix_override_enabled ? "${var.truefoundry_iam_role_policy_prefix_override_name}-${local.svcfoundry_unique_name}" : local.svcfoundry_unique_name

  truefoundry_db_monitoring_interval = var.truefoundry_db_enabled && var.truefoundry_db_enable_monitoring ? var.truefoundry_db_monitoring_interval : null
  truefoundry_db_monitoring_role_arn = var.truefoundry_db_enabled && var.truefoundry_db_enable_monitoring ? coalesce(var.truefoundry_db_monitoring_role_arn, try(aws_iam_role.truefoundry_db_monitoring_role[0].arn, null)) : null
  truefoundry_db_subnet_group_name   = var.truefoundry_db_enabled ? try(aws_db_subnet_group.rds[0].name, null) : null

  # Use the customer-provided KMS key for the master user secret when set, otherwise the module-created key.
  truefoundry_db_master_user_secret_kms_key_arn = var.truefoundry_db_enabled && var.manage_master_user_password ? (
    var.truefoundry_db_master_user_secret_kms_key_arn != null
    ? var.truefoundry_db_master_user_secret_kms_key_arn
    : aws_kms_key.truefoundry_db_master_user_secret_kms_key[0].arn
  ) : null
}
