# policy for IAM based authentication to RDS
data "aws_iam_policy_document" "truefoundry_db_iam_auth_policy_document" {
  statement {
    effect = "Allow"
    actions = [
      "rds-db:connect"
    ]
    resources = [
      "arn:aws:rds-db:${var.aws_region}:${var.aws_account_id}:dbuser:${aws_db_instance.truefoundry_db[0].id}/*"
    ]
  }
}

# we cannnot apply count here as module.truefoundry_oidc_iam requires fixed no of role_policy_arns
resource "aws_iam_policy" "truefoundry_db_iam_auth_policy" {
  count       = var.truefoundry_iam_role_enabled ? 1 : 0
  name_prefix = "${local.svcfoundry_unique_name}-db-iam-auth-policy"
  description = "IAM based authentication policy for ${var.svcfoundry_name} and ${var.mlfoundry_name} in cluster ${var.cluster_name}"
  policy      = data.aws_iam_policy_document.truefoundry_db_iam_auth_policy_document.json
  tags        = local.tags
}