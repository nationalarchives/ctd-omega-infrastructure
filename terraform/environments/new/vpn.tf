module "vpn_access_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.17.2"

  name        = "vpn_access_security_group_test_jt"
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
    Name        = "sg_dev_vpn_test_jt"
    Type        = "security_group"
    Environment = "vpn"
  }
}