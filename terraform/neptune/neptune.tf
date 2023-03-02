resource "aws_neptune_cluster" "ctd-omega-neptune-dev-cluster-a" {
  cluster_identifier = "ctd-omega-neptune-dev-cluster-a"
  availability_zones = local.aws_azs

  neptune_subnet_group_name = "ctd-omega-neptune-dev-cluster-a-subnet-group"

  serverless_v2_scaling_configuration {
    min_capacity = 2.5
    max_capacity = 12
  }

  iam_database_authentication_enabled = true
  storage_encrypted                   = false

  preferred_backup_window = "00:00-04:00"
  backup_retention_period = 14 # days

  preferred_maintenance_window = "04:00-08:00"

  skip_final_snapshot       = false
  final_snapshot_identifier = "ctd-omega-neptune-dev-cluster-a-final-snapshot"
  copy_tags_to_snapshot     = true

  apply_immediately   = true  # TODO(AR) should be set to false for production
  deletion_protection = false # TODO(AR) should be set to true for production

  tags = {
    Name        = "ctd-omega-neptune-cluster-a"
    Type        = "database"
    DBType      = "neptune"
    Environment = "dev"
  }
}

resource "aws_neptune_cluster_instance" "ctd-omega-neptune-dev-cluster-a-instance" {
  identifier_prefix  = "ctd-omega-neptune-dev-cluster-a-instance"
  cluster_identifier = aws_neptune_cluster.ctd-omega-neptune-dev-cluster-a.id

  count          = 2
  instance_class = "db.serverless"

  publicly_accessible       = false
  neptune_subnet_group_name = "ctd-omega-neptune-dev-cluster-a-subnet-group"

  apply_immediately = true # TODO(AR) should be set to false for production

  tags = {
    Name        = id
    Type        = "database"
    DBType      = "neptune"
    Environment = "dev"
  }
}

resource "aws_neptune_subnet_group" "ctd-omega-neptune-dev-cluster-a-subnet-group" {
  name       = "main"
  subnet_ids = [local.vpc_private_subnet_dev_databases]

  tags = {
    Name        = "ctd-omega-neptune-dev-cluster-a-subnet-group"
    Type        = "neptune_subnet_group"
    Environment = "dev"
  }
}
