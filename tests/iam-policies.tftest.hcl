provider "aws" {
  region                      = var.aws_region
  access_key                  = "test-access-key"
  secret_key                  = "test-secret-key"
  token                       = "test-session-token"
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_region_validation      = true
  skip_metadata_api_check     = true
}

variables {
  cluster_name            = "tfy-test-cluster"
  cluster_oidc_issuer_url = "https://oidc.eks.us-west-2.amazonaws.com/id/EXAMPLED539D4633E53DE1B716D3041E"
  aws_region              = "us-west-2"
  aws_account_id          = "123456789012"
  vpc_id                  = "vpc-0123456789abcdef0"

  truefoundry_db_ingress_security_group = "sg-0123456789abcdef0"
  truefoundry_db_subnet_ids = [
    "subnet-0123456789abcdef0",
    "subnet-0fedcba9876543210",
  ]

  # Disable external modules by default for offline tests.
  truefoundry_s3_enabled       = false
  truefoundry_iam_role_enabled = false
}

override_module {
  target = module.truefoundry_bucket
  outputs = {
    s3_bucket_id = "mocked-bucket-id"
  }
}

override_module {
  target = module.truefoundry_oidc_iam
  outputs = {
    iam_role_arn  = "arn:aws:iam::123456789012:role/mocked-role"
    iam_role_name = "mocked-role"
  }
}

run "iam_policies_use_expected_scopes" {
  command = plan
  plan_options {
    refresh = false
  }

  assert {
    condition     = strcontains(data.aws_iam_policy_document.svcfoundry_access_to_multitenant_ssm.json, "parameter/tfy-secret/*")
    error_message = "SSM policy should scope access to parameter/tfy-secret/*."
  }

  assert {
    condition     = strcontains(data.aws_iam_policy_document.svcfoundry_access_to_ecr.json, "repository/tfy-*")
    error_message = "ECR policy should scope repository access to tfy-*."
  }

  assert {
    condition     = strcontains(data.aws_iam_policy_document.svcfoundry_access_to_eks.json, "cluster/${var.cluster_name}")
    error_message = "EKS policy should include cluster-scoped ARN references."
  }

  assert {
    condition     = strcontains(data.aws_iam_policy_document.svcfoundry_access_to_eks.json, ":eks:${var.aws_region}:${var.aws_account_id}:")
    error_message = "EKS policy should be rendered with provided region and account ID."
  }

  assert {
    condition     = strcontains(data.aws_iam_policy_document.truefoundry_bucket_policy.json, "s3:::${var.cluster_name}-truefoundry")
    error_message = "Bucket policy should include the default truefoundry bucket naming prefix."
  }
}

run "rds_iam_auth_policy_only_exists_when_enabled" {
  command = plan
  plan_options {
    refresh = false
  }

  variables {
    iam_database_authentication_enabled = false
  }

  assert {
    condition     = length(aws_iam_policy.truefoundry_db_iam_auth_policy) == 0
    error_message = "RDS IAM auth policy should not be created when iam_database_authentication_enabled is false."
  }
}

run "rds_iam_auth_policy_remains_disabled_without_iam_role" {
  command = plan
  plan_options {
    refresh = false
  }

  variables {
    iam_database_authentication_enabled = true
    truefoundry_iam_role_enabled        = false
  }

  assert {
    condition     = length(aws_iam_policy.truefoundry_db_iam_auth_policy) == 0
    error_message = "RDS IAM auth policy should remain disabled when IAM role creation is disabled."
  }

  assert {
    condition     = length(data.aws_iam_policy_document.truefoundry_db_iam_auth_policy_document) == 0
    error_message = "RDS IAM auth policy document data source should be disabled when IAM role creation is disabled."
  }
}
