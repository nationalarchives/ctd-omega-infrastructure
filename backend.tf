###
# Terraform backend configuration for holding Terraform state for an AWS Cloud for Omega
#
###

terraform {
  backend "s3" {
    bucket         = "tna-ct-omega-remote-state"
    dynamodb_table = "tna-ct-omega-remote-state-lock-table"
    encrypt        = true
    key            = "terraform/tna-ct-omega-remote-state/dev/terraform.tfstate"
    region         = "eu-west-2"
    profile        = "tna-ct-omega"
  }
}