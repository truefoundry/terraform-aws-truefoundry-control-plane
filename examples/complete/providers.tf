terraform {
  required_version = ">= 1.9"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.33"
    }
  }
}

provider "aws" {
  region  = var.primary_region
  profile = var.aws_profile
}

provider "aws" {
  alias   = "secondary"
  region  = var.dr_region
  profile = var.aws_profile
}
