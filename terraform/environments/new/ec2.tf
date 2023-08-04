data "aws_ami" "amazon_linux_2_20230719_x86_64" {
  most_recent = false

  owners = ["137112412989"] # Amazon Web Services

  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-5.10-hvm-2.0.20230719.0-x86_64-gp2"]
  }
}

# Dev Workstation for Adam Retter
resource "aws_instance" "dev_workstation_1" {
  ami                         = data.aws_ami.amazon_linux_2_20230719_x86_64.id
  instance_type               = local.instance_type_dev_workstation
  key_name                    = data.aws_key_pair.omega_admin_key_pair.key_name
  user_data                   = data.cloudinit_config.dev_workstation_new.rendered
  user_data_replace_on_change = false

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  monitoring = false

  network_interface {
    network_interface_id = aws_network_interface.dev_workstation_1_private_interface.id
    device_index         = 0
  }

  root_block_device {
    delete_on_termination = false
    encrypted             = false
    volume_type           = "gp3"
    iops                  = 3000
    throughput            = 125 # MiB/s
    volume_size           = 20  # GiB

    tags = {
      Name        = "root_dev1_new"
      Type        = "primary_volume"
      Environment = "dev"
    }
  }

  tags = {
    Name                      = "dev1_new"
    Type                      = "dev_workstation"
    Environment               = "dev"
    scheduler_mon_fri_dev_ec2 = "true"
  }
}
