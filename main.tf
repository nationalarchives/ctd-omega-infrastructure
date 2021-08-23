###
# Terraform Script for an AWS Cloud for Omega
###

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.55.0"
    }
  }

  required_version = ">= 0.14.9"
}

locals {
  aws_region = "eu-west-2"
  aws_azs = ["${local.aws_region}a"]
}

provider "aws" {
  profile = "tna-ct-omega"
  region  = local.aws_region
}

resource "aws_eip" "nat" {
  count = 1
  vpc   = true
}

resource "aws_customer_gateway" "tna_ct_omega_gateway" {
  bgp_asn    = 65000     # TODO(AR) need the ASN for TNA
  ip_address = "1.1.3.4" # TODO(AR) need a public IP for TNA
  type       = "ipsec.1"

  tags = {
    Name = "vpn-gateway"
  }
}

module "vpn_gateway" {
  source = "terraform-aws-modules/vpn-gateway/aws"
  version = "2.11.0"

  vpn_gateway_id      = module.vpc.vgw_id
  customer_gateway_id = aws_customer_gateway.tna_ct_omega_gateway.id

  vpc_id                       = module.vpc.vpc_id
  vpc_subnet_route_table_ids   = module.vpc.private_route_table_ids
  vpc_subnet_route_table_count = length(module.vpc.private_subnets)
  local_ipv4_network_cidr      = "0.0.0.0/0"
  remote_ipv4_network_cidr     = module.vpc.vpc_cidr_block # TODO(AR) should we restrict to just private subnet?
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "3.6.0"

  name = "tna_ct_omega_vpc"

  cidr = "10.128.238.0/24"

  azs = local.aws_azs

  private_subnets = ["10.128.238.0/29"]   # dev_private_subnet
  intra_subnets   = ["10.128.238.248/29"] # dev_internal_subnet

  enable_ipv6                     = true
  assign_ipv6_address_on_creation = true
  private_subnet_ipv6_prefixes    = [0]
  intra_subnet_ipv6_prefixes      = [16]

  enable_nat_gateway  = true
  single_nat_gateway  = false
  reuse_nat_ips       = true             # <= Skip creation of EIPs for the NAT Gateways
  external_nat_ip_ids = aws_eip.nat.*.id # <= IPs specified here as input to the module

  enable_vpn_gateway = true

  tags = {
    Name = "vpc"
  }
}

