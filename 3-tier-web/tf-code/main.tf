module "vpc" {
  source = "../modules/vpc"

  region = "us-east-1"

  organization = "kkoncloud.net"
  environment  = "dev"

  vpc_name      = "vpc-1"
  vpc_main_cidr = "10.75.0.0/16"
  public_subnet_cidr_map = {
    "us-east-1e" : {
      "subnet-1" : ["10.75.2.0/24", "internet-access"]
    }
    "us-east-1b" : {
      "subnet-1" : ["10.75.0.0/24", "internet-access"]
    }
    "us-east-1c" : {
      "subnet-1" : ["10.75.1.0/24", "internet-access"]
    }
  }
  private_subnet_cidr_map = {
    "us-east-1e" : {
      "subnet-1" : ["10.75.5.0/24", "web"]
      "subnet-2" : ["10.75.8.0/24", "app"]
      "subnet-3" : ["10.75.11.0/24", "db"]
    }
    "us-east-1b" : {
      "subnet-1" : ["10.75.3.0/24", "web"]
      "subnet-2" : ["10.75.6.0/24", "app"]
      "subnet-3" : ["10.75.9.0/24", "db"]
    }
    "us-east-1c": {
      "subnet-1" : ["10.75.4.0/24", "web"]
      "subnet-2" : ["10.75.7.0/24", "app"]
      "subnet-3" : ["10.75.10.0/24", "db"]
    }
  }
  default_tags = {
    environment  = "dev"
    organization = "kkoncloud.net"
  }
}
