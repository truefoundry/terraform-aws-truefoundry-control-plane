data "aws_iam_policy_document" "svcfoundry_access_to_ecr" {
  statement {
    effect = "Allow"
    actions = [
      "ecr:GetRegistryPolicy",
      "ecr:DescribeImageScanFindings",
      "ecr:GetLifecyclePolicyPreview",
      "ecr:CreateRepository",
      "ecr:GetDownloadUrlForLayer",
      "ecr:DescribeImageReplicationStatus",
      "ecr:ListTagsForResource",
      "ecr:BatchGetRepositoryScanningConfiguration",
      "ecr:GetRegistryScanningConfiguration",
      "ecr:PutImage",
      "ecr:BatchGetImage",
      "ecr:DescribeRepositories",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetRepositoryPolicy",
      "ecr:GetLifecyclePolicy",
      "ecr:ListImages",
      "ecr:InitiateLayerUpload",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeImages",
      "ecr:DeleteRepository",
      "ecr:UploadLayerPart",
    ]

    resources = [
      "arn:aws:ecr:${var.aws_region}:${var.aws_account_id}:repository/tfy-*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "ecr:DescribeRegistry",
      "ecr:GetAuthorizationToken",
      "sts:GetServiceBearerToken"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "svcfoundry_access_to_ecr" {
  name_prefix = "${local.svcfoundry_unique_name}-access-to-ecr"
  description = "ECR access for ${var.svcfoundry_name} on ${var.cluster_name}"
  policy      = data.aws_iam_policy_document.svcfoundry_access_to_ecr.json
  tags        = local.tags
}