resource "aws_ebs_volume" "dev_workstation_1_home_volume" {
  availability_zone = "eu-west-2a"
  encrypted         = false
  iops              = 3000
  type              = "gp3"
  throughput        = 125
  size              = 200

  tags = {
    Name        = "home_dev1_new"
    Type        = "home_volume"
    Environment = "dev"
  }

  /* # Uncomment to enable this argument when the environment is active. 
  lifecycle {
        prevent_destroy = true
  }
*/
}

resource "aws_ebs_volume" "dev_workstation_2_home_volume" {
  availability_zone = "eu-west-2a"
  encrypted         = false
  iops              = 3000
  type              = "gp3"
  throughput        = 125
  size              = 200

  tags = {
    Name        = "home_dev2_new"
    Type        = "home_volume"
    Environment = "dev"
  }

  /* # Uncomment to enable this argument when the environment is active. 
  lifecycle {
        prevent_destroy = true
  }
*/
}

resource "aws_volume_attachment" "dev_workstation_1_home_volume_ebs_att" {
  device_name = "/dev/xvdb"
  volume_id   = aws_ebs_volume.dev_workstation_1_home_volume.id
  instance_id = aws_instance.dev_workstation_1.id
}

resource "aws_volume_attachment" "dev_workstation_2_home_volume_ebs_att" {
  device_name = "/dev/xvdb"
  volume_id   = aws_ebs_volume.dev_workstation_2_home_volume.id
  instance_id = aws_instance.dev_workstation_2.id
}

resource "aws_ebs_volume" "dev_mssql_server_1_data_volume" {
  availability_zone = "eu-west-2a"
  encrypted         = false
  iops              = 3000
  type              = "gp3"
  throughput        = 125
  size              = 150

/* # Uncomment to enable this argument when the environment is active. 
  lifecycle {
    prevent_destroy = true
  }
*/
  tags = {
    Name        = "data_mssql1_new"
    Type        = "mssql_data_volume"
    Environment = "dev"
  }
}

resource "aws_ebs_volume" "dev_mssql_server_1_log_volume" {
  availability_zone = "eu-west-2a"
  encrypted         = false
  iops              = 3000
  type              = "gp3"
  throughput        = 125
  size              = 75

/* # Uncomment to enable this argument when the environment is active. 
  lifecycle {
    prevent_destroy = true
  }
*/
  tags = {
    Name        = "log_mssql1_new"
    Type        = "mssql_log_volume"
    Environment = "dev"
  }
}

resource "aws_ebs_volume" "dev_mssql_server_1_backup_volume" {
  availability_zone = "eu-west-2a"
  encrypted         = false
  iops              = 3000
  type              = "gp3"
  throughput        = 125
  size              = 150

/* # Uncomment to enable this argument when the environment is active. 
  lifecycle {
    prevent_destroy = true
  }
*/

  tags = {
    Name        = "backup_mssql1_new"
    Type        = "mssql_backup_volume"
    Environment = "dev"
  }
}

resource "aws_volume_attachment" "dev_mssql_server_1_data_volume_ebs_att" {
  device_name = "/dev/xvdb"
  volume_id   = aws_ebs_volume.dev_mssql_server_1_data_volume.id
  instance_id = aws_instance.dev_mssql_server_1.id
}

resource "aws_volume_attachment" "dev_mssql_server_1_log_volume_ebs_att" {
  device_name = "/dev/xvdc"
  volume_id   = aws_ebs_volume.dev_mssql_server_1_log_volume.id
  instance_id = aws_instance.dev_mssql_server_1.id
}

resource "aws_volume_attachment" "dev_mssql_server_1_backup_volume_ebs_att" {
  device_name = "/dev/xvdd"
  volume_id   = aws_ebs_volume.dev_mssql_server_1_backup_volume.id
  instance_id = aws_instance.dev_mssql_server_1.id
}
