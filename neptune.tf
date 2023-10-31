resource "aws_neptune_cluster" "dev_neptune_cluster_a" {
  cluster_identifier = local.neptune_dev_cluster_a.id
  availability_zones = local.aws_azs

  neptune_subnet_group_name = local.neptune_dev_cluster_a.subnet_group_name
  vpc_security_group_ids    = [module.dev_neptune_cluster_a_security_group.security_group_id]

  engine                               = "neptune"
  engine_version                       = "1.2.1.0"
  neptune_cluster_parameter_group_name = aws_neptune_cluster_parameter_group.dev_neptune_cluster_a.name

  serverless_v2_scaling_configuration {
    min_capacity = 2.5
    max_capacity = 12
  }

  iam_database_authentication_enabled = true
  storage_encrypted                   = false

  iam_roles = [
    aws_iam_role.neptune_loader_iam_role.arn
  ]

  preferred_backup_window = "00:00-04:00"
  backup_retention_period = 14 # days

  preferred_maintenance_window = "sun:04:00-sun:08:00"

  skip_final_snapshot       = false
  final_snapshot_identifier = "${local.neptune_dev_cluster_a.id}-final-snapshot"
  copy_tags_to_snapshot     = true

  apply_immediately   = true  # TODO(AR) should be set to false for production
  deletion_protection = false # TODO(AR) should be set to true for production

  depends_on = [
    aws_neptune_subnet_group.dev_neptune_cluster_a
  ]

  tags = {
    Name        = local.neptune_dev_cluster_a.id
    Type        = "database"
    DBType      = "neptune"
    Environment = "dev"
  }
}

resource "aws_neptune_cluster_parameter_group" "dev_neptune_cluster_a" {
  name   = local.neptune_dev_cluster_a.id
  family = "neptune1.2"

  parameter {
    name  = "neptune_enable_audit_log"
    value = 1
  }
}

resource "aws_neptune_cluster_instance" "dev_neptune_cluster_a_instance" {
  cluster_identifier = aws_neptune_cluster.dev_neptune_cluster_a.id

  identifier_prefix = local.neptune_dev_cluster_a.instance_prefix

  neptune_parameter_group_name = aws_neptune_parameter_group.dev_neptune_cluster_a_instance.name

  count          = 2
  instance_class = "db.serverless"

  publicly_accessible       = false
  neptune_subnet_group_name = local.neptune_dev_cluster_a.subnet_group_name

  apply_immediately = true # TODO(AR) should we set this to 'false' for production?

  tags = {
    Name        = local.neptune_dev_cluster_a.instance_prefix
    Type        = "database"
    DBType      = "neptune"
    Environment = "dev"
  }
}

resource "aws_neptune_parameter_group" "dev_neptune_cluster_a_instance" {
  name   = local.neptune_dev_cluster_a.instance_prefix
  family = "neptune1.2"
}

resource "aws_neptune_subnet_group" "dev_neptune_cluster_a" {
  name       = local.neptune_dev_cluster_a.subnet_group_name
  subnet_ids = module.vpc.intra_subnets

  tags = {
    Name        = "${local.neptune_dev_cluster_a.id}-sg"
    Type        = "neptune_subnet_group"
    Environment = "dev"
  }
}

module "dev_neptune_cluster_a_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.0"

  name        = "dev_neptune_cluster_a_security_group_new"
  description = "Security group for Neptune ports open within VPC"

  vpc_id = module.vpc.vpc_id

  computed_ingress_with_cidr_blocks = [
    {
      description = "Neptune from vpc_private_subnet_dev_general"
      from_port   = 8182
      to_port     = 8182
      protocol    = "tcp"
      cidr_blocks = module.vpc.private_subnets_cidr_blocks[local.idx_vpc_private_subnet_dev_general_a] # NOTE: restricted to vpc_private_subnet_dev_general
    },
    {
      description = "Neptune from services-api-1"
      from_port   = 8182
      to_port     = 8182
      protocol    = "tcp"
      cidr_blocks = "${local.ec2_instances.services_api_1.network_interfaces[0].private_ips[0]}/32" # NOTE: restricted to services-api-1 in vpc_private_subnet_mvpbeta_services
    }
  ]
  number_of_computed_ingress_with_cidr_blocks = 2

  computed_ingress_with_ipv6_cidr_blocks = [
    {
      description      = "Neptune (IPv6) from vpc_private_subnet_dev_general"
      from_port        = 8182
      to_port          = 8182
      protocol         = "tcp"
      ipv6_cidr_blocks = module.vpc.private_subnets_ipv6_cidr_blocks[local.idx_vpc_private_subnet_dev_general_a] # NOTE: restricted to vpc_private_subnet_dev_general (IPv6)
    },
    {
      description      = "Neptune (IPv6) from services-api-1"
      from_port        = 8182
      to_port          = 8182
      protocol         = "tcp"
      ipv6_cidr_blocks = "${module.ec2_instance["services_api_1"].ec2_private_ipv6}/128" # NOTE: restricted to services-api-1 in vpc_private_subnet_mvpbeta_services (IPv6)
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
    Name        = "sg_dev_neptune_cluster_a_new"
    Type        = "security_group"
    Environment = "mvpbeta"
  }
}
