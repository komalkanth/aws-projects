terraform {
  required_version = "~> 1.13"

  required_providers {
    awscc = {
      source  = "hashicorp/awscc"
      version = "~> 1.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "6.25"
    }
  }

  backend "s3" {
    bucket  = "terraformstatebucketkk"
    key     = "cloudwan/vpc/terraform.tfstate"
    region  = "us-east-1"
    profile = "default"
    encrypt = true
  }
}

# Primary provider for us-east-1
provider "awscc" {
  region = "us-east-1"
}

# Secondary provider for us-east-2
provider "awscc" {
  alias  = "use2"
  region = "us-east-2"
}

# AWS provider for us-east-1 (for DynamoDB access)
provider "aws" {
  region = "us-east-1"
}

# Secondary AWS provider for us-east-2
provider "aws" {
  alias  = "use2"
  region = "us-east-2"
}
