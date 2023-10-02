data "aws_ami" "amazon_linux_2_20230719_x86_64" {
  most_recent = false

  owners = ["137112412989"] # Amazon Web Services

  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-5.10-hvm-2.0.20230719.0-x86_64-gp2"]
  }
}

module "dev_workstation_1_cloud_init" {
  source = "./cloud-init"

  fqdn                 = "dev-workstation-1.${local.private_omg_dns_domain}"
  separate_home_volume = "xvdb"

  additional_parts = [
    {
      content_type = "text/x-shellscript"
      filename = "01-install-puppet-agent.sh"
      content = templatefile("${local.scripts_dir}/install-puppet-agent.sh.tftpl", {
        s3_bucket_name_puppet_certificates = local.s3_bucket_name_puppet_certificates
        puppet_agent_fqdn     = "dev-workstation-1.${local.private_omg_dns_domain}"
        puppet_server_fqdn    = "puppet-server-1.${local.private_omg_dns_domain}"
        ca_certificate_pem_filename = basename(module.puppet_server_1_puppet_server_certificate_authority.certificate_pem_exported_filename)
        certificate_pem_filename = basename(module.dev_workstation_1_puppet_agent_certificate.certificate_pem_exported_filename)
        public_key_pem_filename  = basename(module.dev_workstation_1_puppet_agent_certificate.public_key_pem_exported_filename)
        private_key_pem_filename = basename(module.dev_workstation_1_puppet_agent_certificate.private_key_pem_exported_filename)
      })
    }
  ]
}

# Dev Workstation for Adam Retter
resource "aws_instance" "dev_workstation_1" {
  ami                         = data.aws_ami.amazon_linux_2_20230719_x86_64.id
  instance_type               = local.instance_type_dev_workstation
  key_name                    = data.aws_key_pair.omega_admin_key_pair.key_name
  user_data                   = module.dev_workstation_1_cloud_init.rendered
  user_data_replace_on_change = false

  iam_instance_profile = aws_iam_instance_profile.dev_workstation_1_ec2_iam_instance_profile.id

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
      Name        = "root_dev-workstation-1_new"
      Type        = "primary_volume"
      Environment = "dev"
    }
  }

  ebs_block_device {
    delete_on_termination = false
    encrypted             = false
    volume_type           = "gp3"
    iops                  = 3000
    throughput            = 125
    volume_size           = 200

    device_name = "/dev/xvdb"

    tags = {
      Name        = "home_dev-workstation-1_new"
      Type        = "home_volume"
      Environment = "dev"
    }
  }

  tags = {
    Name                      = "dev-workstation-1_new"
    Type                      = "dev_workstation"
    Environment               = "dev"
    scheduler_mon_fri_dev_ec2 = "true"
  }
}


module "dev_workstation_2_cloud_init" {
  source = "./cloud-init"

  fqdn                 = "dev-workstation-2.${local.private_omg_dns_domain}"
  separate_home_volume = "xvdb"
}

# Dev Workstation for Rob Walpole
resource "aws_instance" "dev_workstation_2" {
  ami                         = data.aws_ami.amazon_linux_2_20230719_x86_64.id
  instance_type               = local.instance_type_dev_workstation
  key_name                    = data.aws_key_pair.omega_admin_key_pair.key_name
  user_data                   = module.dev_workstation_2_cloud_init.rendered
  user_data_replace_on_change = false

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  monitoring = false

  network_interface {
    network_interface_id = aws_network_interface.dev_workstation_2_private_interface.id
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
      Name        = "root_dev-workstation-2_new"
      Type        = "primary_volume"
      Environment = "dev"
    }
  }

  ebs_block_device {
    delete_on_termination = false
    encrypted             = false
    volume_type           = "gp3"
    iops                  = 3000
    throughput            = 125
    volume_size           = 200

    device_name = "/dev/xvdb"

    tags = {
      Name        = "home_dev-workstation-2_new"
      Type        = "home_volume"
      Environment = "dev"
    }
  }

  tags = {
    Name                      = "dev-workstation-2_new"
    Type                      = "dev_workstation"
    Environment               = "dev"
    scheduler_mon_fri_dev_ec2 = "true"
  }
}

module "dev_mssql_server_1_cloud_init" {
  source = "./cloud-init"

  fqdn = "dev-mssql-server-1.${local.private_omg_dns_domain}"
  additional_volumes = [
    {
      volume      = "xvdb",
      mount_point = "/mssql/data"
    },
    {
      volume      = "xvdc",
      mount_point = "/mssql/log"
    },
    {
      volume      = "xvdd",
      mount_point = "/mssql/backup"
    }
  ]
}

