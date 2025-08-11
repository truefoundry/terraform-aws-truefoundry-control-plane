data "aws_iam_policy_document" "svcfoundry_access_to_eks" {
  statement {
    effect = "Allow"
    actions = [
      "eks:ListNodegroups",
      "eks:DescribeFargateProfile",
      "eks:ListTagsForResource",
      "eks:DescribeInsight",
      "eks:ListAddons",
      "eks:DescribeAddon",
      "eks:DescribePodIdentityAssociation",
      "eks:ListInsights",
      "eks:ListPodIdentityAssociations",
      "eks:ListFargateProfiles",
      "eks:DescribeNodegroup",
      "eks:ListUpdates",
      "eks:DescribeUpdate",
      "eks:AccessKubernetesApi",
      "eks:DescribeCluster",
    ]

    resources = [
      "arn:${data.aws_partition.current.partition}:eks:${var.aws_region}:${var.aws_account_id}:fargateprofile/${var.cluster_name}/*/*",
      "arn:${data.aws_partition.current.partition}:eks:${var.aws_region}:${var.aws_account_id}:addon/${var.cluster_name}/*/*",
      "arn:${data.aws_partition.current.partition}:eks:${var.aws_region}:${var.aws_account_id}:nodegroup/${var.cluster_name}/*/*",
      "arn:${data.aws_partition.current.partition}:eks:${var.aws_region}:${var.aws_account_id}:podidentityassociation/${var.cluster_name}/*",
      "arn:${data.aws_partition.current.partition}:eks:${var.aws_region}:${var.aws_account_id}:identityproviderconfig/${var.cluster_name}/*/*/*",
      "arn:${data.aws_partition.current.partition}:eks:${var.aws_region}:${var.aws_account_id}:cluster/${var.cluster_name}"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "eks:DescribeAddonConfiguration",
      "eks:ListClusters",
      "eks:DescribeAddonVersions",
      "ec2:DescribeRegions"
    ]

    resources = [
      "*"
    ]
  }
}

resource "aws_iam_policy" "svcfoundry_access_to_eks" {
  count       = var.truefoundry_iam_role_enabled ? 1 : 0
  name_prefix = "${local.truefoundry_iam_role_policy_prefix}-access-to-eks"
  description = "EKS read access for ${var.truefoundry_service_account} on ${var.cluster_name}"
  policy      = data.aws_iam_policy_document.svcfoundry_access_to_eks.json
  tags        = local.tags
}