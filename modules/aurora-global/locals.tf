locals {
  aurora_parameter_group_family = "aurora-postgresql${split(".", var.truefoundry_db_engine_version)[0]}"

  secondary_enabled = var.truefoundry_aurora_secondary_config != null

  secondary_cluster_identifier         = var.truefoundry_db_enable_override ? var.truefoundry_db_override_name : var.truefoundry_aurora_secondary_config.cluster_identifier
  secondary_instance_identifier_prefix = trimspace(var.truefoundry_aurora_secondary_config.instance_identifier) != "" ? var.truefoundry_aurora_secondary_config.instance_identifier : local.secondary_cluster_identifier
  secondary_subnet_group_name          = var.truefoundry_db_subnet_group_name_override_enabled ? var.truefoundry_db_subnet_group_name_override : "${local.secondary_cluster_identifier}-subnet"
  secondary_security_group_name        = var.truefoundry_db_security_group_name_override_enabled ? var.truefoundry_db_security_group_name_override : "${local.secondary_cluster_identifier}-sg"
  secondary_parameter_group_name       = var.truefoundry_db_postgres_parameter_group_override_enabled ? var.truefoundry_db_postgres_parameter_group_override_name : "${local.secondary_cluster_identifier}-pg"

  vpc_peering_enabled        = local.secondary_enabled && var.truefoundry_aurora_vpc_peering_enabled
  automated_failover_enabled = local.secondary_enabled && var.truefoundry_aurora_enable_automated_failover

  aurora_secondary_monitoring_role_external_enabled = local.secondary_enabled && (
    var.truefoundry_aurora_secondary_config.monitoring_role_enable_override ||
    trimspace(var.truefoundry_aurora_secondary_config.monitoring_role_arn) != ""
  )
  aurora_secondary_create_monitoring_role = local.secondary_enabled && var.truefoundry_aurora_secondary_config.enable_monitoring && !local.aurora_secondary_monitoring_role_external_enabled
  aurora_secondary_monitoring_role_name   = var.truefoundry_aurora_secondary_config.monitoring_role_name_override_enabled ? var.truefoundry_aurora_secondary_config.monitoring_role_name_override : null
  aurora_secondary_monitoring_role_arn = local.secondary_enabled && var.truefoundry_aurora_secondary_config.enable_monitoring ? (
    local.aurora_secondary_monitoring_role_external_enabled ?
    var.truefoundry_aurora_secondary_config.monitoring_role_arn :
    try(aws_iam_role.aurora_secondary_monitoring[0].arn, null)
  ) : null
}
