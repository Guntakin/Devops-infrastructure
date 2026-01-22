#------------------------------------------#
# VPC Remote State
#------------------------------------------#

module "env_vpc" {
  source           = "../../../terraform-modules/vpc"
  azs              = ["b", "c", "a"]
  cidr             = "10.50.0.0/20"
  environment-name = "DevOps-test"
}

locals {
  azs = ["a", "b", "c"]
}
