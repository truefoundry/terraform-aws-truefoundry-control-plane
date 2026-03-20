##################################################################################
## Aurora Global Database (optional, for multi-region)
##################################################################################

resource "aws_rds_global_cluster" "truefoundry" {
  count                        = local.global_cluster_enabled ? 1 : 0
  global_cluster_identifier    = "${local.truefoundry_aurora_unique_name}-global"
  source_db_cluster_identifier = aws_rds_cluster.truefoundry_aurora[0].arn
  deletion_protection          = var.truefoundry_db_deletion_protection
  force_destroy                = !var.truefoundry_db_deletion_protection
}

##################################################################################
## Aurora Primary Cluster
##################################################################################

resource "aws_rds_cluster_parameter_group" "truefoundry_aurora_parameter_group" {
  count  = local.aurora_enabled && var.truefoundry_db_postgres_parameter_group_enabled ? 1 : 0
  name   = var.truefoundry_db_postgres_parameter_group_override_enabled ? "${var.truefoundry_db_postgres_parameter_group_override_name}-aurora" : "${local.truefoundry_aurora_unique_name}-pg"
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
  engine_version                      = var.truefoundry_aurora_engine_version
  port                                = local.truefoundry_db_port
  database_name                       = var.truefoundry_db_database_name
  master_username                     = local.truefoundry_db_master_username
  master_password                     = var.manage_master_user_password ? null : random_password.truefoundry_db_password[0].result
  manage_master_user_password         = var.manage_master_user_password ? true : null
  master_user_secret_kms_key_id       = var.manage_master_user_password ? aws_kms_key.truefoundry_db_master_user_secret_kms_key[0].arn : null
  db_subnet_group_name                = aws_db_subnet_group.rds[0].name
  vpc_security_group_ids              = concat([aws_security_group.rds[0].id], aws_security_group.rds-public[*].id, var.truefoundry_db_additional_security_group_ids)
  db_cluster_parameter_group_name     = var.truefoundry_db_postgres_parameter_group_enabled ? aws_rds_cluster_parameter_group.truefoundry_aurora_parameter_group[0].name : null
  backup_retention_period             = var.truefoundry_db_backup_retention_period
  deletion_protection                 = var.truefoundry_db_deletion_protection
  skip_final_snapshot                 = var.truefoundry_db_skip_final_snapshot
  final_snapshot_identifier           = var.truefoundry_db_skip_final_snapshot ? null : "${var.truefoundry_db_database_name}-aurora-${formatdate("DD-MM-YYYY-hh-mm-ss", timestamp())}"
  storage_encrypted                   = var.truefoundry_db_storage_encrypted
  enabled_cloudwatch_logs_exports     = var.truefoundry_aurora_cloudwatch_log_exports
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
  count                                 = local.aurora_enabled ? var.truefoundry_aurora_instance_count : 0
  identifier                            = "${local.truefoundry_aurora_unique_name}-${count.index + 1}"
  cluster_identifier                    = aws_rds_cluster.truefoundry_aurora[0].id
  engine                                = "aurora-postgresql"
  engine_version                        = var.truefoundry_aurora_engine_version
  instance_class                        = var.truefoundry_aurora_instance_class
  db_subnet_group_name                  = aws_db_subnet_group.rds[0].name
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

##################################################################################
## Aurora Secondary Cluster (DR region, uses aws.secondary provider)
##################################################################################

resource "aws_db_subnet_group" "aurora_secondary" {
  count      = local.secondary_enabled ? 1 : 0
  provider   = aws.secondary
  name       = "${var.truefoundry_aurora_secondary_config.cluster_identifier}-subnet"
  subnet_ids = var.truefoundry_aurora_secondary_config.subnet_ids
  tags       = merge(local.tags, var.truefoundry_aurora_secondary_config.tags)
}

resource "aws_security_group" "aurora_secondary" {
  count    = local.secondary_enabled ? 1 : 0
  provider = aws.secondary
  name     = "${var.truefoundry_aurora_secondary_config.cluster_identifier}-sg"
  vpc_id   = var.truefoundry_aurora_secondary_config.vpc_id
  tags     = merge(local.tags, var.truefoundry_aurora_secondary_config.tags)

  ingress {
    from_port       = local.truefoundry_db_port
    to_port         = local.truefoundry_db_port
    protocol        = "tcp"
    security_groups = var.truefoundry_aurora_secondary_config.ingress_security_group_ids
    cidr_blocks     = var.truefoundry_aurora_secondary_config.ingress_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_rds_cluster_parameter_group" "aurora_secondary" {
  count    = local.secondary_enabled && var.truefoundry_db_postgres_parameter_group_enabled ? 1 : 0
  provider = aws.secondary
  name     = "${var.truefoundry_aurora_secondary_config.cluster_identifier}-pg"
  family   = local.aurora_parameter_group_family
  tags     = merge(local.tags, var.truefoundry_aurora_secondary_config.tags)

  parameter {
    name  = "rds.force_ssl"
    value = "0"
  }
}

resource "aws_kms_key" "aurora_secondary" {
  count               = local.secondary_enabled && var.truefoundry_db_storage_encrypted && var.truefoundry_aurora_secondary_config.kms_key_id == null ? 1 : 0
  provider            = aws.secondary
  enable_key_rotation = true
  description         = "Encryption key for Aurora secondary cluster ${var.truefoundry_aurora_secondary_config.cluster_identifier}"
  tags                = merge(local.tags, var.truefoundry_aurora_secondary_config.tags)
}

resource "aws_kms_alias" "aurora_secondary" {
  count         = local.secondary_enabled && var.truefoundry_db_storage_encrypted && var.truefoundry_aurora_secondary_config.kms_key_id == null ? 1 : 0
  provider      = aws.secondary
  name          = "alias/${var.truefoundry_aurora_secondary_config.cluster_identifier}-kms"
  target_key_id = aws_kms_key.aurora_secondary[0].id
}

resource "aws_rds_cluster" "aurora_secondary" {
  count                           = local.secondary_enabled ? 1 : 0
  provider                        = aws.secondary
  cluster_identifier              = var.truefoundry_aurora_secondary_config.cluster_identifier
  global_cluster_identifier       = aws_rds_global_cluster.truefoundry[0].id
  engine                          = "aurora-postgresql"
  engine_version                  = var.truefoundry_aurora_engine_version
  port                            = local.truefoundry_db_port
  db_subnet_group_name            = aws_db_subnet_group.aurora_secondary[0].name
  vpc_security_group_ids          = concat([aws_security_group.aurora_secondary[0].id], var.truefoundry_aurora_secondary_config.additional_security_group_ids)
  db_cluster_parameter_group_name = var.truefoundry_db_postgres_parameter_group_enabled ? aws_rds_cluster_parameter_group.aurora_secondary[0].name : null
  backup_retention_period         = var.truefoundry_aurora_secondary_config.backup_retention_period
  deletion_protection             = var.truefoundry_db_deletion_protection
  skip_final_snapshot             = var.truefoundry_db_skip_final_snapshot
  storage_encrypted               = var.truefoundry_db_storage_encrypted
  kms_key_id                      = var.truefoundry_db_storage_encrypted ? coalesce(var.truefoundry_aurora_secondary_config.kms_key_id, try(aws_kms_key.aurora_secondary[0].arn, null)) : null
  enabled_cloudwatch_logs_exports = var.truefoundry_aurora_cloudwatch_log_exports
  apply_immediately               = true
  tags                            = merge(local.tags, var.truefoundry_aurora_secondary_config.tags)

  depends_on = [aws_rds_cluster_instance.truefoundry_aurora]

  lifecycle {
    ignore_changes = [replication_source_identifier]
  }
}

resource "aws_rds_cluster_instance" "aurora_secondary" {
  count                                 = local.secondary_enabled ? var.truefoundry_aurora_secondary_config.instance_count : 0
  provider                              = aws.secondary
  identifier                            = "${var.truefoundry_aurora_secondary_config.cluster_identifier}-${count.index + 1}"
  cluster_identifier                    = aws_rds_cluster.aurora_secondary[0].id
  engine                                = "aurora-postgresql"
  engine_version                        = var.truefoundry_aurora_engine_version
  instance_class                        = var.truefoundry_aurora_secondary_config.instance_class
  db_subnet_group_name                  = aws_db_subnet_group.aurora_secondary[0].name
  performance_insights_enabled          = var.truefoundry_aurora_secondary_config.enable_insights
  performance_insights_retention_period = var.truefoundry_aurora_secondary_config.enable_insights ? 31 : null
  publicly_accessible                   = var.truefoundry_aurora_secondary_config.publicly_accessible
  apply_immediately                     = true
  tags                                  = merge(local.tags, var.truefoundry_aurora_secondary_config.tags)
}

##################################################################################
## Automated Failover Pipeline (deployed in DR region)
##
## CloudWatch Alarm (replication lag missing or too high)
##   → EventBridge Rule
##     → Lambda (failover-global-cluster)
##       → SNS notification
##
## All resources use aws.secondary so they stay operational when the primary
## region is down.
##################################################################################

resource "aws_sns_topic" "failover_alerts" {
  count    = local.secondary_enabled ? 1 : 0
  provider = aws.secondary
  name     = "${var.truefoundry_aurora_secondary_config.cluster_identifier}-failover-alerts"
  tags     = merge(local.tags, var.truefoundry_aurora_secondary_config.tags)
}

resource "aws_sns_topic_subscription" "failover_email" {
  count     = local.secondary_enabled && var.truefoundry_aurora_alert_email != "" ? 1 : 0
  provider  = aws.secondary
  topic_arn = aws_sns_topic.failover_alerts[0].arn
  protocol  = "email"
  endpoint  = var.truefoundry_aurora_alert_email
}

data "aws_iam_policy_document" "failover_lambda_assume" {
  count = local.secondary_enabled ? 1 : 0
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "failover_lambda_policy" {
  count = local.secondary_enabled ? 1 : 0
  statement {
    sid       = "RDSFailover"
    effect    = "Allow"
    actions   = ["rds:FailoverGlobalCluster", "rds:DescribeGlobalClusters"]
    resources = ["*"]
  }
  statement {
    sid       = "SNSPublish"
    effect    = "Allow"
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.failover_alerts[0].arn]
  }
  statement {
    sid       = "Logs"
    effect    = "Allow"
    actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["arn:aws:logs:*:*:*"]
  }
}

resource "aws_iam_role" "failover_lambda" {
  count              = local.secondary_enabled ? 1 : 0
  provider           = aws.secondary
  name               = "${var.truefoundry_aurora_secondary_config.cluster_identifier}-failover-role"
  assume_role_policy = data.aws_iam_policy_document.failover_lambda_assume[0].json
  tags               = merge(local.tags, var.truefoundry_aurora_secondary_config.tags)
}

resource "aws_iam_role_policy" "failover_lambda" {
  count    = local.secondary_enabled ? 1 : 0
  provider = aws.secondary
  name     = "${var.truefoundry_aurora_secondary_config.cluster_identifier}-failover-policy"
  role     = aws_iam_role.failover_lambda[0].id
  policy   = data.aws_iam_policy_document.failover_lambda_policy[0].json
}

data "archive_file" "failover_lambda" {
  count       = local.secondary_enabled ? 1 : 0
  type        = "zip"
  output_path = "${path.module}/failover_lambda.zip"
  source {
    content  = file("${path.module}/failover_lambda.py")
    filename = "lambda_function.py"
  }
}

resource "aws_lambda_function" "failover" {
  count            = local.secondary_enabled ? 1 : 0
  provider         = aws.secondary
  function_name    = "${var.truefoundry_aurora_secondary_config.cluster_identifier}-failover"
  role             = aws_iam_role.failover_lambda[0].arn
  handler          = "lambda_function.handler"
  runtime          = "python3.12"
  filename         = data.archive_file.failover_lambda[0].output_path
  source_code_hash = data.archive_file.failover_lambda[0].output_base64sha256
  timeout          = 300
  tags             = merge(local.tags, var.truefoundry_aurora_secondary_config.tags)

  environment {
    variables = {
      GLOBAL_CLUSTER = aws_rds_global_cluster.truefoundry[0].id
      DR_CLUSTER_ARN = aws_rds_cluster.aurora_secondary[0].arn
      DR_REGION      = data.aws_region.secondary[0].id
      SNS_TOPIC_ARN  = aws_sns_topic.failover_alerts[0].arn
    }
  }
}

data "aws_region" "secondary" {
  count    = local.secondary_enabled ? 1 : 0
  provider = aws.secondary
}

resource "aws_cloudwatch_log_group" "failover_lambda" {
  count             = local.secondary_enabled ? 1 : 0
  provider          = aws.secondary
  name              = "/aws/lambda/${aws_lambda_function.failover[0].function_name}"
  retention_in_days = 30
  tags              = merge(local.tags, var.truefoundry_aurora_secondary_config.tags)
}

resource "aws_cloudwatch_metric_alarm" "replication_lag" {
  count               = local.secondary_enabled ? 1 : 0
  provider            = aws.secondary
  alarm_name          = "${var.truefoundry_aurora_secondary_config.cluster_identifier}-replication-lag"
  alarm_description   = "Aurora replication lag missing or too high — primary region may be down"
  namespace           = "AWS/RDS"
  metric_name         = "AuroraGlobalDBReplicationLag"
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = var.truefoundry_aurora_alarm_evaluation_periods
  threshold           = 30000
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "breaching"

  dimensions = {
    DBClusterIdentifier = aws_rds_cluster.aurora_secondary[0].cluster_identifier
  }

  alarm_actions             = [aws_sns_topic.failover_alerts[0].arn]
  ok_actions                = [aws_sns_topic.failover_alerts[0].arn]
  insufficient_data_actions = []
  tags                      = merge(local.tags, var.truefoundry_aurora_secondary_config.tags)
}

resource "aws_cloudwatch_event_rule" "failover_trigger" {
  count       = local.secondary_enabled ? 1 : 0
  provider    = aws.secondary
  name        = "${var.truefoundry_aurora_secondary_config.cluster_identifier}-failover-trigger"
  description = "Triggers Aurora failover Lambda when replication lag alarm fires"
  tags        = merge(local.tags, var.truefoundry_aurora_secondary_config.tags)

  event_pattern = jsonencode({
    source      = ["aws.cloudwatch"]
    detail-type = ["CloudWatch Alarm State Change"]
    detail = {
      alarmName = [aws_cloudwatch_metric_alarm.replication_lag[0].alarm_name]
      state     = { value = ["ALARM"] }
    }
  })
}

resource "aws_cloudwatch_event_target" "failover_lambda" {
  count     = local.secondary_enabled ? 1 : 0
  provider  = aws.secondary
  rule      = aws_cloudwatch_event_rule.failover_trigger[0].name
  target_id = "${var.truefoundry_aurora_secondary_config.cluster_identifier}-failover"
  arn       = aws_lambda_function.failover[0].arn
}

resource "aws_lambda_permission" "eventbridge_invoke" {
  count         = local.secondary_enabled ? 1 : 0
  provider      = aws.secondary
  statement_id  = "eventbridge-invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.failover[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.failover_trigger[0].arn
}

