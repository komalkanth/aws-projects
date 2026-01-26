terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  profile    = var.aws_access_key_id == "" ? "default" : null
  region     = "us-east-1"
  access_key = var.aws_access_key_id != "" ? var.aws_access_key_id : null
  secret_key = var.aws_secret_access_key != "" ? var.aws_secret_access_key : null
}
