
terraform {
  backend "s3" {
    bucket   = "devops-terraform-state-az"
    key      = "devops-test-server"
    region   = "us-east-1"
    #role_arn = "arn:aws:iam::836125810747:role/infrastructure-role"
  }
}
