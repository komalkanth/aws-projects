module "vpc" {
  source = "../modules/vpc"

  region = "us-east-1"

  organization = "kkoncloud.net"
  environment  = "dev"

  vpc_name      = "vpc-1"
  vpc_main_cidr = "10.75.0.0/16"
  public_subnet_cidr_map = {
    "az1" : {
      "subnet-1" : ["10.75.2.0/24", "internet-access"]
    }
    "az2" : {
      "subnet-1" : ["10.75.0.0/24", "internet-access"]
    }
    "az3" : {
      "subnet-1" : ["10.75.1.0/24", "internet-access"]
    }
  }
  private_subnet_cidr_map = {
    "az1" : {
      "subnet-1" : ["10.75.5.0/24", "web"]
      "subnet-2" : ["10.75.8.0/24", "app"]
      "subnet-3" : ["10.75.11.0/24", "db"]
    }
    "az2" : {
      "subnet-1" : ["10.75.3.0/24", "web"]
      "subnet-2" : ["10.75.6.0/24", "app"]
      "subnet-3" : ["10.75.9.0/24", "db"]
    }
    "az3" : {
      "subnet-1" : ["10.75.4.0/24", "web"]
      "subnet-2" : ["10.75.7.0/24", "app"]
      "subnet-3" : ["10.75.10.0/24", "db"]
    }
  }
  natgw_enabled = {
    "az1" : true
    "az2" : true
    "az3" : true
  }
  region_short_name = "use1"
  default_tags = {
    environment  = var.environment
    organization = var.organization
  }
}
