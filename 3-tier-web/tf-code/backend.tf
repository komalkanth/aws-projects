terraform {
  backend "s3" {
    profile     = "iamadmin-networking"
    bucket       = "networking-tfstates"
    key          = "dev_kkoncloud/terraform.tfstate"
    region       = "us-east-1"
    # encrypt      = true
    use_lockfile = true
  }
}