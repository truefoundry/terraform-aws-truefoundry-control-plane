# From https://github.com/terraform-aws-modules/terraform-aws-eks/blob/master/examples/irsa/irsa.tf

module "mlfoundry_oidc_iam" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "5.27.0"

  create_role  = true
  role_name    = "${var.cluster_name}-mlfoundry-deps"
  provider_url = replace(var.cluster_oidc_issuer_url, "https://", "")
  oidc_fully_qualified_subjects = [
    "system:serviceaccount:${var.mlfoundry_k8s_namespace}:${var.mlfoundry_k8s_service_account}"
  ]

  role_policy_arns = [
    aws_iam_policy.truefoundry_bucket_policy.arn
  ]
  tags = local.tags
}



data "aws_iam_policy" "servicefoundry_ecr_policy" {
  name = "AmazonEC2ContainerRegistryFullAccess"
}

module "svcfoundry_oidc_iam" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "5.27.0"

  create_role  = true
  role_name    = "${var.cluster_name}-svcfoundry-deps"
  provider_url = replace(var.cluster_oidc_issuer_url, "https://", "")
  oidc_fully_qualified_subjects = [
    "system:serviceaccount:${var.svcfoundry_k8s_namespace}:${var.svcfoundry_k8s_service_account}"
  ]

  role_policy_arns = [
    aws_iam_policy.truefoundry_bucket_policy.arn,
    aws_iam_policy.svcfoundry_access_to_ssm.arn,
    aws_iam_policy.svcfoundry_access_to_multitenant_ssm.arn,
    data.aws_iam_policy.servicefoundry_ecr_policy.arn
  ]
  tags = local.tags
}
