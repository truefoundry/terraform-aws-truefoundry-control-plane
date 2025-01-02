# From https://github.com/terraform-aws-modules/terraform-aws-eks/blob/master/examples/irsa/irsa.tf

module "truefoundry_oidc_iam" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  count   = var.truefoundry_iam_role_enabled ? 1 : 0
  version = "5.39.1"

  create_role  = true
  role_name    = "${var.cluster_name}-truefoundry-deps"
  provider_url = replace(var.cluster_oidc_issuer_url, "https://", "")
  oidc_fully_qualified_subjects = [
    "system:serviceaccount:${var.svcfoundry_k8s_namespace}:${var.svcfoundry_k8s_service_account}",
    "system:serviceaccount:${var.mlfoundry_k8s_namespace}:${var.mlfoundry_k8s_service_account}",
    "system:serviceaccount:${var.tfy_workflow_admin_k8s_namespace}:${var.tfy_workflow_admin_k8s_service_account}",
    "system:serviceaccount:${var.truefoundry_k8s_namespace}:${var.truefoundry_service_account}",
  ]

  role_description = "Truefoundry IAM role for ${var.svcfoundry_k8s_service_account}, ${var.mlfoundry_k8s_service_account} and ${var.tfy_workflow_admin_k8s_service_account} in cluster ${var.cluster_name}"
  role_policy_arns = [
    aws_iam_policy.truefoundry_bucket_policy[0].arn,
    aws_iam_policy.svcfoundry_access_to_ssm[0].arn,
    aws_iam_policy.svcfoundry_access_to_multitenant_ssm[0].arn,
    aws_iam_policy.truefoundry_assume_role_all[0].arn,
    aws_iam_policy.svcfoundry_access_to_ecr[0].arn,
    aws_iam_policy.truefoundry_db_iam_auth_policy[0].arn,
    aws_iam_policy.svcfoundry_access_to_eks[0].arn
  ]
  tags = local.tags
}