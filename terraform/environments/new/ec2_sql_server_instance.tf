# NOTE(AR) This is not in `ec2.tf` as we are not yet using our 'ec2_instance' module for the SQL Server as it has a problem with specifiying additional volumes, see `ec2_instance/locals.tf`, and:  see https://github.com/hashicorp/terraform/issues/33259, this makes the configuration below much more complex than it could be!
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

  additional_parts = [
    {
      content_type = "text/x-shellscript"
      filename     = "01-install-puppet-agent.sh"
      content = templatefile("${path.root}/${path.module}/ec2_instance/scripts/install-puppet-agent.sh.tftpl", {
        puppet_version                     = 8
        s3_bucket_name_puppet_certificates = aws_s3_bucket.puppet_certificates.id
        puppet_agent_fqdn                  = "dev-mssql-server-1.${local.private_omg_dns_domain}"
        puppet_server_fqdn                 = "${local.ec2_puppet_server_instances.puppet_server_1.hostname}.${local.private_omg_dns_domain}"
        ca_certificate_pem_filename        = "${local.ec2_puppet_server_instances.puppet_server_1.hostname}.${local.private_omg_dns_domain}-ca.crt.pem"
        certificate_pem_filename           = basename(module.dev_mssql_server_1_puppet_agent_certificate.certificate_pem_exported_filename)
        public_key_pem_filename            = basename(module.dev_mssql_server_1_puppet_agent_certificate.public_key_pem_exported_filename)
        private_key_pem_filename           = basename(module.dev_mssql_server_1_puppet_agent_certificate.private_key_pem_exported_filename)
      })
    }
  ]
}

