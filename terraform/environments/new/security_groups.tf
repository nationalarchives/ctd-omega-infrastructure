module "dev_workstation_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.0"

  name        = "dev_workstation_security_group_new"
  description = "Security group for Development Workstation ports open within VPC"

  vpc_id = module.vpc.vpc_id

  computed_ingress_with_cidr_blocks = [
    {
      description = "SSH"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = module.vpc.private_subnets_cidr_blocks[0] # NOTE: restricted to vpc_private_subnet_dev_general
    },
    {
      description = "return-from-vpc_private_tna_net_subnet_mvpbeta"
      from_port   = local.linux_ephemeral_port_start
      to_port     = local.linux_ephemeral_port_end
      protocol    = "tcp"
      cidr_blocks = module.vpc.private_subnets_cidr_blocks[8] # NOTE: restricted to vpc_private_tna_net_subnet_mvpbeta
    },
    {
      description = "return-from-vpc_private_subnet_mvpbeta_web"
      from_port   = local.linux_ephemeral_port_start
      to_port     = local.linux_ephemeral_port_end
      protocol    = "tcp"
      cidr_blocks = module.vpc.private_subnets_cidr_blocks[4] # NOTE: restricted to vpc_private_subnet_mvpbeta_web
    },
    {
      description = "RDP"
      from_port   = 3389
      to_port     = 3389
      protocol    = "tcp"
      cidr_blocks = module.vpc.private_subnets_cidr_blocks[0] # NOTE: restricted to vpc_private_subnet_dev_general
    }
  ]
  number_of_computed_ingress_with_cidr_blocks = 4

  computed_ingress_with_ipv6_cidr_blocks = [
    {
      description      = "SSH (IPv6)"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      ipv6_cidr_blocks = module.vpc.private_subnets_ipv6_cidr_blocks[0] # NOTE: restricted to vpc_private_subnet_dev_general (IPv6)
    },
    {
      description      = "return-from-vpc_private_tna_net_subnet_mvpbeta (IPv6)"
      from_port        = local.linux_ephemeral_port_start
      to_port          = local.linux_ephemeral_port_end
      protocol         = "tcp"
      ipv6_cidr_blocks = module.vpc.private_subnets_ipv6_cidr_blocks[8] # NOTE: restricted to vpc_private_tna_net_subnet_mvpbeta (IPv6)
    },
    {
      description      = "return-from-vpc_private_subnet_mvpbeta_web (IPv6)"
      from_port        = local.linux_ephemeral_port_start
      to_port          = local.linux_ephemeral_port_end
      protocol         = "tcp"
      ipv6_cidr_blocks = module.vpc.private_subnets_ipv6_cidr_blocks[4] # NOTE: restricted to vpc_private_subnet_mvpbeta_web (IPv6)
    },
    {
      description      = "RDP (IPv6)"
      from_port        = 3389
      to_port          = 3389
      protocol         = "tcp"
      ipv6_cidr_blocks = module.vpc.private_subnets_ipv6_cidr_blocks[0] # NOTE: restricted to vpc_private_subnet_dev_general (IPv6)
    }
  ]
  number_of_computed_ingress_with_ipv6_cidr_blocks = 4

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
    Name        = "sg_dev_workstation_new"
    Type        = "security_group"
    Environment = "dev"
  }
}

module "dev_database_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.0"

  name        = "dev_database_security_group_new"
  description = "Security group for Development Database ports open within VPC"

  vpc_id = module.vpc.vpc_id

  computed_ingress_with_cidr_blocks = [
    {
      description = "SSH"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = module.vpc.database_subnets_cidr_blocks[0] # NOTE: restricted to vpc_private_subnet_dev_databases
    },
    {
      description = "SSH from vpc_private_subnet_dev_general"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = module.vpc.private_subnets_cidr_blocks[0] # NOTE: restricted to vpc_private_subnet_dev_general
    }
  ]
  number_of_computed_ingress_with_cidr_blocks = 2

  computed_ingress_with_ipv6_cidr_blocks = [
    {
      description      = "SSH (IPv6)"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      ipv6_cidr_blocks = module.vpc.database_subnets_ipv6_cidr_blocks[0] # NOTE: restricted to vpc_private_subnet_dev_databases (IPv6)
    },
    {
      description      = "SSH (IPv6) from vpc_private_subnet_dev_general"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      ipv6_cidr_blocks = module.vpc.private_subnets_ipv6_cidr_blocks[0] # NOTE: restricted to vpc_private_subnet_dev_general (IPv6)
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
    Name        = "sg_dev_database_new"
    Type        = "security_group"
    Environment = "dev"
  }
}

module "puppet_server_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.0"

  name        = "puppet_server_security_group_new"
  description = "Security group for Puppet Server ports open within VPC"

  vpc_id = module.vpc.vpc_id

  computed_ingress_with_cidr_blocks = [
    {
      description = "SSH"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = module.vpc.private_subnets_cidr_blocks[2] # NOTE: restricted to vpc_private_subnet_management
    },
    {
      description = "SSH from vpc_private_subnet_dev_general"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = module.vpc.private_subnets_cidr_blocks[0] # NOTE: restricted to vpc_private_subnet_dev_general
    },
    {
      description = "Puppet"
      from_port   = 8140
      to_port     = 8140
      protocol    = "tcp"
      cidr_blocks = join(",", [
        module.vpc.private_subnets_cidr_blocks[2], # NOTE: restricted to vpc_private_subnet_management
        module.vpc.private_subnets_cidr_blocks[0]  # NOTE: restricted to vpc_private_subnet_dev_general
      ])
    }
  ]
  number_of_computed_ingress_with_cidr_blocks = 3

  computed_ingress_with_ipv6_cidr_blocks = [
    {
      description      = "SSH (IPv6)"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      ipv6_cidr_blocks = module.vpc.private_subnets_ipv6_cidr_blocks[2] # NOTE: restricted to vpc_private_subnet_management (IPv6)
    },
    {
      description      = "SSH (IPv6) from vpc_private_subnet_dev_general"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      ipv6_cidr_blocks = module.vpc.private_subnets_ipv6_cidr_blocks[0] # NOTE: restricted to vpc_private_subnet_dev_general (IPv6)
    },
    {
      description      = "Puppet (IPv6)"
      from_port        = 8140
      to_port          = 8140
      protocol         = "tcp"
      ipv6_cidr_blocks = join(",", [
        module.vpc.private_subnets_ipv6_cidr_blocks[2], # NOTE: restricted to vpc_private_subnet_management (IPv6)
        module.vpc.private_subnets_ipv6_cidr_blocks[0]  # NOTE: restricted to vpc_private_subnet_dev_general
      ])
    }
  ]
  number_of_computed_ingress_with_ipv6_cidr_blocks = 3

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
    Name        = "sg_puppet_server_new"
    Type        = "security_group"
    Environment = "dev"
  }
}