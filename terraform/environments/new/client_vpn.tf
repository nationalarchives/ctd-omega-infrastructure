module "cvpn_access_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.17.2"

  name        = "vpn_access_security_group_new"
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
    Name        = "sg_dev_vpn_new"
    Type        = "security_group"
    Environment = "vpn"
  }
}

resource "aws_cloudwatch_log_group" "client_vpn_log_group_new" {
  name              = "client_vpn_new"
  retention_in_days = 60
  tags = {
    Name        = "log_group"
    Environment = "vpn"
  }
}

resource "aws_cloudwatch_log_stream" "client_vpn_log_stream_new" {
  name           = "client_vpn_new"
  log_group_name = aws_cloudwatch_log_group.client_vpn_log_group_new.name
}

resource "aws_ec2_client_vpn_endpoint" "vpn_new" {
  description = "Omega Client VPN"

  vpc_id = module.vpc.vpc_id

  client_cidr_block = local.vpn_client_cidr_block
  split_tunnel      = true

  server_certificate_arn = aws_acm_certificate.vpn_client_server_certificate_new.arn

  authentication_options {
    type                       = "certificate-authentication"
    root_certificate_chain_arn = aws_acm_certificate.vpn_client_ca_certificate_new.arn
  }

  connection_log_options {
    enabled               = true
    cloudwatch_log_group  = aws_cloudwatch_log_group.client_vpn_log_group_new.name
    cloudwatch_log_stream = aws_cloudwatch_log_stream.client_vpn_log_stream_new.name
  }

  self_service_portal = "disabled"

  security_group_ids = [
    module.cvpn_access_security_group.security_group_id
  ]

  tags = {
    Name        = "client_vpn_endpoint_new"
    Environment = "vpn"
  }
}

output "omega_client_vpn_endpoint" {
  description = "Client VPN Endpoint for Omega"
  value       = aws_ec2_client_vpn_endpoint.vpn_new.dns_name
}

data "aws_subnet" "vpc_private_subnet_dev_general_id" {
  vpc_id     = module.vpc.vpc_id
  cidr_block = module.vpc.private_subnets_cidr_blocks[0] # This is vpc_private_subnet_dev_general
}

data "aws_subnet" "vpc_private_subnet_dev_general_ipv6_id" {
  vpc_id          = module.vpc.vpc_id
  ipv6_cidr_block = module.vpc.private_subnets_ipv6_cidr_blocks[0] # This is vpc_private_subnet_dev_general (IPv6)
}

resource "aws_ec2_client_vpn_network_association" "cvpn_for_vpc_private_subnet_dev_general" {
  count = 1

  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpn_new.id
  subnet_id              = data.aws_subnet.vpc_private_subnet_dev_general_id.id # NOTE: restricted to vpc_private_subnet_dev_general

  lifecycle {
    // The issue why we are ignoring changes is that on every change
    // terraform screws up most of the vpn assosciations
    // see: https://github.com/hashicorp/terraform-provider-aws/issues/14717
    ignore_changes = [subnet_id]
  }
}

resource "aws_ec2_client_vpn_authorization_rule" "cvpn_auth_for_vpc_private_subnet_dev_general" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpn_new.id
  target_network_cidr    = module.vpc.private_subnets_cidr_blocks[0] # NOTE: restricted to vpc_private_subnet_dev_general
  authorize_all_groups   = true
}
