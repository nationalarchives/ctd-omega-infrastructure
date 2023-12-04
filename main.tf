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
      version = "~> 5.22.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.0.4"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.4.0"
    }
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = "2.3.3"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.5.1"
    }
  }

  required_version = ">= 1.5.4"
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

resource "aws_key_pair" "omega_admin_key_pair" {
  key_name = "omega-admin-key-pair"

  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDgy946NcJxQGKhoMSpdKKxKwH1hqM4VOolTiYB+AssPV+8yJ8NTbAdxJhm0as6IIbJgVcrYpoZ98S+DKN1WZwJLBM+ahKbXhftvu+EIq7TQlUjreBimArbRK7VCSGnyLHfaMDgE7X+pXrfnrLwvYyp2vODPfl7p0wGsbPIAFNzmI2NyX2o/ozRJWtHwK29PGj0nqRs1TpfD9PUGEm4dqAMVllLwl/glu3/vS18QfNAda5q4wW3Gz+YBR1aefp9xj/RXaTFjUUAVcbiIkB32zstOTn95BLEYk4soLm2Wrr49aYcMoQWS4jqqegCNIM07RHxNrx9dti8CVhF82LeMxl3vUjS3BddmhxGTSuMio1QwTJWTTRuWGhwMZof2RG6YnZhmwl2iy9Ptk9jlwofU8TziP2A0zvllhMvtrr3sVk8QFQ3wmKxeM7PKCbmdVmOETXTCiJ5b33e5B7FoVYsuUxolJyN39tkLG8aBEgYGmowqxSsnJ0BcFIaX2jfoCRGLbs= admin@cat.nationalarchives.gov.uk"

  tags = {
    Name        = "key_pair"
    Network     = "all"
    Environment = "all"
  }

}

data "aws_key_pair" "omega_admin_key_pair" {
  key_name           = "omega-admin-key-pair"
  include_public_key = true

  filter {
    name   = "tag:Name"
    values = ["key_pair"]
  }
}