data "aws_ami" "amazon_linux_2" {

  # Likely to be AMI with id: ami-0d26eb3972b7f8c96

  most_recent = true

  owners = ["137112412989"] # Amazon Web Services

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

module "dev_workstation_secuirty_group" {
  source = "terraform-aws-modules/security-group/aws"
  version = "4.3.0"

  name        = "dev_workstation_security_group"
  description = "Security group for Development Workstation ports open within VPC"

  vpc_id = module.vpc.vpc_id

  computed_ingress_with_cidr_blocks = [
    {
      description = "SSH"
      from_port   = 0
      to_port     = 22
      protocol    = "tcp"
      #cidr_blocks = "${module.vpc.private_subnets_cidr_blocks}"    # TODO(AR) why can't we use private subnet here?
      cidr_blocks = module.vpc.vpc_cidr_block
    },
    {
      description = "RDP"
      from_port   = 0
      to_port     = 3389
      protocol    = "tcp"
      #cidr_blocks = "${module.vpc.private_subnets_cidr_blocks}"   # TODO(AR) why can't we use private subnet here?
      cidr_blocks = module.vpc.vpc_cidr_block
    }
  ]
  number_of_computed_ingress_with_cidr_blocks = 1

  computed_ingress_with_ipv6_cidr_blocks = [
    {
      description      = "SSH (IPv6)"
      from_port        = 0
      to_port          = 22
      protocol         = "tcp"
      #ipv6_cidr_blocks = module.vpc.private_subnets_ipv6_cidr_blocks
      ipv6_cidr_blocks = module.vpc.vpc_ipv6_cidr_block
    },
    {
      description = "RDP (IPv6)"
      from_port   = 0
      to_port     = 3389
      protocol    = "tcp"
      #ipv6_cidr_blocks = module.vpc.private_subnets_ipv6_cidr_blocks # TODO(AR) why can't we use private subnet here?
      ipv6_cidr_blocks = module.vpc.vpc_ipv6_cidr_block # TODO(AR) why can't we use private subnet here?
    }
  ]
  number_of_computed_ingress_with_ipv6_cidr_blocks = 1

  egress_with_cidr_blocks = [
    {
      description = "All"
      from_port   = 0
      to_port     = 0
      protocol    = 0
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  egress_with_ipv6_cidr_blocks = [
    {
      description = "All"
      from_port   = 0
      to_port     = 0
      protocol    = 0
      cidr_blocks = "2001:db8::/64"
    }
  ]

  tags = {
    Name        = "security_group"
    Environment = "dev"
  }
}

resource "aws_network_interface" "dev_workstation_1_private_interface" {
  description        = "Private Subnet Interface for Dev Workstation 1"
  subnet_id          = module.vpc.private_subnets[0]
  private_ips        = ["10.128.238.0"]
  ipv6_address_count = 0 # use assign_ipv6_address_on_creation=true from the vpc subnet configuration

  tags = {
    Name        = "primary_network_interface"
    Network     = "private"
    Environment = "dev"
  }
}

resource "aws_network_interface" "dev_workstation_1_internal_interface" {
  description        = "Internal Subnet Interface for Dev Workstation 1"
  subnet_id          = module.vpc.intra_subnets[0]
  private_ips        = ["10.128.238.248"]
  ipv6_address_count = 0 # use assign_ipv6_address_on_creation=true from the vpc subnet configuration

  tags = {
    Name        = "secondary_network_interface"
    Network     = "internal"
    Environment = "dev"
  }
}

resource "aws_instance" "dev_workstation_1" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = "m5a.2xlarge"

  monitoring = false

  network_interface {
    network_interface_id = aws_network_interface.dev_workstation_1_private_interface.id
    device_index         = 0
  }

  network_interface {
    network_interface_id = aws_network_interface.dev_workstation_1_internal_interface.id
    device_index         = 1
  }

  root_block_device {
    delete_on_termination = false
    encrypted             = false
    volume_type           = "gp3"
    iops                  = 3000
    throughput            = 120 # 120 MiB/s == ~125 MBps
    volume_size           = 500 # GiB

    tags = {
      Name        = "primary_volume"
      Environment = "dev"
    }
  }

  security_groups = [
    "dev_workstation_secuirty_group"
  ]

  tags = {
    Name        = "dev_workstation"
    Environment = "dev"
  }
}

resource "aws_network_interface" "dev_mssql_server_1_internal_interface" {
  description        = "Internal Subnet Interface for Dev MS SQL Server 1"
  subnet_id          = module.vpc.intra_subnets[0]
  private_ips        = ["10.128.238.255"]
  ipv6_address_count = 0 # use assign_ipv6_address_on_creation=true from the vpc subnet configuration

  tags = {
    Name        = "primary_network_interface"
    Network     = "internal"
    Environment = "dev"
  }
}

resource "aws_instance" "mssql_server_1" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = "r5.xlarge"
  # m5a.2xlarge == $0.4 / hour == 8 vCPU == 32GiB RAM
  # r5.xlarge == $0.296 / hour == 4 vCPU == 32GiB RAM

  monitoring = true

  network_interface {
    network_interface_id = aws_network_interface.dev_mssql_server_1_internal_interface.id
    device_index         = 0
  }

  root_block_device {
    delete_on_termination = false
    encrypted             = false
    volume_type           = "gp3"
    iops                  = 3000
    throughput            = 120 # 120 MiB/s == ~125 MBps
    volume_size           = 60  # GiB

    tags = {
      Name        = "primary_volume"
      Environment = "dev"
    }
  }

  ebs_block_device {
    device_name           = "xvdb"
    delete_on_termination = false
    encrypted             = false
    volume_type           = "gp3" # TODO(AR) consider upgrading to io2 and/or more IOPS
    iops                  = 3000
    throughput            = 120 # 120 MiB/s == ~125 MBps
    volume_size           = 150 # GiB

    tags = {
      Name        = "mssql_data_volume"
      Environment = "dev"
    }
  }

  ebs_block_device {
    device_name           = "xvdc"
    delete_on_termination = false
    encrypted             = false
    volume_type           = "gp3" # TODO(AR) consider upgrading to io2 and/or more IOPS
    iops                  = 3000
    throughput            = 120 # 120 MiB/s == ~125 MBps
    volume_size           = 75  # GiB

    tags = {
      Name        = "mssql_log_volume"
      Environment = "dev"
    }
  }

  ebs_block_device {
    device_name           = "xvdd"
    delete_on_termination = false
    encrypted             = false
    volume_type           = "gp3" # TODO(AR) consider upgrading to io2 and/or more IOPS
    iops                  = 3000
    throughput            = 120 # 120 MiB/s == ~125 MBps
    volume_size           = 150 # GiB

    tags = {
      Name        = "mssql_backup_volume"
      Environment = "dev"
    }
  }

  tags = {
    Name        = "dev_mssql_server"
    Environment = "dev"
  }
}


# TODO(AR) - how about scheduled startup times each day? -- AWS Instance Scheduler -- https://registry.terraform.io/modules/diodonfrost/lambda-scheduler-stop-start/aws/latest

# TODO(AR) - how to initiate Puppet?

