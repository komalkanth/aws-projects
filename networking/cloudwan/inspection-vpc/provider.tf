terraform {
  required_version = "~> 1.13"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.25"
    }
    awscc = {
      source  = "hashicorp/awscc"
      version = "~> 1.0"
    }
  }

  backend "s3" {
    bucket  = "terraformstatebucketkk"
    key     = "cloudwan/inspection-vpc/terraform.tfstate"
    region  = "us-east-1"
    profile = "default"
    encrypt = true
  }
}

provider "aws" {
  profile = "default"
  region  = var.vpc_region

  default_tags {
    tags = {
      Environment = "inspection"
      ManagedBy   = "Terraform"
      Project     = "CloudWAN"
    }
  }
}

provider "awscc" {
  profile = "default"
  region  = var.vpc_region
}
