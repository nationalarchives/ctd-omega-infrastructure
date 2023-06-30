###
# Terraform backend configuration for holding Terraform state for an AWS Cloud for Omega
# At present the state is just held in a separate private git repo which is a submodule of this repo called ctd-omega-infrastructure-terraform-state
###

terraform {
  backend "local" {
    path = "ctd-omega-infrastructure-terraform-state/terraform.tfstate"
  }
}
