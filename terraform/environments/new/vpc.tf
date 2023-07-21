module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "4.0.1"

  name                  = "tna_ct_omega_vpc_new"
  cidr                  = local.vpc_cidr_block

  azs = local.aws_azs

  # NOTE: Smallest subnet possible in a VPC is a '/28',
  #       however for a VPN connection the smallest possible subnet is '/27'
  # NOTE: The first four IP addresses and the last IP address in each subnet
  # CIDR block are not available for you to use, and cannot be assigned to
  # an instance.
  # See https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Subnets.html#vpc-sizing-ipv4
  # See https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Subnets.html#vpc-sizing-ipv6
  # Planning tool: https://tidalmigrations.com/subnet-builder/

  private_subnets                                = local.vpc_private_subnets
  private_subnet_assign_ipv6_address_on_creation = true
  private_subnet_ipv6_prefixes                   = local.vpc_private_ipv6_subnets
  private_subnet_tags = {
    Type = "private_subnet"
  }

  database_subnets                                = local.vpc_database_subnets
  database_subnet_assign_ipv6_address_on_creation = true
  database_subnet_ipv6_prefixes                   = local.vpc_database_ipv6_subnets
  database_subnet_tags = {
    Type = "database_subnet"
  }

  intra_subnets                                = local.vpc_intra_subnets
  intra_subnet_assign_ipv6_address_on_creation = true
  intra_subnet_ipv6_prefixes                   = local.vpc_intra_ipv6_subnets
  intra_subnet_tags = {
    Type = "intra_subnet"
  }

  public_subnets                                = local.vpc_public_subnets
  public_subnet_assign_ipv6_address_on_creation = true
  public_subnet_ipv6_prefixes                   = local.vpc_public_ipv6_subnets
  public_subnet_tags = {
    Type = "public_subnet"
  }

  enable_ipv6             = true
  map_public_ip_on_launch = false

  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false
  reuse_nat_ips          = true                         # <= Skip creation of EIPs for the NAT Gateways
  external_nat_ip_ids    = aws_eip.vpc_subnet_nats.*.id # <= IPs specified here as input to the module

  enable_dns_support   = true
  enable_dns_hostnames = false

  manage_default_security_group = true
  manage_default_network_acl    = true
  manage_default_route_table    = false

  default_security_group_ingress = [
    {
      description = "Allow all"
      protocol    = -1
      self        = true
    }
  ]

  default_security_group_egress = [
    {
      description      = "Allow all"
      protocol         = -1
      from_port        = 0
      to_port          = 0
      cidr_blocks      = "0.0.0.0/0"
      ipv6_cidr_blocks = "::/0"
    }
  ]

  public_dedicated_network_acl = true

  public_inbound_acl_rules = []

  public_outbound_acl_rules = []

  private_dedicated_network_acl = true

  private_inbound_acl_rules = [
    {
      rule_number = 100
      rule_action = "allow"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_block  = module.vpc.private_subnets_cidr_blocks[0] # NOTE: restricted to vpc_private_subnet_dev_general
    },
    {
      rule_number     = 160
      rule_action     = "allow"
      from_port       = 22
      to_port         = 22
      protocol        = "tcp"
      ipv6_cidr_block = module.vpc.private_subnets_ipv6_cidr_blocks[0] # NOTE: restricted to vpc_private_subnet_dev_general
    },
    {
      rule_number = 200
      rule_action = "allow"
      from_port   = 3389
      to_port     = 3389
      protocol    = "tcp"
      cidr_block  = module.vpc.private_subnets_cidr_blocks[0] # NOTE: restricted to vpc_private_subnet_dev_general
    },
    {
      rule_number     = 260
      rule_action     = "allow"
      from_port       = 3389
      to_port         = 3389
      protocol        = "tcp"
      ipv6_cidr_block = module.vpc.private_subnets_ipv6_cidr_blocks[0] # NOTE: restricted to vpc_private_subnet_dev_general
    },
    {
      rule_number = 300
      rule_action = "allow"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_block  = module.vpc.private_subnets_cidr_blocks[0] # NOTE: restricted to vpc_private_subnet_dev_general
    },
    {
      rule_number     = 360
      rule_action     = "allow"
      from_port       = 80
      to_port         = 80
      protocol        = "tcp"
      ipv6_cidr_block = module.vpc.private_subnets_ipv6_cidr_blocks[0] # NOTE: restricted to vpc_private_subnet_dev_general
    },
    {
      rule_number = 400
      rule_action = "allow"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_block  = module.vpc.private_subnets_cidr_blocks[0] # NOTE: restricted to vpc_private_subnet_dev_general
    },
    {
      rule_number     = 460
      rule_action     = "allow"
      from_port       = 443
      to_port         = 443
      protocol        = "tcp"
      ipv6_cidr_block = module.vpc.private_subnets_ipv6_cidr_blocks[0] # NOTE: restricted to vpc_private_subnet_dev_general
    },
    {
      rule_number = 600
      rule_action = "allow"
      from_port   = 9443
      to_port     = 9443
      protocol    = "tcp"
      cidr_block  = module.vpc.private_subnets_cidr_blocks[0] # NOTE: restricted to vpc_private_subnet_dev_general
    },
    {
      rule_number     = 660
      rule_action     = "allow"
      from_port       = 9443
      to_port         = 9443
      protocol        = "tcp"
      ipv6_cidr_block = module.vpc.private_subnets_ipv6_cidr_blocks[0] # NOTE: restricted to vpc_private_subnet_dev_general
    },
    {
      # allow results from outgoing IPv4 internet traffic
      rule_number = 900
      rule_action = "allow"
      from_port   = local.unpriviledged_port_start
      to_port     = local.unpriviledged_port_end
      protocol    = "tcp"
      cidr_block  = "0.0.0.0/0"
    },
    {
      # allow results from outgoing IPv6 internet traffic
      rule_number     = 960
      rule_action     = "allow"
      from_port       = local.unpriviledged_port_start
      to_port         = local.unpriviledged_port_end
      protocol        = "tcp"
      ipv6_cidr_block = "::/0"
    }
  ]

  private_outbound_acl_rules = [
    {
      rule_number = 100
      rule_action = "allow"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_block  = module.vpc.private_subnets_cidr_blocks[0] # NOTE: restricted to vpc_private_subnet_dev_general
    },
    {
      rule_number     = 160
      rule_action     = "allow"
      from_port       = 22
      to_port         = 22
      protocol        = "tcp"
      ipv6_cidr_block = module.vpc.private_subnets_ipv6_cidr_blocks[0] # NOTE: restricted to vpc_private_subnet_dev_general
    },
    {
      rule_number = 101
      rule_action = "allow"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_block  = module.vpc.private_subnets_cidr_blocks[4] # NOTE: restricted to vpc_private_tna_net_subnet_mvpbeta
    },
    {
      rule_number     = 161
      rule_action     = "allow"
      from_port       = 22
      to_port         = 22
      protocol        = "tcp"
      ipv6_cidr_block = module.vpc.private_subnets_ipv6_cidr_blocks[4] # NOTE: restricted to vpc_private_tna_net_subnet_mvpbeta
    },
    {
      rule_number = 102
      rule_action = "allow"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_block  = module.vpc.private_subnets_cidr_blocks[2] # NOTE: restricted to vpc_private_subnet_mvpbeta_web
    },
    {
      rule_number     = 162
      rule_action     = "allow"
      from_port       = 22
      to_port         = 22
      protocol        = "tcp"
      ipv6_cidr_block = module.vpc.private_subnets_ipv6_cidr_blocks[2] # NOTE: restricted to vpc_private_subnet_mvpbeta_web
    },
    {
      rule_number = 200
      rule_action = "allow"
      from_port   = 3389
      to_port     = 3389
      protocol    = "tcp"
      cidr_block  = module.vpc.private_subnets_cidr_blocks[0] # NOTE: restricted to vpc_private_subnet_dev_general
    },
    {
      rule_number     = 260
      rule_action     = "allow"
      from_port       = 3389
      to_port         = 3389
      protocol        = "tcp"
      ipv6_cidr_block = module.vpc.private_subnets_ipv6_cidr_blocks[0] # NOTE: restricted to vpc_private_subnet_dev_general
    },
    {
      rule_number = 300
      rule_action = "allow"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_block  = "0.0.0.0/0"
    },
    {
      rule_number     = 360
      rule_action     = "allow"
      from_port       = 80
      to_port         = 80
      protocol        = "tcp"
      ipv6_cidr_block = "::/0"
    },
    {
      rule_number = 400
      rule_action = "allow"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_block  = "0.0.0.0/0"
    },
    {
      rule_number     = 460
      rule_action     = "allow"
      from_port       = 443
      to_port         = 443
      protocol        = "tcp"
      ipv6_cidr_block = "::/0"
    },
    {
      rule_number = 500
      rule_action = "allow"
      from_port   = 9443
      to_port     = 9443
      protocol    = "tcp"
      cidr_block  = module.vpc.private_subnets_cidr_blocks[2] # NOTE: restricted to vpc_private_subnet_mvpbeta_web
    },
    {
      rule_number     = 560
      rule_action     = "allow"
      from_port       = 9443
      to_port         = 9443
      protocol        = "tcp"
      ipv6_cidr_block = module.vpc.private_subnets_ipv6_cidr_blocks[2] # NOTE: restricted to vpc_private_subnet_mvpbeta_web
    },
    {
      # allow IPv4 return traffic from vpc_private_subnet_dev_general
      rule_number = 1200
      rule_action = "allow"
      from_port   = local.linux_ephemeral_port_start
      to_port     = local.linux_ephemeral_port_end
      protocol    = "tcp"
      cidr_block  = module.vpc.private_subnets_cidr_blocks[0] # NOTE: restricted to vpc_private_subnet_dev_general
    },
    {
      # allow IPv6 return traffic from vpc_private_subnet_dev_general
      rule_number     = 1260
      rule_action     = "allow"
      from_port       = local.linux_ephemeral_port_start
      to_port         = local.linux_ephemeral_port_end
      protocol        = "tcp"
      ipv6_cidr_block = module.vpc.private_subnets_ipv6_cidr_blocks[0] # NOTE: restricted to vpc_private_subnet_dev_general
    },
    {
      # allow IPv4 return traffic from vpc_private_tna_net_subnet_mvpbeta
      rule_number = 1400
      rule_action = "allow"
      from_port   = local.linux_ephemeral_port_start
      to_port     = local.linux_ephemeral_port_end
      protocol    = "tcp"
      cidr_block  = module.vpc.private_subnets_cidr_blocks[4] # NOTE: restricted to vpc_private_tna_net_subnet_mvpbeta
    },
    {
      # allow IPv6 return traffic from vpc_private_subnet_mvpbeta_web
      rule_number     = 1460
      rule_action     = "allow"
      from_port       = local.linux_ephemeral_port_start
      to_port         = local.linux_ephemeral_port_end
      protocol        = "tcp"
      ipv6_cidr_block = module.vpc.private_subnets_ipv6_cidr_blocks[4] # NOTE: restricted to vpc_private_subnet_mvpbeta_web
    },
  ]

  vpc_tags = {
    Name = "tag_tna_ct_omega_vpc_new"
  }
}

resource "aws_eip" "vpc_subnet_nats" {
  count = 1 # NOTE: must match the number of NAT Gateways in the VPC!
  vpc   = true
}