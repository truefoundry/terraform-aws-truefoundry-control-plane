terraform {
  required_version = ">= 1.4"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.44.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.5.1"
    }
  }
}