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

# Mirror the default provider for the aws.secondary alias declared via
# configuration_aliases in versions.tf. Aurora Global / VPC peering / failover
# resources are gated to count = 0 in these tests, so the credentials never run.
provider "aws" {
  alias                       = "secondary"
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

  truefoundry_db_engine_mode = "aurora"

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

run "aurora_cluster_replaces_rds_when_engine_mode_is_aurora" {
  command = plan
  plan_options {
    refresh = false
  }

  assert {
    condition     = length(aws_db_instance.truefoundry_db) == 0
    error_message = "aws_db_instance.truefoundry_db should not be created when engine_mode = aurora."
  }

  assert {
    condition     = length(aws_rds_cluster.truefoundry_aurora) == 1
    error_message = "Exactly one Aurora cluster should be created when engine_mode = aurora."
  }

  assert {
    condition     = aws_rds_cluster.truefoundry_aurora[0].engine == "aurora-postgresql"
    error_message = "Aurora cluster engine should be aurora-postgresql."
  }
}

run "aurora_instance_count_drives_cluster_instance_count" {
  command = plan
  plan_options {
    refresh = false
  }

  variables {
    truefoundry_aurora_instance_count = 3
  }

  assert {
    condition     = length(aws_rds_cluster_instance.truefoundry_aurora) == 3
    error_message = "Cluster instance count should match truefoundry_aurora_instance_count."
  }
}

run "aurora_parameter_group_family_matches_engine_major" {
  command = plan
  plan_options {
    refresh = false
  }

  variables {
    truefoundry_aurora_engine_version = "17.4"
  }

  assert {
    condition     = aws_rds_cluster_parameter_group.truefoundry_aurora_parameter_group[0].family == "aurora-postgresql17"
    error_message = "Aurora cluster parameter group family should track the engine major version."
  }
}

run "aurora_no_secret_kms_key_when_password_management_off" {
  command = plan
  plan_options {
    refresh = false
  }

  variables {
    manage_master_user_password = false
  }

  # The module's locals coalesce master_user_secret_kms_key_id to null when
  # password management is off; we assert the side effect (no KMS key created)
  # since the attribute itself is unknown until apply.
  assert {
    condition     = length(aws_kms_key.truefoundry_db_master_user_secret_kms_key) == 0
    error_message = "No master-user-secret KMS key should be created when manage_master_user_password = false."
  }

  assert {
    condition     = aws_rds_cluster.truefoundry_aurora[0].manage_master_user_password == null
    error_message = "manage_master_user_password should be null on the cluster when the input is false."
  }
}

run "aurora_module_creates_secret_kms_key_when_none_supplied" {
  command = plan
  plan_options {
    refresh = false
  }

  variables {
    manage_master_user_password = true
  }

  assert {
    condition     = length(aws_kms_key.truefoundry_db_master_user_secret_kms_key) == 1
    error_message = "Module should create its own master-user-secret KMS key for Aurora when none is supplied."
  }
}

# Regression test for Bugbot 329527b4-afc6-43f0-8189-5cbe14ea41ff:
# "Aurora ignores custom secret KMS". Aurora previously hardcoded
# aws_kms_key.truefoundry_db_master_user_secret_kms_key[0].arn, which doesn't
# exist when a customer ARN is supplied (count = 0). Now it must read through
# local.truefoundry_db_master_user_secret_kms_key_arn, matching RDS behavior.
run "aurora_supplied_secret_kms_key_skips_module_key" {
  command = plan
  plan_options {
    refresh = false
  }

  variables {
    manage_master_user_password                   = true
    truefoundry_db_master_user_secret_kms_key_arn = "arn:aws:kms:us-west-2:123456789012:key/22222222-2222-2222-2222-222222222222"
  }

  assert {
    condition     = length(aws_kms_key.truefoundry_db_master_user_secret_kms_key) == 0
    error_message = "Module should not create a master-user-secret KMS key when a customer key is supplied (Aurora)."
  }

  assert {
    condition     = aws_rds_cluster.truefoundry_aurora[0].master_user_secret_kms_key_id == "arn:aws:kms:us-west-2:123456789012:key/22222222-2222-2222-2222-222222222222"
    error_message = "Aurora cluster master_user_secret_kms_key_id should use the supplied customer KMS key ARN."
  }
}
