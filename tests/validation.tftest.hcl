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

run "db_requires_ingress_security_group" {
  command = plan
  plan_options {
    refresh = false
  }

  variables {
    truefoundry_db_enabled                = true
    truefoundry_db_subnet_ids             = ["subnet-0123456789abcdef0"]
    truefoundry_db_ingress_security_group = ""
  }

  expect_failures = [
    var.truefoundry_db_ingress_security_group,
  ]
}

run "db_requires_subnet_ids" {
  command = plan
  plan_options {
    refresh = false
  }

  variables {
    truefoundry_db_enabled                = true
    truefoundry_db_subnet_ids             = []
    truefoundry_db_ingress_security_group = "sg-0123456789abcdef0"
  }

  expect_failures = [
    var.truefoundry_db_subnet_ids,
  ]
}

run "db_additional_sg_ids_must_be_valid" {
  command = plan
  plan_options {
    refresh = false
  }

  variables {
    truefoundry_db_enabled                       = true
    truefoundry_db_subnet_ids                    = ["subnet-0123456789abcdef0"]
    truefoundry_db_ingress_security_group        = "sg-0123456789abcdef0"
    truefoundry_db_additional_security_group_ids = ["not-a-security-group-id"]
  }

  expect_failures = [
    var.truefoundry_db_additional_security_group_ids,
  ]
}

run "db_monitoring_interval_validation" {
  command = plan
  plan_options {
    refresh = false
  }

  variables {
    truefoundry_db_monitoring_interval = 2
  }

  expect_failures = [
    var.truefoundry_db_monitoring_interval,
  ]
}

run "s3_override_name_max_length" {
  command = plan
  plan_options {
    refresh = false
  }

  variables {
    truefoundry_s3_enable_override = true
    truefoundry_s3_override_name   = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
  }

  expect_failures = [
    var.truefoundry_s3_override_name,
  ]
}

run "db_kms_key_requires_storage_encrypted" {
  command = plan
  plan_options {
    refresh = false
  }

  variables {
    truefoundry_db_kms_key_arn       = "arn:aws:kms:us-west-2:123456789012:key/11111111-1111-1111-1111-111111111111"
    truefoundry_db_storage_encrypted = false
  }

  expect_failures = [
    var.truefoundry_db_kms_key_arn,
  ]
}

run "db_override_name_max_length" {
  command = plan
  plan_options {
    refresh = false
  }

  variables {
    truefoundry_db_enable_override        = true
    truefoundry_db_override_name          = "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
    truefoundry_db_subnet_ids             = ["subnet-0123456789abcdef0"]
    truefoundry_db_ingress_security_group = "sg-0123456789abcdef0"
  }

  expect_failures = [
    var.truefoundry_db_override_name,
  ]
}
