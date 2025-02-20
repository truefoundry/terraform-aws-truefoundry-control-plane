data "aws_iam_policy_document" "svcfoundry_access_to_multitenant_ssm" {
  statement {
    effect = "Allow"
    actions = [
      "ssm:GetParameterHistory",
      "ssm:GetParametersByPath",
      "ssm:GetParameters",
      "ssm:GetParameter",
      "ssm:PutParameter",
      "ssm:DeleteParameter",
      "ssm:DeleteParameters",
    ]
    resources = [
      "arn:aws:ssm:${var.aws_region}:${var.aws_account_id}:parameter/tfy-secret/*"
    ]
  }
}

resource "aws_iam_policy" "svcfoundry_access_to_multitenant_ssm" {
  count       = var.truefoundry_iam_role_enabled ? 1 : 0
  name_prefix = "${local.svcfoundry_unique_name}-access-to-multitenant-ssm"
  description = "SSM read access for ${var.svcfoundry_k8s_service_account} to all multitenant params on ${var.cluster_name}"
  policy      = data.aws_iam_policy_document.svcfoundry_access_to_multitenant_ssm.json
  tags        = local.tags
}

# allow servicefoundry to assume any role to support Assume role feature
data "aws_iam_policy_document" "truefoundry_assume_role_all" {
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
    ]
    resources = [
      "*"
    ]
  }
}

resource "aws_iam_policy" "truefoundry_assume_role_all" {
  count       = var.truefoundry_iam_role_enabled ? 1 : 0
  name_prefix = "${local.svcfoundry_unique_name}-truefoundry-allow-assume-role-all"
  description = "Allow access to assume role for ${local.svcfoundry_unique_name} and ${local.mlfoundry_unique_name} in ${var.cluster_name}"
  policy      = data.aws_iam_policy_document.truefoundry_assume_role_all.json
  tags        = local.tags
}
