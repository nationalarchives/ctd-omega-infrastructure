resource "aws_neptune_cluster" "ctd-omega-neptune-cluster" {
  cluster_identifier                  = "ctd-omega-neptune-cluster"
  engine                              = "neptune"
  engine_version                      = "1.0.4.0.neptune"
  neptune_subnet_group_name       = "neptune-subnet-group"
  backup_retention_period             = 5
  preferred_backup_window             = "07:00-09:00"
  skip_final_snapshot                 = true
  iam_database_authentication_enabled = true
  apply_immediately                   = true
  storage_encrypted               = true
  replication_source_identifier   = "neptune-cluster-source"
  snapshot_identifier             = "neptune-cluster-snapshot"
}

resource "aws_neptune_cluster_instance" "ctd-omega-writer-instance" {
  count              = 2
  cluster_identifier = aws_neptune_cluster.ctd-omega-neptune-cluster.id
  engine             = "neptune"
  instance_class     = "db.t3.medium"
  apply_immediately  = true
}