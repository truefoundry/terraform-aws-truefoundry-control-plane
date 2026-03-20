terraform {
  required_version = "~> 1.9"
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 6.33"
      configuration_aliases = [aws.secondary]
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}
