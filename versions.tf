terraform {
  required_version = "~> 1.4"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.57"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}
