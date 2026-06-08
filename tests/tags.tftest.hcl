mock_provider "aws" {
  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  mock_data "aws_partition" {
    defaults = {
      partition = "aws"
    }
  }
}

mock_provider "random" {}

run "tags_applied" {
  command = plan

  variables {
    cluster_name            = "test-cluster"
    cluster_oidc_issuer_url = "https://oidc.eks.us-east-1.amazonaws.com/id/EXAMPLE"
    aws_region              = "us-east-1"
    aws_account_id          = "123456789012"
    vpc_id                  = "vpc-0123456789abcdef0"

    truefoundry_db_enabled                = true
    truefoundry_db_ingress_security_group = "sg-0123456789abcdef0"
    truefoundry_db_subnet_ids             = ["subnet-0123456789abcdef0", "subnet-0fedcba9876543210"]

    # Disable the IAM role module to avoid child-module ARN validation with mocked values
    truefoundry_iam_role_enabled = false

    tags = {
      "cost-center" = "test-123"
    }
  }

  assert {
    condition     = aws_db_instance.truefoundry_db[0].tags["cost-center"] == "test-123"
    error_message = "aws_db_instance is missing caller tag cost-center=test-123"
  }

  assert {
    condition     = aws_db_instance.truefoundry_db[0].tags["terraform-module"] == "control-plane"
    error_message = "aws_db_instance has wrong terraform-module tag (expected control-plane)"
  }

  assert {
    condition     = aws_db_parameter_group.truefoundry_db_parameter_group[0].tags["cost-center"] == "test-123"
    error_message = "aws_db_parameter_group is missing caller tag cost-center=test-123"
  }

  assert {
    condition     = aws_db_parameter_group.truefoundry_db_parameter_group[0].tags["terraform-module"] == "control-plane"
    error_message = "aws_db_parameter_group has wrong terraform-module tag (expected control-plane)"
  }
}
