data "aws_region" "secondary" {
  provider = aws.secondary
}

resource "aws_rds_global_cluster" "truefoundry" {
  global_cluster_identifier    = var.truefoundry_aurora_global_cluster_identifier
  deletion_protection          = local.secondary_config.deletion_protection
  force_destroy                = !local.secondary_config.deletion_protection
  tags                         = local.tags
}

resource "aws_db_subnet_group" "truefoundry_aurora_secondary" {
  provider   = aws.secondary
  name       = local.secondary_subnet_group_name
  subnet_ids = local.secondary_config.subnet_ids
  tags       = local.secondary_tags
}

resource "aws_security_group" "truefoundry_aurora_secondary" {
  provider = aws.secondary
  name     = local.secondary_security_group_name
  vpc_id   = local.secondary_config.vpc_id
  tags     = local.secondary_tags

  ingress {
    from_port       = var.truefoundry_db_port
    to_port         = var.truefoundry_db_port
    protocol        = "tcp"
    security_groups = local.secondary_config.ingress_security_group_ids
    cidr_blocks     = local.secondary_config.ingress_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_rds_cluster_parameter_group" "truefoundry_aurora_secondary" {
  count    = local.secondary_config.postgres_parameter_group_enabled ? 1 : 0
  provider = aws.secondary
  name     = local.secondary_parameter_group_name
  family   = local.aurora_parameter_group_family
  tags     = local.secondary_tags

  dynamic "parameter" {
    for_each = local.secondary_config.postgres_parameter_group_parameters
    content {
      name  = parameter.value.name
      value = parameter.value.value
      apply_method = parameter.value.apply_method
    }
  }
}

data "aws_iam_policy_document" "aurora_secondary_monitoring_assume" {
  count = local.aurora_secondary_create_monitoring_role ? 1 : 0
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["monitoring.rds.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [var.aws_account_id]
    }
  }
}

resource "aws_iam_role" "aurora_secondary_monitoring" {
  count                = local.aurora_secondary_create_monitoring_role ? 1 : 0
  name                 = local.aurora_secondary_monitoring_role_name
  name_prefix          = local.aurora_secondary_monitoring_role_name == null ? "${substr(local.secondary_cluster_identifier, 0, 25)}-mon-" : null
  description          = "Enhanced monitoring role for Aurora secondary cluster ${local.secondary_cluster_identifier}"
  assume_role_policy   = data.aws_iam_policy_document.aurora_secondary_monitoring_assume[0].json
  permissions_boundary = local.secondary_config.monitoring_role_permission_boundary_arn
  tags                 = local.secondary_tags
}

resource "aws_iam_role_policy_attachment" "aurora_secondary_monitoring" {
  count      = local.aurora_secondary_create_monitoring_role ? 1 : 0
  role       = aws_iam_role.aurora_secondary_monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

resource "aws_rds_cluster" "truefoundry_aurora_secondary" {
  provider                              = aws.secondary
  cluster_identifier                    = local.secondary_cluster_identifier
  global_cluster_identifier             = aws_rds_global_cluster.truefoundry.id
  engine                                = "aurora-postgresql"
  engine_version                        = var.truefoundry_db_engine_version
  port                                  = var.truefoundry_db_port
  db_subnet_group_name                  = aws_db_subnet_group.truefoundry_aurora_secondary.name
  vpc_security_group_ids                = concat([aws_security_group.truefoundry_aurora_secondary.id], local.secondary_config.additional_security_group_ids)
  db_cluster_parameter_group_name       = local.secondary_config.postgres_parameter_group_enabled ? aws_rds_cluster_parameter_group.truefoundry_aurora_secondary[0].name : null
  performance_insights_enabled          = local.secondary_config.enable_insights
  performance_insights_retention_period = local.secondary_config.enable_insights ? 31 : null
  monitoring_role_arn                   = local.aurora_secondary_monitoring_role_arn
  backup_retention_period               = local.secondary_config.backup_retention_period
  deletion_protection                   = local.secondary_config.deletion_protection
  skip_final_snapshot                   = local.secondary_config.skip_final_snapshot
  storage_encrypted                     = local.secondary_config.storage_encrypted
  kms_key_id                            = local.secondary_config.storage_encrypted ? local.secondary_config.kms_key_id : null
  enabled_cloudwatch_logs_exports       = local.secondary_cloudwatch_log_exports
  iam_database_authentication_enabled   = local.secondary_config.iam_database_authentication_enabled
  apply_immediately                     = true
  tags                                  = local.secondary_tags

  lifecycle {
    ignore_changes = [replication_source_identifier]
  }
}

resource "aws_rds_cluster_instance" "truefoundry_aurora_secondary" {
  count                                 = local.secondary_config.instance_count
  provider                              = aws.secondary
  identifier                            = length(local.secondary_config.instances_identifier) != 0 && trimspace(local.secondary_config.instances_identifier[count.index]) != "" ? local.secondary_config.instances_identifier[count.index] : "${local.secondary_cluster_identifier}-instance-${count.index + 1}"
  cluster_identifier                    = aws_rds_cluster.truefoundry_aurora_secondary.id
  engine                                = "aurora-postgresql"
  copy_tags_to_snapshot                 = true
  engine_version                        = var.truefoundry_db_engine_version
  instance_class                        = local.secondary_config.instance_class
  db_subnet_group_name                  = aws_db_subnet_group.truefoundry_aurora_secondary.name
  performance_insights_enabled          = local.secondary_config.enable_insights
  performance_insights_retention_period = local.secondary_config.enable_insights ? 31 : null
  monitoring_interval                   = local.secondary_config.enable_monitoring ? local.secondary_config.monitoring_interval : null
  monitoring_role_arn                   = local.aurora_secondary_monitoring_role_arn
  publicly_accessible                   = local.secondary_config.publicly_accessible
  apply_immediately                     = true
  tags                                  = local.secondary_tags
}