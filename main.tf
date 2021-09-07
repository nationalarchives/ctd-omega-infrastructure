###
# Terraform Script for an AWS Cloud for Omega
###

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.57.0"
    }
  }

  required_version = ">= 0.14.9"
}

locals {
  aws_region = "eu-west-2"
  aws_azs = ["${local.aws_region}a"]


  public_dns_domain = "cat.nationalarchives.gov.uk"
  private_dns_domain = "in.cat.nationalarchives.gov.uk"

  vpn_client_cidr_block = "10.255.252.0/22"

  vpc_cidr_block = "10.128.238.0/24"

  /* Private Subnet for General Development */
  vpc_private_subnet_dev_general = "10.128.238.0/27"
  vpc_private_subnet_dev_general_ipv6_prefixes = 0

  /* Private Subnet for databases used in Development */
  vpc_private_subnet_dev_databases = "10.128.238.96/27"
  vpc_private_subnet_dev_databases_ipv6_prefixes = 16

  /* Public Subnet for Development */
  vpc_public_subnet_dev = "10.128.238.224/27"
  vpc_public_subnet_dev_ipv6_prefixes = 128
}

provider "aws" {
  profile = "tna-ct-omega"
  region  = local.aws_region
}

data "aws_partition" "current" {}

resource "aws_eip" "vpc_subnet_nats" {
  count = 2  # NOTE: must match the number of private subnets in the VPC!
  vpc   = true
}

resource "aws_route53_zone" "omega_public_dns" {
  name = local.public_dns_domain

  tags = {
    name = "dns_zone"
  }
}

resource "aws_route53_record" "omega_public_dns_nameservers" {
  allow_overwrite = true
  name = local.public_dns_domain
  ttl             = 86400      # 24 Hours
  type            = "NS"
  zone_id         = aws_route53_zone.omega_public_dns.zone_id
  records = aws_route53_zone.omega_public_dns.name_servers
}

output "omega_public_dns_servers" {
  description = "Public DNS Servers for Omega"
  value = aws_route53_zone.omega_public_dns.name_servers
}

resource "aws_acmpca_certificate_authority_certificate" "omega_ca_certificate_association" {
  certificate_authority_arn = aws_acmpca_certificate_authority.omega_ca.arn

  certificate       = aws_acmpca_certificate.omega_ca_certificate.certificate
  certificate_chain = aws_acmpca_certificate.omega_ca_certificate.certificate_chain
}

resource "aws_acmpca_certificate" "omega_ca_certificate" {
  certificate_authority_arn   = aws_acmpca_certificate_authority.omega_ca.arn
  certificate_signing_request = aws_acmpca_certificate_authority.omega_ca.certificate_signing_request
  signing_algorithm           = "SHA512WITHRSA"

  template_arn = "arn:${data.aws_partition.current.partition}:acm-pca:::template/RootCACertificate/V1"

  validity {
    type  = "YEARS"
    value = 3
  }
}

resource "aws_acmpca_certificate_authority" "omega_ca" {
  type = "ROOT"

  certificate_authority_configuration {
    key_algorithm     = "RSA_4096"
    signing_algorithm = "SHA512WITHRSA"

    subject {
      common_name = local.public_dns_domain
      organizational_unit = "Project Omega"
      organization = "The National Archives"
      locality = "Kew"
      state = "Surrey"
      country = "GB"
    }
  }

  tags = {
      Name = "certificate_authority"
  }
}

resource "tls_private_key" "vpn_server_certificate_private_key" {
  algorithm   = "RSA"
  rsa_bits = "2048"
}

resource "tls_cert_request" "vpn_server_certificate_signing_request" {
  key_algorithm   = "RSA"
  private_key_pem = tls_private_key.vpn_server_certificate_private_key.private_key_pem

  subject {
    common_name = "vpn-server.${local.public_dns_domain}"
    organizational_unit = "Project Omega"
    organization = "The National Archives"
    street_address = ["Bessant Drive"]
    locality = "Kew"
    province = "Surrey"
    country = "GB"
    postal_code = "TW9 4DU"
  }
}