resource "aws_instance" "dev_mssql_server_1" {
  ami           = data.aws_ami.amazon_linux_2_20230719_x86_64.id
  instance_type = local.instance_type_dev_mssql_server
  # m5a.2xlarge == $0.4 / hour == 8 vCPU == 32GiB RAM
  # r5.xlarge == $0.296 / hour == 4 vCPU == 32GiB RAM

  key_name = data.aws_key_pair.omega_admin_key_pair.key_name

  user_data                   = module.dev_mssql_server_1_cloud_init.rendered
  user_data_replace_on_change = false

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  monitoring = true

  network_interface {
    network_interface_id = aws_network_interface.dev_mssql_server_1_database_interface.id
    device_index         = 0
  }

  root_block_device {
    delete_on_termination = false
    encrypted             = false
    volume_type           = "gp3"
    iops                  = 3000
    throughput            = 125 # MiB/s
    volume_size           = 60  # GiB

    tags = {
      Name        = "root_dev-mssql-server-1_new"
      Type        = "primary_volume"
      Environment = "dev"
    }
  }

  # dev_mssql_server_1_data_volume
  ebs_block_device {
    delete_on_termination = false
    encrypted             = false
    volume_type           = "gp3"
    iops                  = 3000
    throughput            = 125
    volume_size           = 150

    device_name = "/dev/xvdb"

    tags = {
      Name        = "data_dev-mssql-server-1_new"
      Type        = "mssql_server_data_volume"
      Environment = "dev"
    }
  }

  # dev_mssql_server_1_log_volume
  ebs_block_device {
    delete_on_termination = false
    encrypted             = false
    volume_type           = "gp3"
    iops                  = 3000
    throughput            = 125
    volume_size           = 75

    device_name = "/dev/xvdc"

    tags = {
      Name        = "log_dev-mssql-server-1_new"
      Type        = "mssql_server_log_volume"
      Environment = "dev"
    }
  }

  # dev_mssql_server_1_backup_volume
  ebs_block_device {
    delete_on_termination = false
    encrypted             = false
    volume_type           = "gp3"
    iops                  = 3000
    throughput            = 125
    volume_size           = 150

    device_name = "/dev/xvdd"

    tags = {
      Name        = "backup_dev-mssql-server-1_new"
      Type        = "mssql_server_backup_volume"
      Environment = "dev"
    }
  }

  tags = {
    Name                      = "dev-mssql-server-1_new"
    Type                      = "dev_mssql_server"
    Environment               = "dev"
    scheduler_mon_fri_dev_ec2 = "true"
  }
}

module "puppet_server_1_cloud_init" {
  source = "./cloud-init"

  fqdn                 = "puppet-server-1.${local.private_omg_dns_domain}"

  additional_parts = [
    {
      content_type = "text/x-shellscript"
      filename = "01-install-puppet-server.sh"
      content = templatefile("${local.scripts_dir}/install-puppet-server.sh.tftpl", {
        s3_bucket_name_puppet_certificates = local.s3_bucket_name_puppet_certificates
        puppet_server_fqdn          = "puppet-server-1.${local.private_omg_dns_domain}"
        ca_certificate_pem_filename = basename(module.puppet_server_1_puppet_server_certificate_authority.certificate_pem_exported_filename)
        ca_private_key_pem_filename = basename(module.puppet_server_1_puppet_server_certificate_authority.private_key_pem_exported_filename)
        ca_public_key_pem_filename  = basename(module.puppet_server_1_puppet_server_certificate_authority.public_key_pem_exported_filename)
        puppet_control_repo_url = "https://github.com/nationalarchives/ctd-omega-puppet.git"
        puppet_environment      = "production"
        puppet_agents           = [
          {
            fqdn = "puppet-server-1.${local.private_omg_dns_domain}"
            certificate_pem_filename = basename(module.puppet_server_1_puppet_agent_certificate.certificate_pem_exported_filename)
            public_key_pem_filename  = basename(module.puppet_server_1_puppet_agent_certificate.public_key_pem_exported_filename)
            private_key_pem_filename = basename(module.puppet_server_1_puppet_agent_certificate.private_key_pem_exported_filename)
          },
          {
            fqdn = "dev-workstation-1.${local.private_omg_dns_domain}"
            certificate_pem_filename  = basename(module.dev_workstation_1_puppet_agent_certificate.certificate_pem_exported_filename)
            public_key_pem_filename   = basename(module.dev_workstation_1_puppet_agent_certificate.public_key_pem_exported_filename)
            private_key_pem_filename  = basename(module.dev_workstation_1_puppet_agent_certificate.private_key_pem_exported_filename)
          }
        ]
      })
    }
  ]
}

# Puppet Server
resource "aws_instance" "puppet_server_1" {
  ami                         = data.aws_ami.amazon_linux_2_20230719_x86_64.id
  instance_type               = local.instance_type_puppet_server
  key_name                    = data.aws_key_pair.omega_admin_key_pair.key_name
  user_data                   = module.puppet_server_1_cloud_init.rendered
  user_data_replace_on_change = false

  iam_instance_profile = aws_iam_instance_profile.puppet_server_iam_instance_profile.id

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  monitoring = false

  network_interface {
    network_interface_id = aws_network_interface.puppet_server_1_private_interface.id
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
      Name        = "root_puppet-server-1_new"
      Type        = "primary_volume"
      Environment = "dev"
    }
  }

  tags = {
    Name                      = "puppet-server-1_new"
    Type                      = "puppet_server"
    Environment               = "mvpbeta"
    scheduler_mon_fri_dev_ec2 = "false"
  }
}
