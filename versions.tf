terraform {
  required_version = ">= 1.4"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.32.1"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.5.1"
    }
  }
}