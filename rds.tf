resource "random_password" "truefoundry_db_password" {
  count            = var.truefoundry_db_enabled ? var.manage_master_user_password ? 0 : 1 : 0
  length           = 24
  special          = true
  override_special = "#%&*()-_=+[]{}<>:"
}

resource "aws_db_subnet_group" "rds" {
  count      = var.truefoundry_db_enabled ? 1 : 0
  name       = "${local.truefoundry_db_unique_name}-rds"
  subnet_ids = var.truefoundry_db_subnet_ids
  tags       = local.tags
}

resource "aws_security_group" "rds" {
  count  = var.truefoundry_db_enabled ? 1 : 0
  name   = "${local.truefoundry_db_unique_name}-rds"
  vpc_id = var.vpc_id
  tags   = local.tags

  ingress {
    from_port       = local.truefoundry_db_port
    to_port         = local.truefoundry_db_port
    protocol        = "tcp"
    security_groups = var.truefoundry_db_ingress_security_group != "" ? [var.truefoundry_db_ingress_security_group] : []
    cidr_blocks     = length(var.truefoundry_db_ingress_cidr_blocks) > 0 ? var.truefoundry_db_ingress_cidr_blocks : []
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_security_group" "rds-public" {
  count  = var.truefoundry_db_enabled ? var.truefoundry_db_publicly_accessible ? 1 : 0 : 0
  name   = "${local.truefoundry_db_unique_name}-rds-public"
  vpc_id = var.vpc_id
  tags   = local.tags

  ingress {
    from_port   = local.truefoundry_db_port
    to_port     = local.truefoundry_db_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "truefoundry_db" {
  count                                 = var.truefoundry_db_enabled ? 1 : 0
  tags                                  = local.tags
  engine                                = "postgres"
  engine_version                        = var.truefoundry_db_engine_version
  multi_az                              = var.truefoundry_db_multiple_az
  allocated_storage                     = var.truefoundry_db_allocated_storage
  max_allocated_storage                 = var.truefoundry_db_max_allocated_storage
  port                                  = local.truefoundry_db_port
  db_subnet_group_name                  = aws_db_subnet_group.rds[0].name
  vpc_security_group_ids                = concat([aws_security_group.rds[0].id], aws_security_group.rds-public[*].id)
  username                              = local.truefoundry_db_master_username
  identifier                            = var.truefoundry_db_enable_override ? var.truefoundry_db_override_name : null
  identifier_prefix                     = var.truefoundry_db_enable_override ? null : local.truefoundry_db_unique_name
  db_name                               = var.truefoundry_db_database_name
  skip_final_snapshot                   = var.truefoundry_db_skip_final_snapshot
  password                              = var.manage_master_user_password ? null : random_password.truefoundry_db_password[0].result
  manage_master_user_password           = var.manage_master_user_password ? true : null
  master_user_secret_kms_key_id         = var.manage_master_user_password ? aws_kms_key.truefoundry_db_master_user_secret_kms_key[0].arn : null
  final_snapshot_identifier             = var.truefoundry_db_skip_final_snapshot ? null : "${var.truefoundry_db_database_name}-${formatdate("DD-MM-YYYY-hh-mm-ss", timestamp())}"
  backup_retention_period               = var.truefoundry_db_backup_retention_period
  instance_class                        = var.truefoundry_db_instance_class
  performance_insights_enabled          = var.truefoundry_db_enable_insights
  performance_insights_retention_period = var.truefoundry_db_enable_insights ? 31 : 0
  publicly_accessible                   = var.truefoundry_db_publicly_accessible
  deletion_protection                   = var.truefoundry_db_deletion_protection
  iam_database_authentication_enabled   = var.iam_database_authentication_enabled
  apply_immediately                     = true
  storage_encrypted                     = var.truefoundry_db_storage_encrypted
  enabled_cloudwatch_logs_exports       = var.truefoundry_cloudwatch_log_exports
  storage_type                          = var.truefoundry_db_storage_type
  iops                                  = var.truefoundry_db_storage_iops == 0 ? null : var.truefoundry_db_storage_iops

  lifecycle {
    ignore_changes = [
      identifier,
      final_snapshot_identifier
    ]
  }
}

resource "aws_secretsmanager_secret_rotation" "turefoundry_db_secret_rotation" {
  count              = var.truefoundry_db_enabled ? var.manage_master_user_password ? var.manage_master_user_password_rotation ? 1 : 0 : 0 : 0
  secret_id          = aws_db_instance.truefoundry_db[0].master_user_secret[0].secret_arn
  rotate_immediately = var.master_user_password_rotate_immediately
  rotation_rules {
    automatically_after_days = var.master_user_password_rotation_automatically_after_days
    duration                 = var.master_user_password_rotation_duration
  }
}
