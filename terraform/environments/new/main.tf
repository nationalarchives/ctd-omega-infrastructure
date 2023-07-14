###
# Terraform Script for an AWS Cloud for Omega
#
# Author: Adam Retter @ Evolved Binary
#         Jay Thomas @ DevOps Direct Tooling
###

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.65.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.0.4"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.4.0"
    }
  }

  required_version = ">= 1.3.9"
}

provider "aws" {
  profile = var.profile
  region  = var.region
}

resource "aws_s3_account_public_access_block" "tna-ct-omega" {
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}