resource "aws_instance" "dev_mssql_server_1" {
  ami           = local.aws_ami.linux2_x86_64.id
  instance_type = local.instance_type_dev_mssql_server

  key_name = data.aws_key_pair.omega_admin_key_pair.key_name

  user_data                   = module.dev_mssql_server_1_cloud_init.rendered
  user_data_replace_on_change = false

  iam_instance_profile = aws_iam_instance_profile.dev_mssql_server_1_ec2_iam_instance_profile.id

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

resource "aws_network_interface" "dev_mssql_server_1_database_interface" {
  description = "Private Dev Database Subnet interface for Dev MS SQL Server 1"
  subnet_id   = module.vpc.database_subnets[0]
  private_ips = ["10.129.203.4"]

  security_groups = [
    module.dev_database_security_group.security_group_id
  ]

  tags = {
    Name        = "eth0_dev-mssql-server1"
    Type        = "primary_network_interface"
    Network     = "dev_database"
    Environment = "dev"
  }
}

data "aws_network_interface" "dev_mssql_server_1_database_interface" {
  id = aws_network_interface.dev_mssql_server_1_database_interface.id
}

module "dev_mssql_server_1_dns" {
  source = "./host_dns"

  fqdn = "dev-mssql-server-1.${local.private_omg_dns_domain}"

  zone_id = aws_route53_zone.omega_private_omg_dns.zone_id
  ipv4    = {
    addresses       = data.aws_network_interface.dev_mssql_server_1_database_interface.private_ips
    reverse_zone_id = aws_route53_zone.omega_private_ipv4_omg_reverse_dns.zone_id
  }
  ipv6    = {
    addresses       = data.aws_network_interface.dev_mssql_server_1_database_interface.ipv6_addresses
    reverse_zone_id = aws_route53_zone.omega_private_ipv6_omg_reverse_dns.zone_id
  }
}

module "dev_mssql_server_1_puppet_agent_certificate" {
  source = "./certificate"

  id = "dev-mssql-server-1.${local.private_omg_dns_domain}"

  is_ca_certificate = false

  subject = merge({ common_name = "dev-mssql-server-1.${local.private_omg_dns_domain}" }, local.default_certificate_subject)

  dns_names = [
    "dev-mssql-server-1.${local.private_omg_dns_domain}"
  ]

  expiry_days = 5 * 365  # 5 years

  ca = {
    private_key_pem = module.ec2_puppet_server_instance["puppet_server_1"].puppet_ca_private_key_pem
    certificate_pem = module.ec2_puppet_server_instance["puppet_server_1"].puppet_ca_certificate_pem
  }

  export_path = "../../../ctd-omega-infrastructure-certificates/exported"
}

resource "aws_s3_object" "dev_mssql_server_1_puppet_agent_certificate" {
    bucket = aws_s3_bucket.puppet_certificates.id
    key = "certificates/public/dev-mssql-server-1.${local.private_omg_dns_domain}.crt.pem"
    content = module.dev_mssql_server_1_puppet_agent_certificate.certificate_pem
    content_type = "application/x-pem-file"
    checksum_algorithm = "SHA256"
    tags = {
        Type        = "certificate"
        Environment = "management"
    }
}

resource "aws_s3_object" "dev_mssql_server_1_puppet_agent_public_key" {
    bucket = aws_s3_bucket.puppet_certificates.id
    key = "certificates/public/dev-mssql-server-1.${local.private_omg_dns_domain}.public.key.pem"
    content = module.dev_mssql_server_1_puppet_agent_certificate.public_key_pem
    content_type = "application/x-pem-file"
    checksum_algorithm = "SHA256"
    tags = {
        Type        = "certificate"
        Environment = "management"
    }
}

resource "aws_s3_object" "dev_mssql_server_1_puppet_agent_private_key" {
    bucket = aws_s3_bucket.puppet_certificates.id
    key = "certificates/private/dev-mssql-server-1.${local.private_omg_dns_domain}.private.key.pem"
    content = module.dev_mssql_server_1_puppet_agent_certificate.private_key_pem
    content_type = "application/x-pem-file"
    checksum_algorithm = "SHA256"
    tags = {
        Type        = "certificate"
        Environment = "management"
    }
}

# Puppet Agent EC2 Instance Profile
resource "aws_iam_instance_profile" "dev_mssql_server_1_ec2_iam_instance_profile" {
  name = "dev-mssql-server-1_ec2"
  path = "/puppet/"

  role = aws_iam_role.dev_mssql_server_1_ec2_iam_role.name

  tags = {
    Environment = "management"
  }
}

resource "aws_iam_role" "dev_mssql_server_1_ec2_iam_role" {
  name = "dev-mssql-server-1_ec2_role"
  path = "/puppet/"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role_policy.json
  managed_policy_arns = concat(
    [
      aws_iam_policy.scratch_space_backup_read_policy.arn,
      aws_iam_policy.puppet_ca_public_policy.arn,
      aws_iam_policy.puppet_certificates_public_policy.arn,
      aws_iam_policy.dev_mssql_server_1_puppet_certificates_private_puppet_agent_policy.arn
    ]
  )
}

resource "aws_iam_policy" "dev_mssql_server_1_puppet_certificates_private_puppet_agent_policy" {
  name = "puppet_certificates_private_dev-mssql-server-1_policy"
  path = "/puppet/"
  policy = data.aws_iam_policy_document.dev_mssql_server_1_puppet_certificates_private_puppet_agent_policy.json
}

data "aws_iam_policy_document" "dev_mssql_server_1_puppet_certificates_private_puppet_agent_policy" {
  statement {
    sid = "AllowReadPuppetCertificatesPrivateDevMssqlServer1"

    actions = [
        "s3:GetObject",
        "s3:ListBucket"
    ]

    resources = [
      "${aws_s3_bucket.puppet_certificates.arn}/certificates/private/dev-mssql-server-1.${local.private_omg_dns_domain}.*",
      "${aws_s3_bucket.puppet_certificates.arn}"
    ]
  }
}

# MS SQL Server SA Password
resource "random_password" "dev_mssql_server_1_sa_password" {
  length           = 16
  lower            = true
  upper            = true
  numeric          = true
  special          = true
  override_special = "@#$%"
}

resource "aws_secretsmanager_secret" "dev_mssql_server_1_sa_password_secret" {
  # NOTE(AR) the naming convention involving the `==` separators are required for use by this Puppet/Hiera lookup function - https://github.com/krux/hiera-aws-secretsmanager#character-translation-in-secret-names
  name = "secrets/production/dev_mssql_server_1==sa==password"
}

resource "aws_secretsmanager_secret_version" "dev_mssql_server_1_sa_password_secret_version" {
  secret_id     = aws_secretsmanager_secret.dev_mssql_server_1_sa_password_secret.id
  # NOTE(AR) the additional quotes in the secret string are required for use by this Puppet/Hiera lookup function - https://github.com/krux/hiera-aws-secretsmanager#storing-secrets-as-json
  secret_string = "\"${random_password.dev_mssql_server_1_sa_password.result}\""
}
