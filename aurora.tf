##################################################################################
## Aurora Primary Cluster
##################################################################################

resource "aws_rds_cluster_parameter_group" "truefoundry_aurora_parameter_group" {
  count  = local.aurora_enabled && var.truefoundry_db_postgres_parameter_group_enabled ? 1 : 0
  name   = var.truefoundry_db_postgres_parameter_group_override_enabled ? var.truefoundry_db_postgres_parameter_group_override_name : "${local.truefoundry_aurora_unique_name}-pg"
  family = local.aurora_parameter_group_family
  tags   = local.tags

  parameter {
    name  = "rds.force_ssl"
    value = "0"
  }
}

resource "aws_rds_cluster" "truefoundry_aurora" {
  count                               = local.aurora_enabled ? 1 : 0
  cluster_identifier                  = var.truefoundry_db_enable_override ? "${var.truefoundry_db_override_name}-aurora" : null
  cluster_identifier_prefix           = var.truefoundry_db_enable_override ? null : local.truefoundry_aurora_unique_name
  engine                              = "aurora-postgresql"
  engine_version                      = var.truefoundry_db_engine_version
  port                                = local.truefoundry_db_port
  database_name                       = var.truefoundry_db_database_name
  master_username                     = local.truefoundry_db_master_username
  master_password                     = var.manage_master_user_password ? null : random_password.truefoundry_db_password[0].result
  manage_master_user_password         = var.manage_master_user_password ? true : null
  master_user_secret_kms_key_id       = local.truefoundry_db_master_user_secret_kms_key_arn
  db_subnet_group_name                = local.truefoundry_db_subnet_group_name
  vpc_security_group_ids              = concat([aws_security_group.rds[0].id], aws_security_group.rds-public[*].id, var.truefoundry_db_additional_security_group_ids)
  db_cluster_parameter_group_name     = var.truefoundry_db_postgres_parameter_group_enabled ? aws_rds_cluster_parameter_group.truefoundry_aurora_parameter_group[0].name : null
  backup_retention_period             = var.truefoundry_db_backup_retention_period
  deletion_protection                 = var.truefoundry_db_deletion_protection
  skip_final_snapshot                 = var.truefoundry_db_skip_final_snapshot
  final_snapshot_identifier           = var.truefoundry_db_skip_final_snapshot ? null : "${var.truefoundry_db_database_name}-aurora-${formatdate("DD-MM-YYYY-hh-mm-ss", timestamp())}"
  storage_encrypted                   = var.truefoundry_db_storage_encrypted
  kms_key_id                          = var.truefoundry_db_storage_encrypted ? var.truefoundry_db_kms_key_arn : null
  enabled_cloudwatch_logs_exports     = local.truefoundry_db_aurora_cloudwatch_log_exports
  iam_database_authentication_enabled = var.iam_database_authentication_enabled
  apply_immediately                   = true
  tags                                = local.tags

  lifecycle {
    ignore_changes = [
      cluster_identifier,
      final_snapshot_identifier,
      replication_source_identifier,
      global_cluster_identifier,
    ]
  }
}

resource "aws_rds_cluster_instance" "truefoundry_aurora" {
  count                                 = local.aurora_enabled ? var.truefoundry_db_instance_count : 0
  identifier                            = "${local.truefoundry_aurora_instance_identifier_prefix}-${count.index + 1}"
  cluster_identifier                    = aws_rds_cluster.truefoundry_aurora[0].cluster_identifier
  engine                                = "aurora-postgresql"
  engine_version                        = var.truefoundry_db_engine_version
  instance_class                        = local.truefoundry_db_instance_class
  db_subnet_group_name                  = local.truefoundry_db_subnet_group_name
  performance_insights_enabled          = var.truefoundry_db_enable_insights
  performance_insights_retention_period = var.truefoundry_db_enable_insights ? 31 : null
  monitoring_interval                   = local.truefoundry_db_monitoring_interval
  monitoring_role_arn                   = local.truefoundry_db_monitoring_role_arn
  publicly_accessible                   = var.truefoundry_db_publicly_accessible
  apply_immediately                     = true
  tags                                  = local.tags
}

resource "aws_secretsmanager_secret_rotation" "truefoundry_aurora_secret_rotation" {
  count              = local.aurora_enabled && var.manage_master_user_password && var.manage_master_user_password_rotation ? 1 : 0
  secret_id          = aws_rds_cluster.truefoundry_aurora[0].master_user_secret[0].secret_arn
  rotate_immediately = var.master_user_password_rotate_immediately
  rotation_rules {
    automatically_after_days = var.master_user_password_rotation_automatically_after_days
    duration                 = var.master_user_password_rotation_duration
  }
}

