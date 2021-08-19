###
# Terraform Script for an AWS Cloud for Omega
###

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.54.0"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  profile = "tna-ct-omega"
  region  = "eu-west-2"
}


# TODO(AR) IPv6 block
resource "aws_vpc" "tna_ct_omega_vpc" {
  cidr_block = "10.11.0.0/16"
  tags = {
	Name = "vpc"
  }
}

# TODO(AR) IPv6 subnet
resource "aws_subnet" "dev_subnet" {
  vpc_id     = aws_vpc.tna_ct_omega_vpc.id
  cidr_block = "10.11.10.0/24"

  tags = {
    Name = "subnet"
    Environment = "dev"
  }
}

# TODO(AR) IPv6 addresses
resource "aws_network_interface" "dev_workstation_1" {
  subnet_id   = aws_subnet.dev_subnet.id
  private_ips = ["10.11.10.11"]

  tags = {
    Name        = "primary_network_interface"
    Environment = "dev"
  }
}

# TODO(AR) - block devices?
# TODO(AR) - how about scheduled startup times each day?
# TODO(AR) - AWS firewall?
# TODO(AR) - separate interface for database access only?
# TODO(AR) - how to initiate Puppet?
resource "aws_instance" "dev_workstation_1" {
  ami           = "ami-0d26eb3972b7f8c96"
  instance_type = "m5a.2xlarge"

  network_interface {
    network_interface_id = aws_network_interface.dev_workstation_1.id
    device_index         = 0
  }

  tags = {
    Name        = "dev_workstation"
    Environment = "dev"
  }
}

# TODO(AR) - SQLServer VM - doesn't need as much power as dev VMs

