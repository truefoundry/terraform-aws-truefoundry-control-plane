# policy for IAM based authentication to RDS
data "aws_iam_policy_document" "truefoundry_db_iam_auth_policy_document" {
  count = var.truefoundry_db_enabled && var.truefoundry_iam_role_enabled && var.iam_database_authentication_enabled ? 1 : 0
  statement {
    effect = "Allow"
    actions = [
      "rds-db:connect"
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:rds-db:${var.aws_region}:${var.aws_account_id}:dbuser:${aws_db_instance.truefoundry_db[0].id}/*"
    ]
  }
}

# we cannnot apply count here as module.truefoundry_oidc_iam requires fixed no of role_policy_arns
resource "aws_iam_policy" "truefoundry_db_iam_auth_policy" {
  count       = var.truefoundry_db_enabled && var.truefoundry_iam_role_enabled && var.iam_database_authentication_enabled ? 1 : 0
  name_prefix = "${local.truefoundry_iam_role_policy_prefix}-db-iam-auth-policy"
  description = "IAM based authentication policy for ${var.truefoundry_service_account} in cluster ${var.cluster_name}"
  policy      = data.aws_iam_policy_document.truefoundry_db_iam_auth_policy_document[0].json
  tags        = local.tags
}

data "aws_iam_policy_document" "truefoundry_db_monitoring_role_trust_policy_document" {
  count   = var.truefoundry_db_enabled && var.truefoundry_db_enable_monitoring && var.truefoundry_db_monitoring_role_arn == "" ? 1 : 0
  version = "2012-10-17"
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = [
        "monitoring.rds.amazonaws.com"
      ]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values = [
        var.aws_account_id
      ]
    }
  }
}

resource "aws_iam_role" "truefoundry_db_monitoring_role" {
  count = var.truefoundry_db_enabled && var.truefoundry_db_enable_monitoring && var.truefoundry_db_monitoring_role_arn == "" ? 1 : 0

  name_prefix        = "${substr(local.truefoundry_db_unique_name, 0, 25)}-monitoring-"
  description        = "IAM role for enhanced monitoring of RDS instance for ${var.cluster_name} cluster"
  assume_role_policy = data.aws_iam_policy_document.truefoundry_db_monitoring_role_trust_policy_document[0].json
  tags               = local.tags
}

resource "aws_iam_role_policy_attachment" "truefoundry_db_monitoring_role_policy_attachment" {
  count = var.truefoundry_db_enabled && var.truefoundry_db_enable_monitoring && var.truefoundry_db_monitoring_role_arn == "" ? 1 : 0

  role       = aws_iam_role.truefoundry_db_monitoring_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}
