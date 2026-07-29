data "aws_region" "secondary" {
  provider = aws.secondary
}

resource "aws_rds_global_cluster" "truefoundry" {
  global_cluster_identifier = var.truefoundry_aurora_global_cluster_identifier
  # source_db_cluster_identifier = var.primary_cluster_arn
  deletion_protection = var.truefoundry_db_deletion_protection
}

resource "aws_db_subnet_group" "truefoundry_aurora_secondary" {
  provider   = aws.secondary
  name       = local.secondary_subnet_group_name
  subnet_ids = var.truefoundry_aurora_secondary_config.subnet_ids
  tags       = merge(var.tags, var.truefoundry_aurora_secondary_config.tags)
}

resource "aws_security_group" "truefoundry_aurora_secondary" {
  provider = aws.secondary
  name     = local.secondary_security_group_name
  vpc_id   = var.truefoundry_aurora_secondary_config.vpc_id
  tags     = merge(var.tags, var.truefoundry_aurora_secondary_config.tags)

  ingress {
    from_port       = var.truefoundry_db_port
    to_port         = var.truefoundry_db_port
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

resource "aws_rds_cluster_parameter_group" "truefoundry_aurora_secondary" {
  count    = var.truefoundry_db_postgres_parameter_group_enabled ? 1 : 0
  provider = aws.secondary
  name     = local.secondary_parameter_group_name
  family   = local.aurora_parameter_group_family
  tags     = merge(var.tags, var.truefoundry_aurora_secondary_config.tags)

  parameter {
    name  = "rds.force_ssl"
    value = "0"
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
  permissions_boundary = var.truefoundry_aurora_secondary_config.monitoring_role_permission_boundary_arn
  tags                 = merge(var.tags, var.truefoundry_aurora_secondary_config.tags)
}

resource "aws_iam_role_policy_attachment" "aurora_secondary_monitoring" {
  count      = local.aurora_secondary_create_monitoring_role ? 1 : 0
  role       = aws_iam_role.aurora_secondary_monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

resource "aws_rds_cluster" "truefoundry_aurora_secondary" {
  provider                            = aws.secondary
  cluster_identifier                  = local.secondary_cluster_identifier
  global_cluster_identifier           = aws_rds_global_cluster.truefoundry.id
  engine                              = "aurora-postgresql"
  engine_version                      = var.truefoundry_db_engine_version
  port                                = var.truefoundry_db_port
  db_subnet_group_name                = aws_db_subnet_group.truefoundry_aurora_secondary.name
  vpc_security_group_ids              = concat([aws_security_group.truefoundry_aurora_secondary.id], var.truefoundry_aurora_secondary_config.additional_security_group_ids)
  db_cluster_parameter_group_name     = var.truefoundry_db_postgres_parameter_group_enabled ? aws_rds_cluster_parameter_group.truefoundry_aurora_secondary[0].name : null
  backup_retention_period             = var.truefoundry_aurora_secondary_config.backup_retention_period
  deletion_protection                 = var.truefoundry_db_deletion_protection
  skip_final_snapshot                 = var.truefoundry_db_skip_final_snapshot
  storage_encrypted                   = var.truefoundry_db_storage_encrypted
  kms_key_id                          = var.truefoundry_db_storage_encrypted ? var.truefoundry_aurora_secondary_config.kms_key_id : null
  enabled_cloudwatch_logs_exports     = var.truefoundry_db_aurora_cloudwatch_log_exports
  iam_database_authentication_enabled = var.iam_database_authentication_enabled
  apply_immediately                   = true
  tags                                = merge(var.tags, var.truefoundry_aurora_secondary_config.tags)

  lifecycle {
    ignore_changes = [replication_source_identifier]
  }
}

resource "aws_rds_cluster_instance" "truefoundry_aurora_secondary" {
  count                                 = var.truefoundry_aurora_secondary_config.instance_count
  provider                              = aws.secondary
  identifier                            = "${local.secondary_instance_identifier_prefix}-${count.index + 1}"
  cluster_identifier                    = aws_rds_cluster.truefoundry_aurora_secondary.id
  engine                                = "aurora-postgresql"
  copy_tags_to_snapshot                 = true
  engine_version                        = var.truefoundry_db_engine_version
  instance_class                        = var.truefoundry_aurora_secondary_config.instance_class
  db_subnet_group_name                  = aws_db_subnet_group.truefoundry_aurora_secondary.name
  performance_insights_enabled          = var.truefoundry_aurora_secondary_config.enable_insights
  performance_insights_retention_period = var.truefoundry_aurora_secondary_config.enable_insights ? 31 : null
  monitoring_interval                   = var.truefoundry_aurora_secondary_config.enable_monitoring ? var.truefoundry_aurora_secondary_config.monitoring_interval : null
  monitoring_role_arn                   = local.aurora_secondary_monitoring_role_arn
  publicly_accessible                   = var.truefoundry_aurora_secondary_config.publicly_accessible
  apply_immediately                     = true
  tags                                  = merge(var.tags, var.truefoundry_aurora_secondary_config.tags)
}

# resource "aws_sns_topic" "failover_alerts" {
#   provider = aws.secondary
#   name     = "${local.secondary_cluster_identifier}-failover-alerts"
#   tags     = merge(var.tags, var.truefoundry_aurora_secondary_config.tags)
# }

# resource "aws_sns_topic_subscription" "failover_email" {
#   count     = var.truefoundry_aurora_alert_email != "" ? 1 : 0
#   provider  = aws.secondary
#   topic_arn = aws_sns_topic.failover_alerts.arn
#   protocol  = "email"
#   endpoint  = var.truefoundry_aurora_alert_email
# }

# data "aws_iam_policy_document" "failover_lambda_assume" {
#   statement {
#     effect  = "Allow"
#     actions = ["sts:AssumeRole"]
#     principals {
#       type        = "Service"
#       identifiers = ["lambda.amazonaws.com"]
#     }
#   }
# }

# data "aws_iam_policy_document" "failover_lambda_policy" {
#   statement {
#     sid       = "RDSFailover"
#     effect    = "Allow"
#     actions   = ["rds:FailoverGlobalCluster", "rds:DescribeGlobalClusters"]
#     resources = ["*"]
#   }
#   statement {
#     sid       = "SNSPublish"
#     effect    = "Allow"
#     actions   = ["sns:Publish"]
#     resources = [aws_sns_topic.failover_alerts.arn]
#   }
#   statement {
#     sid       = "Logs"
#     effect    = "Allow"
#     actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
#     resources = ["arn:aws:logs:*:*:*"]
#   }
# }

# resource "aws_iam_role" "failover_lambda" {
#   provider           = aws.secondary
#   name               = "${local.secondary_cluster_identifier}-failover-role"
#   assume_role_policy = data.aws_iam_policy_document.failover_lambda_assume.json
#   tags               = merge(var.tags, var.truefoundry_aurora_secondary_config.tags)
# }

# resource "aws_iam_role_policy" "failover_lambda" {
#   provider = aws.secondary
#   name     = "${local.secondary_cluster_identifier}-failover-policy"
#   role     = aws_iam_role.failover_lambda.id
#   policy   = data.aws_iam_policy_document.failover_lambda_policy.json
# }

# data "archive_file" "failover_lambda" {
#   type        = "zip"
#   output_path = "${path.module}/failover_lambda.zip"
#   source {
#     content  = file("${path.module}/lambda/failover_lambda.py")
#     filename = "lambda_function.py"
#   }
# }

# resource "aws_lambda_function" "failover" {
#   provider         = aws.secondary
#   function_name    = "${local.secondary_cluster_identifier}-failover"
#   role             = aws_iam_role.failover_lambda.arn
#   handler          = "lambda_function.handler"
#   runtime          = "python3.12"
#   filename         = data.archive_file.failover_lambda.output_path
#   source_code_hash = data.archive_file.failover_lambda.output_base64sha256
#   timeout          = 300
#   tags             = merge(var.tags, var.truefoundry_aurora_secondary_config.tags)

#   environment {
#     variables = {
#       GLOBAL_CLUSTER = aws_rds_global_cluster.truefoundry.id
#       DR_CLUSTER_ARN = aws_rds_cluster.truefoundry_aurora_secondary.arn
#       DR_REGION      = data.aws_region.secondary.region
#       SNS_TOPIC_ARN  = aws_sns_topic.failover_alerts.arn
#     }
#   }
# }

# resource "aws_cloudwatch_log_group" "failover_lambda" {
#   provider          = aws.secondary
#   name              = "/aws/lambda/${aws_lambda_function.failover.function_name}"
#   retention_in_days = 30
#   tags              = merge(var.tags, var.truefoundry_aurora_secondary_config.tags)
# }

# resource "aws_cloudwatch_metric_alarm" "replication_lag" {
#   provider            = aws.secondary
#   alarm_name          = "${local.secondary_cluster_identifier}-replication-lag"
#   alarm_description   = "Aurora replication lag missing or too high — primary region may be down"
#   namespace           = "AWS/RDS"
#   metric_name         = "AuroraGlobalDBReplicationLag"
#   statistic           = "Maximum"
#   period              = 60
#   evaluation_periods  = var.truefoundry_aurora_alarm_evaluation_periods
#   threshold           = 30000
#   comparison_operator = "GreaterThanThreshold"
#   treat_missing_data  = var.truefoundry_aurora_alarm_treat_missing_data

#   dimensions = {
#     DBClusterIdentifier = aws_rds_cluster.truefoundry_aurora_secondary.cluster_identifier
#   }

#   alarm_actions             = [aws_sns_topic.failover_alerts.arn]
#   ok_actions                = [aws_sns_topic.failover_alerts.arn]
#   insufficient_data_actions = []
#   tags                      = merge(var.tags, var.truefoundry_aurora_secondary_config.tags)
# }

# resource "aws_cloudwatch_event_rule" "failover_trigger" {
#   count       = local.automated_failover_enabled ? 1 : 0
#   provider    = aws.secondary
#   name        = "${local.secondary_cluster_identifier}-failover-trigger"
#   description = "Triggers Aurora failover Lambda when replication lag alarm fires"
#   tags        = merge(var.tags, var.truefoundry_aurora_secondary_config.tags)

#   event_pattern = jsonencode({
#     source      = ["aws.cloudwatch"]
#     detail-type = ["CloudWatch Alarm State Change"]
#     detail = {
#       alarmName = [aws_cloudwatch_metric_alarm.replication_lag.alarm_name]
#       state     = { value = ["ALARM"] }
#     }
#   })
# }

# resource "aws_cloudwatch_event_target" "failover_lambda" {
#   count     = local.automated_failover_enabled ? 1 : 0
#   provider  = aws.secondary
#   rule      = aws_cloudwatch_event_rule.failover_trigger[0].name
#   target_id = "${local.secondary_cluster_identifier}-failover"
#   arn       = aws_lambda_function.failover.arn
# }

# resource "aws_lambda_permission" "eventbridge_invoke" {
#   count         = local.automated_failover_enabled ? 1 : 0
#   provider      = aws.secondary
#   statement_id  = "eventbridge-invoke"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.failover.function_name
#   principal     = "events.amazonaws.com"
#   source_arn    = aws_cloudwatch_event_rule.failover_trigger[0].arn
# }

data "aws_vpc" "peering_primary" {
  count = local.vpc_peering_enabled ? 1 : 0
  id    = var.vpc_id
}

data "aws_vpc" "peering_secondary" {
  count    = local.vpc_peering_enabled ? 1 : 0
  provider = aws.secondary
  id       = var.truefoundry_aurora_secondary_config.vpc_id
}

resource "aws_vpc_peering_connection" "primary_to_dr" {
  count       = local.vpc_peering_enabled ? 1 : 0
  vpc_id      = var.vpc_id
  peer_vpc_id = var.truefoundry_aurora_secondary_config.vpc_id
  peer_region = data.aws_region.secondary.region
  auto_accept = false
  tags = merge(
    var.tags,
    var.truefoundry_aurora_secondary_config.tags,
    { Name = "${var.truefoundry_aurora_global_cluster_identifier}-primary-to-dr" }
  )
}

resource "aws_vpc_peering_connection_accepter" "secondary" {
  count                     = local.vpc_peering_enabled ? 1 : 0
  provider                  = aws.secondary
  vpc_peering_connection_id = aws_vpc_peering_connection.primary_to_dr[0].id
  auto_accept               = true
  tags = merge(
    var.tags,
    var.truefoundry_aurora_secondary_config.tags,
    { Name = "${var.truefoundry_aurora_global_cluster_identifier}-primary-to-dr" }
  )
}

resource "aws_vpc_peering_connection_options" "primary" {
  count                     = local.vpc_peering_enabled && var.truefoundry_aurora_vpc_peering_allow_remote_dns_resolution ? 1 : 0
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.secondary[0].id

  requester {
    allow_remote_vpc_dns_resolution = true
  }
}

resource "aws_vpc_peering_connection_options" "secondary" {
  count                     = local.vpc_peering_enabled && var.truefoundry_aurora_vpc_peering_allow_remote_dns_resolution ? 1 : 0
  provider                  = aws.secondary
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.secondary[0].id

  accepter {
    allow_remote_vpc_dns_resolution = true
  }
}

resource "aws_route" "primary_to_dr" {
  for_each                  = local.vpc_peering_enabled ? toset(var.truefoundry_aurora_vpc_peering_primary_route_table_ids) : toset([])
  route_table_id            = each.value
  destination_cidr_block    = data.aws_vpc.peering_secondary[0].cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.primary_to_dr[0].id
}

resource "aws_route" "dr_to_primary" {
  for_each                  = local.vpc_peering_enabled ? toset(var.truefoundry_aurora_vpc_peering_dr_route_table_ids) : toset([])
  provider                  = aws.secondary
  route_table_id            = each.value
  destination_cidr_block    = data.aws_vpc.peering_primary[0].cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.primary_to_dr[0].id
}