resource "aws_acmpca_certificate" "vpn_server_certificate" {
  certificate_authority_arn   = aws_acmpca_certificate_authority.omega_ca.arn
  certificate_signing_request = tls_cert_request.vpn_server_certificate_signing_request.cert_request_pem
  signing_algorithm           = "SHA512WITHRSA"
  validity {
    type  = "YEARS"
    value = 1
  }
}

resource "aws_acm_certificate" "vpn_server" {
  private_key = tls_private_key.vpn_server_certificate_private_key.private_key_pem
  certificate_body = aws_acmpca_certificate.vpn_server_certificate.certificate
  certificate_chain = aws_acmpca_certificate.vpn_server_certificate.certificate_chain

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "certificate"
    Scope = "vpn_server"
    Environment = "vpn"
  }
}

resource "aws_acmpca_certificate_authority_certificate" "vpn_client_ca_certificate_association" {
  certificate_authority_arn = aws_acmpca_certificate_authority.vpn_client_ca.arn

  certificate       = aws_acmpca_certificate.vpn_client_ca_certificate.certificate
  certificate_chain = aws_acmpca_certificate.vpn_client_ca_certificate.certificate_chain
}

resource "aws_acmpca_certificate" "vpn_client_ca_certificate" {
  certificate_authority_arn   = aws_acmpca_certificate_authority.omega_ca.arn
  certificate_signing_request = aws_acmpca_certificate_authority.vpn_client_ca.certificate_signing_request
  signing_algorithm           = "SHA512WITHRSA"

  template_arn = "arn:${data.aws_partition.current.partition}:acm-pca:::template/SubordinateCACertificate_PathLen0/V1"

  validity {
    type  = "YEARS"
    value = 2
  }
}

resource "aws_acmpca_certificate_authority" "vpn_client_ca" {
  type = "SUBORDINATE"

  certificate_authority_configuration {
    key_algorithm     = "RSA_4096"
    signing_algorithm = "SHA512WITHRSA"

    subject {
      common_name = "vpn-client.nationalarchives.gov.uk"
      organizational_unit = "Project Omega"
      organization = "The National Archives"
      locality = "Kew"
      state = "Surrey"
      country = "GB"
    }
  }

  tags = {
    Name = "certificate_authority"
  }
}

resource "tls_private_key" "root_vpn_client_certificate_private_key" {
  algorithm   = "RSA"
  rsa_bits = "2048"
}

resource "tls_cert_request" "root_vpn_client_certificate_signing_request" {
  key_algorithm   = "RSA"
  private_key_pem = tls_private_key.root_vpn_client_certificate_private_key.private_key_pem

  subject {
    common_name = "root.vpn-client.${local.public_dns_domain}"
    organizational_unit = "Project Omega"
    organization = "The National Archives"
    street_address = ["Bessant Drive"]
    locality = "Kew"
    province = "Surrey"
    country = "GB"
    postal_code = "TW9 4DU"
  }
}

resource "aws_acmpca_certificate" "root_vpn_client_certificate" {
  certificate_authority_arn   = aws_acmpca_certificate_authority.vpn_client_ca.arn
  certificate_signing_request = tls_cert_request.root_vpn_client_certificate_signing_request.cert_request_pem
  signing_algorithm           = "SHA512WITHRSA"
  validity {
    type  = "YEARS"
    value = 1
  }
}

resource "aws_acm_certificate" "root_vpn_client_certificate" {
  private_key = tls_private_key.root_vpn_client_certificate_private_key.private_key_pem
  certificate_body = aws_acmpca_certificate.root_vpn_client_certificate.certificate
  certificate_chain = aws_acmpca_certificate.root_vpn_client_certificate.certificate_chain

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "certificate"
    Scope = "vpn_client"
    Environment = "vpn"
  }
}

output "root_vpn_client_certificate_private_key" {
  description = "VPN Client Root Certificate Private Key"
  value = tls_private_key.root_vpn_client_certificate_private_key.private_key_pem

  sensitive = true
}

output "root_vpn_client_certificate" {
  description = "VPN Client Root Certificate"
  value = aws_acmpca_certificate.root_vpn_client_certificate.certificate
}

module "vpn_access_security_group" {
  source = "terraform-aws-modules/security-group/aws"
  version = "4.3.0"

