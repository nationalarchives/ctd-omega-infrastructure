module "ec2_puppet_server_instance" {
  source = "./ec2_instance"

  for_each = local.ec2_puppet_server_instances

  fqdn = "${each.value.hostname}.${local.private_omg_dns_domain}"

  ami           = each.value.ami
  instance_type = each.value.instance_type
  key_name      = data.aws_key_pair.omega_admin_key_pair.key_name

  security_groups = each.value.security_groups

  # Puppet Server settings
  puppet = {
    server = {
      control_repo_url = local.puppet_control_repo_url
      environment = "production"
    }
    certificates = {
      s3_bucket_name = aws_s3_bucket.puppet_certificates.id
      s3_bucket_certificates_public_policy = aws_iam_policy.puppet_certificates_public_policy.arn
      s3_bucket_ca_public_policy = aws_iam_policy.puppet_ca_public_policy.arn
      s3_bucket_ca_private_policy = aws_iam_policy.puppet_ca_private_policy.arn
    }
  }

  root_block_device = lookup(each.value, "root_block_device", { volume_size = 20 })   # default: 20 GiB
  home_block_device = lookup(each.value, "home_block_device", null)
  secondary_block_devices = lookup(each.value, "secondary_block_devices", [])

  subnet_id   = each.value.subnet_id
  private_ips = [each.value.ipv4_address]
  dns = {
    zone_id = aws_route53_zone.omega_private_omg_dns.zone_id
    reverse_ipv4_zone_id = aws_route53_zone.omega_private_ipv4_omg_reverse_dns.zone_id
    reverse_ipv6_zone_id = aws_route53_zone.omega_private_ipv6_omg_reverse_dns.zone_id
  }

  tags = each.value.tags
}

## Create EC2 instances from `local.ec2_instances`
module "ec2_instance" {
  source = "./ec2_instance"

  for_each = local.ec2_instances

  fqdn = "${each.value.hostname}.${local.private_omg_dns_domain}"

  ami           = each.value.ami
  instance_type = each.value.instance_type
  key_name      = data.aws_key_pair.omega_admin_key_pair.key_name

  security_groups = each.value.security_groups

  # Puppet Agent settings
  puppet = each.value.puppet == null ? null : {
    server_fqdn = "${local.ec2_puppet_server_instances.puppet_server_1.hostname}.${local.private_omg_dns_domain}"
    certificates = {
      s3_bucket_name = aws_s3_bucket.puppet_certificates.id
      s3_bucket_certificates_public_policy = aws_iam_policy.puppet_certificates_public_policy.arn
      s3_bucket_ca_public_policy = aws_iam_policy.puppet_ca_public_policy.arn
      s3_bucket_ca_private_policy = aws_iam_policy.puppet_ca_private_policy.arn
      subject = local.default_certificate_subject
      ca_private_key_pem = module.ec2_puppet_server_instance["puppet_server_1"].puppet_ca_private_key_pem
      ca_certificate_pem = module.ec2_puppet_server_instance["puppet_server_1"].puppet_ca_certificate_pem
    }
  }

  root_block_device = lookup(each.value, "root_block_device", { volume_size = 20 })   # default: 20 GiB
  home_block_device = lookup(each.value, "home_block_device", null)
  secondary_block_devices = lookup(each.value, "secondary_block_devices", [])

  # TODO(AR) additional data volumes

  subnet_id   = each.value.subnet_id
  private_ips = [each.value.ipv4_address]
  dns = {
    zone_id = aws_route53_zone.omega_private_omg_dns.zone_id
    reverse_ipv4_zone_id = aws_route53_zone.omega_private_ipv4_omg_reverse_dns.zone_id
    reverse_ipv6_zone_id = aws_route53_zone.omega_private_ipv6_omg_reverse_dns.zone_id
  }

  tags = each.value.tags
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
  ami           = local.aws_ami.linux2_x86_64.id
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

# data "aws_iam_policy_document" "ec2_assume_role_policy" {
#   statement {
#     actions = ["sts:AssumeRole"]

#     principals {
#       type        = "Service"
#       identifiers = ["ec2.amazonaws.com"]
#     }
#   }
# }