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

run "db_defaults_engine_and_port" {
  command = plan
  plan_options {
    refresh = false
  }

  assert {
    condition     = aws_db_instance.truefoundry_db[0].engine == "postgres"
    error_message = "DB engine must remain postgres."
  }

  assert {
    condition     = aws_db_instance.truefoundry_db[0].port == 5432
    error_message = "DB port must remain 5432."
  }
}

run "db_identifier_uses_prefix_when_override_disabled" {
  command = plan
  plan_options {
    refresh = false
  }

  variables {
    truefoundry_db_enable_override = false
  }

  assert {
    condition     = aws_db_instance.truefoundry_db[0].identifier_prefix == "${var.cluster_name}-db"
    error_message = "identifier_prefix should follow the cluster_name-based default."
  }
}

run "db_identifier_uses_override_when_enabled" {
  command = plan
  plan_options {
    refresh = false
  }

  variables {
    truefoundry_db_enable_override = true
    truefoundry_db_override_name   = "custom-db-identifier"
  }

  assert {
    condition     = aws_db_instance.truefoundry_db[0].identifier == "custom-db-identifier"
    error_message = "identifier should match override name when override is enabled."
  }
}

run "public_sg_disabled_when_db_not_public" {
  command = plan
  plan_options {
    refresh = false
  }

  variables {
    truefoundry_db_publicly_accessible = "false"
  }

  assert {
    condition     = length(aws_security_group.rds-public) == 0
    error_message = "Public RDS security group should not be created when DB is not public."
  }
}

run "public_sg_enabled_when_db_public" {
  command = plan
  plan_options {
    refresh = false
  }

  variables {
    truefoundry_db_publicly_accessible = "true"
  }

  assert {
    condition     = length(aws_security_group.rds-public) == 1
    error_message = "Public RDS security group should be created when DB is publicly accessible."
  }
}

run "db_storage_type_defaults_to_gp3" {
  command = plan
  plan_options {
    refresh = false
  }

  assert {
    condition     = aws_db_instance.truefoundry_db[0].storage_type == "gp3"
    error_message = "DB storage type should default to gp3."
  }
}

run "postgres17_family_for_17x_engine" {
  command = plan
  plan_options {
    refresh = false
  }

  variables {
    truefoundry_db_engine_version = "17.5"
  }

  assert {
    condition     = aws_db_parameter_group.truefoundry_db_parameter_group[0].family == "postgres17"
    error_message = "DB parameter group family should be postgres17 for engine version 17.x."
  }
}

run "postgres13_family_for_13x_engine" {
  command = plan
  plan_options {
    refresh = false
  }

  variables {
    truefoundry_db_engine_version = "13.15"
  }

  assert {
    condition     = aws_db_parameter_group.truefoundry_db_parameter_group[0].family == "postgres13"
    error_message = "DB parameter group family should be postgres13 for engine version 13.x."
  }
}

run "storage_kms_key_used_when_set" {
  command = plan
  plan_options {
    refresh = false
  }

  variables {
    truefoundry_db_kms_key_arn = "arn:aws:kms:us-west-2:123456789012:key/11111111-1111-1111-1111-111111111111"
  }

  assert {
    condition     = aws_db_instance.truefoundry_db[0].kms_key_id == "arn:aws:kms:us-west-2:123456789012:key/11111111-1111-1111-1111-111111111111"
    error_message = "kms_key_id should match truefoundry_db_kms_key_arn when set."
  }
}

run "module_creates_secret_kms_key_when_none_supplied" {
  command = plan
  plan_options {
    refresh = false
  }

  variables {
    manage_master_user_password = true
  }

  assert {
    condition     = length(aws_kms_key.truefoundry_db_master_user_secret_kms_key) == 1
    error_message = "Module should create its own master-user-secret KMS key when none is supplied."
  }
}

run "supplied_secret_kms_key_skips_module_key" {
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
    error_message = "Module should not create a master-user-secret KMS key when a customer key is supplied."
  }

  assert {
    condition     = aws_db_instance.truefoundry_db[0].master_user_secret_kms_key_id == "arn:aws:kms:us-west-2:123456789012:key/22222222-2222-2222-2222-222222222222"
    error_message = "master_user_secret_kms_key_id should use the supplied customer KMS key ARN."
  }
}
