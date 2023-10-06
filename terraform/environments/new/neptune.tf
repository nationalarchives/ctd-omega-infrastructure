resource "aws_neptune_cluster" "dev_neptune_cluster_a" {
  cluster_identifier = local.neptune_dev_cluster_a.id
  availability_zones = local.aws_azs

  neptune_subnet_group_name = local.neptune_dev_cluster_a.subnet_group_name

  engine = "neptune"
  engine_version = "1.2.1.0"
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
  name = local.neptune_dev_cluster_a.id
  family = "neptune1.2"
}

resource "aws_neptune_cluster_instance" "dev_neptune_cluster_a_instance" {
  cluster_identifier = aws_neptune_cluster.dev_neptune_cluster_a.id

  identifier_prefix  = local.neptune_dev_cluster_a.instance_prefix
  
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
  name = local.neptune_dev_cluster_a.instance_prefix
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
