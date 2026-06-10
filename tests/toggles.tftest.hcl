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

run "db_disabled_disables_resources_and_outputs" {
  command = plan
  plan_options {
    refresh = false
  }

  variables {
    truefoundry_db_enabled = false
  }

  assert {
    condition     = length(aws_db_instance.truefoundry_db) == 0
    error_message = "DB instance should not be created when truefoundry_db_enabled is false."
  }

  assert {
    condition     = output.truefoundry_db_endpoint == ""
    error_message = "DB endpoint output should be empty when DB is disabled."
  }

  assert {
    condition     = output.truefoundry_db_id == ""
    error_message = "DB id output should be empty when DB is disabled."
  }
}

run "s3_disabled_disables_bucket_and_policy" {
  command = plan
  plan_options {
    refresh = false
  }

  variables {
    truefoundry_s3_enabled = false
  }

  assert {
    condition     = length(module.truefoundry_bucket) == 0
    error_message = "S3 module should not be created when truefoundry_s3_enabled is false."
  }

  assert {
    condition     = output.truefoundry_bucket_id == ""
    error_message = "Bucket output should be empty when bucket creation is disabled."
  }

  assert {
    condition     = length(aws_iam_policy.truefoundry_bucket_policy) == 0
    error_message = "Bucket access policy should not be created when S3 is disabled."
  }
}

run "iam_role_disabled_disables_iam_role_and_policies" {
  command = plan
  plan_options {
    refresh = false
  }

  variables {
    truefoundry_iam_role_enabled = false
  }

  assert {
    condition     = length(module.truefoundry_oidc_iam) == 0
    error_message = "OIDC IAM role module should be disabled."
  }

  assert {
    condition     = output.truefoundry_iam_role_arn == ""
    error_message = "IAM role output should be empty when IAM role creation is disabled."
  }

  assert {
    condition     = length(aws_iam_policy.svcfoundry_access_to_ecr) == 0
    error_message = "Role-scoped IAM policies should not be created when IAM role is disabled."
  }
}

run "manage_master_user_password_enables_kms_and_disables_random_password" {
  command = plan
  plan_options {
    refresh = false
  }

  variables {
    manage_master_user_password = true
  }

  assert {
    condition     = length(random_password.truefoundry_db_password) == 0
    error_message = "Random password should not be created when RDS manages the master password."
  }

  assert {
    condition     = length(aws_kms_key.truefoundry_db_master_user_secret_kms_key) == 1
    error_message = "KMS key should be created when RDS manages the master password."
  }

  assert {
    condition     = aws_db_instance.truefoundry_db[0].manage_master_user_password == true
    error_message = "DB instance should have manage_master_user_password enabled."
  }
}

run "db_monitoring_without_external_role_creates_monitoring_role" {
  command = plan
  plan_options {
    refresh = false
  }

  variables {
    truefoundry_db_enable_monitoring   = true
    truefoundry_db_monitoring_role_arn = ""
  }

  assert {
    condition     = length(aws_iam_role.truefoundry_db_monitoring_role) == 1
    error_message = "Monitoring role should be created when monitoring is enabled without an external role ARN."
  }

  assert {
    condition     = aws_db_instance.truefoundry_db[0].monitoring_interval == var.truefoundry_db_monitoring_interval
    error_message = "DB monitoring interval should match configured variable."
  }
}

run "db_monitoring_with_external_role_skips_monitoring_role_creation" {
  command = plan
  plan_options {
    refresh = false
  }

  variables {
    truefoundry_db_enable_monitoring   = true
    truefoundry_db_monitoring_role_arn = "arn:aws:iam::123456789012:role/existing-rds-monitoring-role"
  }

  assert {
    condition     = length(aws_iam_role.truefoundry_db_monitoring_role) == 0
    error_message = "Monitoring role should not be created when an external role ARN is provided."
  }

  assert {
    condition     = aws_db_instance.truefoundry_db[0].monitoring_role_arn == var.truefoundry_db_monitoring_role_arn
    error_message = "DB monitoring role ARN should use the externally provided role."
  }
}

run "s3_cors_toggle_off_with_s3_disabled_is_plan_safe" {
  command = plan
  plan_options {
    refresh = false
  }

  variables {
    truefoundry_s3_enabled            = false
    truefoundry_s3_attach_cors_policy = false
    truefoundry_s3_cors_origins       = ["https://app.example.com"]
  }

  assert {
    condition     = output.truefoundry_bucket_id == ""
    error_message = "Bucket output should remain empty when S3 is disabled with CORS attachment disabled."
  }

  assert {
    condition     = length(aws_iam_policy.truefoundry_bucket_policy) == 0
    error_message = "Bucket access policy should remain disabled when S3 is disabled."
  }
}