  name        = "vpn_access_security_group"
  description = "Security group for VPN Access"

  vpc_id = module.vpc.vpc_id

  computed_ingress_with_cidr_blocks = [
    {
      description = "VPN TLS"
      from_port   = 443
      to_port     = 443
      protocol    = "udp"
      cidr_blocks = module.vpc.private_subnets_cidr_blocks[0] # This is vpc_private_subnet_dev_general
    }
  ]
  number_of_computed_ingress_with_cidr_blocks = 1

  computed_ingress_with_ipv6_cidr_blocks = [
    {
      description      = "VPN TLS (IPv6)"
      from_port        = 443
      to_port          = 443
      protocol         = "udp"
      ipv6_cidr_blocks = module.vpc.private_subnets_ipv6_cidr_blocks[0] # This is vpc_private_subnet_dev_general (IPv6)
    }
  ]
  number_of_computed_ingress_with_ipv6_cidr_blocks = 1

  egress_with_cidr_blocks = [
    {
      description = "All"
      from_port   = -1
      to_port     = -1
      protocol    = -1
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  egress_with_ipv6_cidr_blocks = [
    {
      description = "All (IPv6)"
      from_port   = -1
      to_port     = -1
      protocol    = -1
      cidr_blocks = "2001:db8::/64"
    }
  ]

  tags = {
    Name        = "sg_dev_vpn"
    Type = "security_group"
    Environment = "vpn"
  }
}

resource "aws_cloudwatch_log_group" "client_vpn_log_group" {
  name = "client_vpn"
  retention_in_days = 60
  tags = {
    Name = "log_group"
    Environment = "vpn"
  }
}

resource "aws_cloudwatch_log_stream" "client_vpn_log_stream" {
  name = "client_vpn"
  log_group_name = aws_cloudwatch_log_group.client_vpn_log_group.name
}


resource "aws_ec2_client_vpn_endpoint" "vpn" {
  description = "Omega Client VPN"
  
  client_cidr_block = local.vpn_client_cidr_block
  split_tunnel = true

  server_certificate_arn = aws_acm_certificate.vpn_server.arn

  authentication_options {
    type = "certificate-authentication"
    root_certificate_chain_arn = aws_acm_certificate.root_vpn_client_certificate.arn
  }

  connection_log_options {
    enabled = true
    cloudwatch_log_group = aws_cloudwatch_log_group.client_vpn_log_group.name
    cloudwatch_log_stream = aws_cloudwatch_log_stream.client_vpn_log_stream.name
  }

  tags = {
    Name = "client_vpn_endpoint"
    Environment = "vpn"
  }
}

output "omega_client_vpn_endpoint" {
  description = "Client VPN Endpoint for Omega"
  value = aws_ec2_client_vpn_endpoint.vpn.dns_name
}

data "aws_subnet" "vpc_private_subnet_dev_general_id" {
  vpc_id = module.vpc.vpc_id
  cidr_block = module.vpc.private_subnets_cidr_blocks[0] # This is vpc_private_subnet_dev_general
}

data "aws_subnet" "vpc_private_subnet_dev_general_ipv6_id" {
  vpc_id = module.vpc.vpc_id
  ipv6_cidr_block = module.vpc.private_subnets_ipv6_cidr_blocks[0] # This is vpc_private_subnet_dev_general (IPv6)
}

resource "aws_ec2_client_vpn_network_association" "vpn_for_vpc_private_subnet_dev_general" {
  count = 1

  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpn.id
  subnet_id = data.aws_subnet.vpc_private_subnet_dev_general_id.id  # NOTE: restricted to vpc_private_subnet_dev_general

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

resource "aws_ec2_client_vpn_authorization_rule" "vpn_auth_for_vpc_private_subnet_dev_general" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpn.id
  target_network_cidr = module.vpc.private_subnets_cidr_blocks[0]  # NOTE: restricted to vpc_private_subnet_dev_general
  authorize_all_groups = true
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "3.7.0"

  name = "tna_ct_omega_vpc"

  cidr = local.vpc_cidr_block

  azs = local.aws_azs

  # NOTE: Smallest subnet possible in a VPC is a '/28',
  #       however for a VPN connection the smallest possible subnet is '/27'
  # NOTE: The first four IP addresses and the last IP address in each subnet
  # CIDR block are not available for you to use, and cannot be assigned to
  # an instance.
  # See https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Subnets.html#vpc-sizing-ipv4
  # See https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Subnets.html#vpc-sizing-ipv6
  # Planning tool: https://tidalmigrations.com/subnet-builder/

  private_subnets = [
    local.vpc_private_subnet_dev_general,
    local.vpc_private_subnet_dev_databases
  ]
  private_subnet_ipv6_prefixes = [
    local.vpc_private_subnet_dev_general_ipv6_prefixes,
    local.vpc_private_subnet_dev_databases_ipv6_prefixes
  ]
  private_subnet_tags = {
    Type = "private_subnet"
  }

  public_subnets = [
    local.vpc_public_subnet_dev
  ]
  public_subnet_ipv6_prefixes = [
    local.vpc_public_subnet_dev_ipv6_prefixes
  ]
  public_subnet_tags = {
      Type = "public_subnet"
  }

  enable_ipv6                     = true
  assign_ipv6_address_on_creation = true

  manage_default_network_acl = true

  private_dedicated_network_acl     = true

  private_inbound_acl_rules       = [
    {
      rule_number = 100
      rule_action = "allow"
      from_port   = 22
      to_port   = 22
      protocol    = "tcp"
      cidr_block = module.vpc.private_subnets_cidr_blocks[0]  # TODO(AR) ideally this should be only the Client VPN network interface(s) in this subnet
    },
    {
      rule_number = 160
      rule_action = "allow"
      from_port   = 22
      to_port   = 22
      protocol    = "tcp"
      ipv6_cidr_block = module.vpc.private_subnets_ipv6_cidr_blocks[0]  # TODO(AR) ideally this should be only the Client VPN network interface(s) in this subnet
    },
    {
      rule_number = 200
      rule_action = "allow"
      from_port   = 3389
      to_port   = 3389
      protocol    = "tcp"
      cidr_block = module.vpc.private_subnets_cidr_blocks[0]  # TODO(AR) ideally this should be only the Client VPN network interface(s) in this subnetsubnet
    },
    {
      rule_number = 260
      rule_action = "allow"
      from_port   = 3389
      to_port   = 3389
      protocol    = "tcp"
      ipv6_cidr_block = module.vpc.private_subnets_ipv6_cidr_blocks[0]  # TODO(AR) ideally this should be only the Client VPN network interface(s) in this subnet
    },
    {
      # allow results from outgoing IPv4 internet traffic
      rule_number = 900
      rule_action = "allow"
      from_port   = 1024
      to_port     = 65535
      protocol    = "tcp"
      cidr_block  = "0.0.0.0/0"
    },
    {
      # allow results from outgoing IPv6 internet traffic
      rule_number = 960
      rule_action = "allow"
      from_port   = 1024
      to_port     = 65535
      protocol    = "tcp"
      ipv6_cidr_block = "::/0"
    }
  ]

  private_outbound_acl_rules       = [
    {
      rule_number = 100
      rule_action = "allow"
      from_port   = 22
      to_port   = 22
      protocol    = "tcp"
      cidr_block = module.vpc.private_subnets_cidr_blocks[0]  # TODO(AR) ideally this should be only the Client VPN network interface(s) in this subnetsubnet
    },
    {
      rule_number = 160
      rule_action = "allow"
      from_port   = 22
      to_port   = 22
      protocol    = "tcp"
      ipv6_cidr_block = module.vpc.private_subnets_ipv6_cidr_blocks[0]  # TODO(AR) ideally this should be only the Client VPN network interface(s) in this subnet
    },
    {
      rule_number = 200
      rule_action = "allow"
      from_port   = 3389
      to_port   = 3389
      protocol    = "tcp"
      cidr_block = module.vpc.private_subnets_cidr_blocks[0]  # TODO(AR) ideally this should be only the Client VPN network interface(s) in this subnetsubnet
    },
    {
      rule_number = 260
      rule_action = "allow"
      from_port   = 3389
      to_port   = 3389
      protocol    = "tcp"
      ipv6_cidr_block = module.vpc.private_subnets_ipv6_cidr_blocks[0]  # TODO(AR) ideally this should be only the Client VPN network interface(s) in this subnet
    },
    {
      rule_number = 300
      rule_action = "allow"
      from_port   = 80
      to_port   = 80
      protocol    = "tcp"
      cidr_block = "0.0.0.0/0"
    },
    {
      rule_number = 360
      rule_action = "allow"
      from_port   = 80
      to_port   = 80
      protocol    = "tcp"
      ipv6_cidr_block = "::/0"
    },
    {
      rule_number = 400
      rule_action = "allow"
      from_port   = 443
      to_port   = 443
      protocol    = "tcp"
      cidr_block = "0.0.0.0/0"
    },
    {
      rule_number = 460
      rule_action = "allow"
      from_port   = 443
      to_port   = 443
      protocol    = "tcp"
      ipv6_cidr_block = "::/0"
    }
  ]

  enable_nat_gateway  = true
  single_nat_gateway  = false
  one_nat_gateway_per_az = false
  reuse_nat_ips       = true             # <= Skip creation of EIPs for the NAT Gateways
  external_nat_ip_ids = aws_eip.vpc_subnet_nats.*.id # <= IPs specified here as input to the module

  vpc_tags = {
    Name = "vpc"
  }
}

# TODO (AR) do we want to log all VPC traffic in production - or just for debugging?
resource "aws_flow_log" "vpc_flow_log" {
  log_destination = aws_cloudwatch_log_group.vpc_log_group.arn
  iam_role_arn    = aws_iam_role.vpc_log_group_iam_role.arn
  traffic_type    = "ALL"
  vpc_id          = module.vpc.vpc_id
}

resource "aws_cloudwatch_log_group" "vpc_log_group" {
  name = "vpc_log_group"
  retention_in_days = 7
  tags = {
    Name = "log_group"
    Environment = "all"
  }
}

resource "aws_iam_role" "vpc_log_group_iam_role" {
  name = "vpc_log_group_iam_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "vpc-flow-logs.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "vpc_log_group_iam_role_policy" {
  name = "vpc_log_group_iam_role_policy"
  role = aws_iam_role.vpc_log_group_iam_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

output "omega_vpc" {
  description = "Omega VPC"
  value = module.vpc.vpc_id
}

resource "aws_route53_zone" "omega_private_dns" {
  name = local.private_dns_domain

  vpc {
    vpc_id = module.vpc.vpc_id
  }

  tags = {
    name = "dns_zone"
  }
}

output "omega_private_dns_servers" {
  description = "DNS Servers for Omega Internal"
  value = aws_route53_zone.omega_private_dns.name_servers
}

resource "aws_vpc_dhcp_options" "vpc_dhcp_options" {
  domain_name          = local.private_dns_domain
  #domain_name_servers  = aws_route53_zone.omega_private_dns.name_servers   # TODO(AR) how do we reesolve against our private_dns_domain?
  domain_name_servers  = ["AmazonProvidedDNS"]

  tags = {
    Name = "vpc_dhcp_options"
  }
}

resource "aws_vpc_dhcp_options_association" "dns_resolver" {
  vpc_id          = module.vpc.vpc_id
  dhcp_options_id = aws_vpc_dhcp_options.vpc_dhcp_options.id
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

module "dev_workstation_security_group" {
  source = "terraform-aws-modules/security-group/aws"
  version = "4.3.0"

  name        = "dev_workstation_security_group"
  description = "Security group for Development Workstation ports open within VPC"

  vpc_id = module.vpc.vpc_id

  computed_ingress_with_cidr_blocks = [
    {
      description = "SSH"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = module.vpc.private_subnets_cidr_blocks[0]  # NOTE: restricted to vpc_private_subnet_dev_general
    },
    {
      description = "RDP"
      from_port   = 3389
      to_port     = 3389
      protocol    = "tcp"
      cidr_blocks = module.vpc.private_subnets_cidr_blocks[0]  # NOTE: restricted to vpc_private_subnet_dev_general
    }
  ]
  number_of_computed_ingress_with_cidr_blocks = 2

  computed_ingress_with_ipv6_cidr_blocks = [
    {
      description      = "SSH (IPv6)"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      ipv6_cidr_blocks = module.vpc.private_subnets_ipv6_cidr_blocks[0]  # NOTE: restricted to vpc_private_subnet_dev_general (IPv6)
    },
    {
      description = "RDP (IPv6)"
      from_port   = 3389
      to_port     = 3389
      protocol    = "tcp"
      ipv6_cidr_blocks = module.vpc.private_subnets_ipv6_cidr_blocks[0]  # NOTE: restricted to vpc_private_subnet_dev_general (IPv6)
    }
  ]
  number_of_computed_ingress_with_ipv6_cidr_blocks = 2

  egress_with_cidr_blocks = [
    {
      description = "All"
      from_port   = -1
      to_port     = -1
      protocol    = -1
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  egress_with_ipv6_cidr_blocks = [
    {
      description = "All (IPv6)"
      from_port   = -1
      to_port     = -1
      protocol    = -1
      cidr_blocks = "2001:db8::/64"
    }
  ]

  tags = {
    Name        = "sg_dev_workstation"
    Type = "security_group"
    Environment = "dev"
  }
}

resource "aws_network_interface" "dev_workstation_1_private_interface" {
  description        = "Private Subnet Interface for Dev Workstation 1"
  subnet_id          = module.vpc.private_subnets[0]
  private_ips        = ["10.128.238.4"]
  ipv6_address_count = 0 # use assign_ipv6_address_on_creation=true from the vpc subnet configuration

  security_groups = [
      module.dev_workstation_security_group.security_group_id
  ]

  tags = {
    Name        = "eth0_dev1"
    Type        = "primary_network_interface"
    Network     = "dev_private"
    Environment = "dev"
  }
}

data "aws_network_interface" "dev_workstation_1_private_interface" {
  id = aws_network_interface.dev_workstation_1_private_interface.id
}

resource "aws_network_interface" "dev_workstation_1_database_interface" {
  description        = "Dev Database Subnet Interface for Dev Workstation 1"
  subnet_id          = module.vpc.private_subnets[1]
  private_ips        = ["10.128.238.100"]
  ipv6_address_count = 0 # use assign_ipv6_address_on_creation=true from the vpc subnet configuration

  tags = {
    Name        = "eth1_dev1"
    Type        = "secondary_network_interface"
    Network     = "dev_database"
    Environment = "dev"
  }
}

resource "aws_key_pair" "omega_admin_key_pair" {
  key_name = "omega-admin-key-pair"

  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDgy946NcJxQGKhoMSpdKKxKwH1hqM4VOolTiYB+AssPV+8yJ8NTbAdxJhm0as6IIbJgVcrYpoZ98S+DKN1WZwJLBM+ahKbXhftvu+EIq7TQlUjreBimArbRK7VCSGnyLHfaMDgE7X+pXrfnrLwvYyp2vODPfl7p0wGsbPIAFNzmI2NyX2o/ozRJWtHwK29PGj0nqRs1TpfD9PUGEm4dqAMVllLwl/glu3/vS18QfNAda5q4wW3Gz+YBR1aefp9xj/RXaTFjUUAVcbiIkB32zstOTn95BLEYk4soLm2Wrr49aYcMoQWS4jqqegCNIM07RHxNrx9dti8CVhF82LeMxl3vUjS3BddmhxGTSuMio1QwTJWTTRuWGhwMZof2RG6YnZhmwl2iy9Ptk9jlwofU8TziP2A0zvllhMvtrr3sVk8QFQ3wmKxeM7PKCbmdVmOETXTCiJ5b33e5B7FoVYsuUxolJyN39tkLG8aBEgYGmowqxSsnJ0BcFIaX2jfoCRGLbs= admin@cat.nationalarchives.gov.uk"

  tags = {
    Name = "key_pair"
    Network = "all"
    Environment = "all"
  }
}

data "cloudinit_config" "dev_workstation" {
  gzip = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    filename = "yum-upgrade.yaml"
    content = <<EOF
#cloud-config
package_update: true
package_upgrade: true
EOF
  }

  part {
    content_type = "text/x-shellscript"
    filename = "omega-01-install-puppet.sh"
    content = <<EOF
#!/usr/bin/env bash
rpm -Uvh https://yum.puppet.com/puppet7-release-el-7.noarch.rpm
yum -y install puppet
EOF
  }

  part {
    content_type = "text/x-shellscript"
    filename = "omega-02-install-puppet-modules.sh"
    content = <<EOF
#!/usr/bin/env bash
/opt/puppetlabs/bin/puppet module install puppetlabs-stdlib --version 7.1.0
/opt/puppetlabs/bin/puppet module install saz-ssh
/opt/puppetlabs/bin/puppet module install domkrm-ufw
/opt/puppetlabs/bin/puppet module install puppet-yum
/opt/puppetlabs/bin/puppet module install puppetlabs-sshkeys_core
/opt/puppetlabs/bin/puppet module install puppetlabs-vcsrepo
EOF
  }

  part {
    content_type = "text/x-shellscript"
    filename = "omega-03-install-puppet-scripts.sh"
    content = <<EOF
#!/usr/bin/env bash
mkdir /root/omega-puppet-scripts
echo '${filebase64("base.pp")}' | base64 -d > /root/omega-puppet-scripts/base.pp
echo '${filebase64("developer-vm.pp")}' | base64 -d > /root/omega-puppet-scripts/developer-vm.pp
EOF
  }

  part {
    content_type = "text/x-shellscript"
    filename = "omega-04-run-puppet-scripts.sh"
    content = <<EOF
#!/usr/bin/env bash
/opt/puppetlabs/bin/puppet apply /root/omega-puppet-scripts
EOF
  }
}

resource "aws_instance" "dev_workstation_1" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = "m5a.2xlarge"

  key_name = aws_key_pair.omega_admin_key_pair.key_name

  user_data = data.cloudinit_config.dev_workstation.rendered

  monitoring = false

  network_interface {
    network_interface_id = aws_network_interface.dev_workstation_1_private_interface.id
    device_index         = 0
  }

  network_interface {
    network_interface_id = aws_network_interface.dev_workstation_1_database_interface.id
    device_index         = 1
  }

  root_block_device {
    delete_on_termination = false
    encrypted             = false
    volume_type           = "gp3"
    iops                  = 3000
    throughput            = 125 # MiB/s
    volume_size           = 500 # GiB

    tags = {
      Name        = "root_dev1"
      Type = "primary_volume"
      Environment = "dev"
    }
  }

  tags = {
    Name        = "dev1"
    Type        = "dev_workstation"
    Environment = "dev"
  }
}

resource "aws_route53_record" "dns_a_dev1_in_cat_nationalarchives_gov_uk" {
  zone_id = aws_route53_zone.omega_private_dns.zone_id
  name    = "dev1.${local.private_dns_domain}"
  type    = "A"
  ttl     = "300"
  records = data.aws_network_interface.dev_workstation_1_private_interface.private_ips
}

resource "aws_network_interface" "dev_mssql_server_1_database_interface" {
  description        = "Dev Database Subnet Interface for Dev MS SQL Server 1"
  subnet_id          = module.vpc.private_subnets[1]
  private_ips        = ["10.128.238.126"]
  ipv6_address_count = 0 # use assign_ipv6_address_on_creation=true from the vpc subnet configuration

  tags = {
    Name        = "eth0_mssql1"
    Type        = "primary_network_interface"
    Network     = "dev_database"
    Environment = "dev"
  }
}

data "aws_network_interface" "dev_mssql_server_1_database_interface" {
  id = aws_network_interface.dev_mssql_server_1_database_interface.id
}

data "cloudinit_config" "mssql_server" {
  gzip = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    filename = "yum-upgrade.yaml"
    content = <<EOF
#cloud-config
package_update: true
package_upgrade: true
EOF
  }

  part {
    content_type = "text/x-shellscript"
    filename = "omega-01-install-puppet.sh"
    content = <<EOF
#!/usr/bin/env bash
rpm -Uvh https://yum.puppet.com/puppet7-release-el-7.noarch.rpm
yum -y install puppet
EOF
  }

  part {
    content_type = "text/x-shellscript"
    filename = "omega-02-install-puppet-modules.sh"
    content = <<EOF
#!/usr/bin/env bash
/opt/puppetlabs/bin/puppet module install puppetlabs-stdlib --version 7.1.0
/opt/puppetlabs/bin/puppet module install saz-ssh
/opt/puppetlabs/bin/puppet module install domkrm-ufw
/opt/puppetlabs/bin/puppet module install puppet-yum
/opt/puppetlabs/bin/puppet module install puppetlabs-sshkeys_core
/opt/puppetlabs/bin/puppet module install puppetlabs-vcsrepo
EOF
  }

  part {
    content_type = "text/x-shellscript"
    filename = "omega-03-install-puppet-scripts.sh"
    content = <<EOF
#!/usr/bin/env bash
mkdir /root/omega-puppet-scripts
echo '${filebase64("base.pp")}' | base64 -d > /root/omega-puppet-scripts/base.pp
echo '${filebase64("sqlserver-vm.pp")}' | base64 -d > /root/omega-puppet-scripts/sqlserver-vm.pp
EOF
  }

  part {
    content_type = "text/x-shellscript"
    filename = "omega-04-run-puppet-scripts.sh"
    content = <<EOF
#!/usr/bin/env bash
/opt/puppetlabs/bin/puppet apply /root/omega-puppet-scripts
EOF
  }
}

resource "aws_instance" "mssql_server_1" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = "r5.xlarge"
  # m5a.2xlarge == $0.4 / hour == 8 vCPU == 32GiB RAM
  # r5.xlarge == $0.296 / hour == 4 vCPU == 32GiB RAM

  key_name = aws_key_pair.omega_admin_key_pair.key_name

  user_data = data.cloudinit_config.mssql_server.rendered

  monitoring = true

  network_interface {
    network_interface_id = aws_network_interface.dev_mssql_server_1_database_interface.id
    device_index         = 0
  }

  root_block_device {
    delete_on_termination = false
    encrypted             = false
    volume_type           = "gp3"
    iops                  = 3000
    throughput            = 125 # MiB/s
    volume_size           = 60  # GiB

    tags = {
      Name        = "root_mssql1"
      Type        = "primary_volume"
      Environment = "dev"
    }
  }

  ebs_block_device {
    device_name           = "xvdb"
    delete_on_termination = false
    encrypted             = false
    volume_type           = "gp3" # TODO(AR) consider upgrading to io2 and/or more IOPS
    iops                  = 3000
    throughput            = 125 # MiB/s
    volume_size           = 150 # GiB

    tags = {
      Name        = "data_mssql1"
      Type        = "mssql_data_volume"
      Environment = "dev"
    }
  }

  ebs_block_device {
    device_name           = "xvdc"
    delete_on_termination = false
    encrypted             = false
    volume_type           = "gp3" # TODO(AR) consider upgrading to io2 and/or more IOPS
    iops                  = 3000
    throughput            = 125 # MiB/s
    volume_size           = 75  # GiB

    tags = {
      Name        = "log_mssql1"
      Type        = "mssql_log_volume"
      Environment = "dev"
    }
  }

  ebs_block_device {
    device_name           = "xvdd"
    delete_on_termination = false
    encrypted             = false
    volume_type           = "gp3" # TODO(AR) consider upgrading to io2 and/or more IOPS
    iops                  = 3000
    throughput            = 125 # MiB/s
    volume_size           = 150 # GiB

    tags = {
      Name        = "backup_mssql1"
      Type        = "mssql_backup_volume"
      Environment = "dev"
    }
  }

  tags = {
    Name = "mssql1"
    Type        = "dev_mssql_server"
    Environment = "dev"
  }
}

resource "aws_route53_record" "dns_a_mssql1_in_cat_nationalarchives_gov_uk" {
  zone_id = aws_route53_zone.omega_private_dns.zone_id
  name    = "mssql1.${local.private_dns_domain}"
  type    = "A"
  ttl     = "300"
  records = data.aws_network_interface.dev_mssql_server_1_database_interface.private_ips
}


# TODO(AR) - how about scheduled startup times each day? -- AWS Instance Scheduler -- https://registry.terraform.io/modules/diodonfrost/lambda-scheduler-stop-start/aws/latest

