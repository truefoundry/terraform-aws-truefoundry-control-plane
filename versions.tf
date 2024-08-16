terraform {
  required_version = ">= 1.8"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.63.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.6.2"
    }
  }
}