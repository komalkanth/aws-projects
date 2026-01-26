# ============================================================================
# Terraform and Provider Configuration
# ============================================================================

terraform {
  required_version = "~> 1.13"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.25"
    }
  }

  backend "s3" {
    bucket  = "terraformstatebucketkk"
    key     = "cloudwan/cwan/terraform.tfstate"
    region  = "us-east-1"
    profile = "default"
  }
}

# Configure the AWS Provider with the "default" profile
provider "aws" {
  region  = "us-east-1"
  profile = "default"
}
