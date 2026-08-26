locals {
  aurora_parameter_group_family = "aurora-postgresql${split(".", var.truefoundry_db_engine_version)[0]}"

  secondary_config = var.truefoundry_aurora_secondary_config
  secondary_enabled = var.truefoundry_aurora_secondary_config != null

  secondary_cluster_identifier   = length(local.secondary_config.cluster_identifier) != 0 && trimspace(local.secondary_config.cluster_identifier) != "" ? local.secondary_config.cluster_identifier : "${var.secondary_cluster_name}-cluster"
  secondary_subnet_group_name    = var.truefoundry_db_subnet_group_name_override_enabled ? var.truefoundry_db_subnet_group_name_override : "${var.secondary_cluster_name}-subnet"
  secondary_security_group_name  = var.truefoundry_db_security_group_name_override_enabled ? var.truefoundry_db_security_group_name_override : "${var.secondary_cluster_name}-db-sg"
  secondary_parameter_group_name = var.truefoundry_db_postgres_parameter_group_override_enabled ? var.truefoundry_db_postgres_parameter_group_override_name : "${var.secondary_cluster_name}-db-pg"
  secondary_cloudwatch_log_exports = [
    for log in local.secondary_config.cloudwatch_log_exports : log if log != "upgrade"
  ]

  aurora_secondary_monitoring_role_external_enabled = local.secondary_enabled && (
    local.secondary_config.monitoring_role_enable_override ||
    trimspace(local.secondary_config.monitoring_role_arn) != ""
  )
  aurora_secondary_create_monitoring_role = local.secondary_enabled && local.secondary_config.enable_monitoring && !local.aurora_secondary_monitoring_role_external_enabled
  aurora_secondary_monitoring_role_name   = local.secondary_config.monitoring_role_name_override_enabled ? local.secondary_config.monitoring_role_name_override : null
  aurora_secondary_monitoring_role_arn = local.secondary_enabled && local.secondary_config.enable_monitoring ? (
    local.aurora_secondary_monitoring_role_external_enabled ?
    local.secondary_config.monitoring_role_arn :
    try(aws_iam_role.aurora_secondary_monitoring[0].arn, null)
  ) : null

  tags = merge(
    var.disable_default_tags ? {} : {
      "truefoundry-terraform-module" = "control-plane"
      "truefoundry-managed"          = "true"
      "truefoundry-cluster-name"     = var.cluster_name
      "cluster-name"                 = var.cluster_name
    },
    var.tags
  )

  secondary_tags = merge(local.tags, local.secondary_config.tags)
}
