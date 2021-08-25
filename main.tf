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

# TODO(AR) is this still needed
#resource "aws_eip" "nat" {
#  count = 1
#  vpc   = true
#}


# TODO - Security Group for VPN -- should be SSH and RDP
# TODO - NACL (Network ACLs) Rules for VPN -- in from SSH/RDP -- out from ALL
# TODO - Certificate Manager - for VPN
#  --- Need a Root Chain cert
#  --- Need a Cert per User
#  --- AWS will provide OVPN files for users

resource "aws_acm_certificate" "vpn_server" {
  domain_name = "omega.nationalarchives.com"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "certificate"
    Scope = "vpn_server"
    Environment = "vpn"
  }
}

resource "aws_acm_certificate_validation" "vpn_server" {
  certificate_arn = aws_acm_certificate.vpn_server.arn
  timeouts {
    create = "1m"
  }
}

resource "aws_acm_certificate" "vpn_client_root" {
  #private_key = file("certs/client-vpn-ca.key")
  #certificate_body = file("certs/client-vpn-ca.crt")
  #certificate_chain = file("certs/ca-chain.crt")

  domain_name = "omega.nationalarchives.com"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "certificate"
    Scope = "vpn_client_root"
    Environment = "vpn"
  }
}

resource "aws_acm_certificate_validation" "vpn_client_root" {
  certificate_arn = aws_acm_certificate.vpn_client_root.arn
  timeouts {
    create = "1m"
  }
}

module "vpn_access_security_group" {
  source = "terraform-aws-modules/security-group/aws"
  version = "4.3.0"

  name        = "dev_workstation_security_group"
  description = "Security group for Development Workstation ports open within VPC"

  vpc_id = module.vpc.vpc_id

  computed_ingress_with_cidr_blocks = [
    {
      description = "Incoming VPN connection"
      from_port   = 443
      to_port     = 443
      protocol    = "udp"
      #cidr_blocks = "${module.vpc.private_subnets_cidr_blocks}"    # TODO(AR) why can't we use private subnet here?
      cidr_blocks = module.vpc.vpc_cidr_block
    }
  ]
  number_of_computed_ingress_with_cidr_blocks = 1

  computed_ingress_with_ipv6_cidr_blocks = [
    {
      description      = "Incoming VPN connection (IPv6)"
      from_port        = 443
      to_port          = 443
      protocol         = "udp"
      #ipv6_cidr_blocks = module.vpc.private_subnets_ipv6_cidr_blocks
      ipv6_cidr_blocks = module.vpc.vpc_ipv6_cidr_block
    }
  ]
  number_of_computed_ingress_with_ipv6_cidr_blocks = 1

  egress_with_cidr_blocks = [
    {
      description = "All"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  egress_with_ipv6_cidr_blocks = [
    {
      description = "All"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = "2001:db8::/64"
    }
  ]

  tags = {
    Name        = "security_group"
    Environment = "vpn"
  }
}

resource "aws_ec2_client_vpn_endpoint" "vpn" {
  description = "Omega Client VPN"
  
  client_cidr_block = "10.255.252.0/22"
  split_tunnel = true
  
  server_certificate_arn = aws_acm_certificate_validation.vpn_server.certificate_arn

  authentication_options {
    type = "certificate-authentication"
    root_certificate_chain_arn = aws_acm_certificate_validation.vpn_client_root.certificate_arn
  }

  connection_log_options {
    enabled = true
  }

  tags = {
    Name = "client_vpn_endpoint"
    Environment = "vpn"
  }
}

data "aws_subnet_ids" "vpc_subnet_ids" {
  vpc_id = module.vpc.vpc_id
}

resource "aws_ec2_client_vpn_network_association" "vpn_subnets" {
  count = 1

  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpn.id
  subnet_id = tolist(data.aws_subnet_ids.vpc_subnet_ids.ids)[count.index]  #TODO(AR) is this the private or internal subnet
  security_groups = [
    module.vpn_access_security_group.security_group_id
  ]

  lifecycle {
    // The issue why we are ignoring changes is that on every change
    // terraform screws up most of the vpn assosciations
    // see: https://github.com/hashicorp/terraform-provider-aws/issues/14717
    ignore_changes = [subnet_id]
  }
}

resource "aws_ec2_client_vpn_authorization_rule" "vpn_auth_rule" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpn.id
  # target_network_cidr = module.vpc.private_subnets_cidr_blocks  # TODO(AR) why can't we use private subnet here?
  target_network_cidr = module.vpc.vpc_cidr_block
  authorize_all_groups = true
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

  # TODO (AR) are these needed still
  #enable_nat_gateway  = true
  #single_nat_gateway  = false
  #reuse_nat_ips       = true             # <= Skip creation of EIPs for the NAT Gateways
  #external_nat_ip_ids = aws_eip.nat.*.id # <= IPs specified here as input to the module

  enable_dns_hostnames = true
  enable_dns_support = true

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
      protocol    = "-1"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  egress_with_ipv6_cidr_blocks = [
    {
      description = "All"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
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

  security_groups = [
      module.dev_workstation_secuirty_group.security_group_id
  ]

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

