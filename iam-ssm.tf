resource "aws_iam_policy" "svcfoundry_access_to_ssm" {
  name_prefix = "${local.svcfoundry_unique_name}-access-to-ssm"
  description = "SSM read access for ${var.svcfoundry_name} on ${var.cluster_name}"
  policy      = data.aws_iam_policy_document.svcfoundry_access_to_ssm.json
}

data "aws_iam_policy_document" "svcfoundry_access_to_ssm" {
  statement {
    effect = "Allow"
    actions = [
      "ssm:DescribeParameters"
    ]
    resources = ["*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "ssm:GetParameterHistory",
      "ssm:GetParametersByPath",
      "ssm:GetParameters",
      "ssm:GetParameter",
    ]
    resources = [
      "arn:aws:ssm:${var.aws_region}:${var.aws_account_id}:parameter/${var.account_name}/${var.svcfoundry_name}/*",
      "arn:aws:ssm:${var.aws_region}:${var.aws_account_id}:parameter/${var.account_name}/${aws_db_instance.truefoundry_db.id}/*",
      "arn:aws:ssm:${var.aws_region}:${var.aws_account_id}:parameter/${var.account_name}/truefoundry/dockerhub/IMAGE_PULL_CREDENTIALS",
    ]
  }
}

resource "aws_iam_policy" "svcfoundry_access_to_multitenant_ssm" {
  name_prefix = "${local.svcfoundry_unique_name}-access-to-multitenant-ssm"
  description = "SSM read access for ${var.svcfoundry_name} to all multitenant params on ${var.cluster_name}"
  policy      = data.aws_iam_policy_document.svcfoundry_access_to_multitenant_ssm.json
}

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