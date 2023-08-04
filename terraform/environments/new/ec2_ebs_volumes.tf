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

resource "aws_volume_attachment" "dev_workstation_1_home_volume_ebs_att" {
  device_name = "/dev/xvdb"
  volume_id   = aws_ebs_volume.dev_workstation_1_home_volume.id
  instance_id = aws_instance.dev_workstation_1.id
}
