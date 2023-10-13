module "ec2_instance_cloud_init" {
  source = "../cloud-init"

  fqdn                 = var.fqdn
  separate_home_volume = try(local.home_block_device.device_name, null)

  # If this has puppet settings, add the Puppet cloud-init part
  additional_parts = var.puppet == null ? [] : [ local.puppet_cloud_init_part ]
}

resource "aws_instance" "ec2_instance" {
  ami                         = var.ami
  instance_type               = var.instance_type
  key_name                    = var.key_name
  user_data                   = module.ec2_instance_cloud_init.rendered
  user_data_replace_on_change = var.user_data_replace_on_change

  iam_instance_profile = local.iam_instance_profile

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  monitoring = false

  network_interface {
    network_interface_id = aws_network_interface.ec2_instance_private_interface.id
    device_index         = 0
  }

  root_block_device {
    delete_on_termination = local.root_block_device["delete_on_termination"]
    encrypted             = local.root_block_device["encrypted"]
    volume_type           = local.root_block_device["volume_type"]
    iops                  = local.root_block_device["iops"]
    throughput            = local.root_block_device["throughput"]
    volume_size           = local.root_block_device["volume_size"]

    tags = local.root_block_device["tags"]
  }

  dynamic "ebs_block_device" {
    for_each = local.additional_block_devices
    content {
        delete_on_termination = ebs_block_device.value["delete_on_termination"]
        encrypted             = ebs_block_device.value["encrypted"]
        volume_type           = ebs_block_device.value["volume_type"]
        iops                  = ebs_block_device.value["iops"]
        throughput            = ebs_block_device.value["throughput"]
        volume_size           = ebs_block_device.value["volume_size"]

        device_name = "/dev/${ebs_block_device.value["device_name"]}"

        tags = ebs_block_device.value["tags"]
    }
  }

  tags = merge({ Name = "${local.hostname}_new" }, var.tags)
}

resource "aws_network_interface" "ec2_instance_private_interface" {
  description = "Network Interface ${local.hostname}"
  subnet_id   = var.subnet_id
  private_ips = var.private_ips

  security_groups = var.security_groups

  tags = {
    Name        = "eth0_${local.hostname}"
    Type        = "primary_network_interface"
    Environment = var.tags["Environment"]
  }
}

data "aws_network_interface" "ec2_instance_private_interface" {
  id = aws_network_interface.ec2_instance_private_interface.id
}

# Setup DNS
module "ec2_instance_dns" {
  source = "../host_dns"

  count = var.dns == null ? 0 : 1

  fqdn = var.fqdn

  zone_id = var.dns.zone_id
  ipv4    = {
    addresses       = data.aws_network_interface.ec2_instance_private_interface.private_ips
    reverse_zone_id = var.dns.reverse_ipv4_zone_id
  }
  ipv6    = {
    addresses       = data.aws_network_interface.ec2_instance_private_interface.ipv6_addresses
    reverse_zone_id = var.dns.reverse_ipv6_zone_id
  }
}

# Create Puppet CA Certificates and keys (if needed)
module "puppet_certificate_authority" {
  source = "../certificate"

  count = local.generate_ca ? 1 : 0  # NOTE(AR) Only run if we are not provided with CA details

  id = local.puppet_server_fqdn

  is_ca_certificate = true

  subject = merge({ common_name = "Puppet CA: ${local.puppet_server_fqdn}" },  try(var.puppet.server.ca.subject, {}))

  expiry_days = 5 * 365  # 5 years
}

# Generate Puppet Agent Certificates and keys (if needed)
module "puppet_agent_certificate" {
  source = "../certificate"

  count =  local.generate_certificate ? 1 : 0  # NOTE(AR) Only run if we are not provided with certificate details

  id = var.fqdn

  is_ca_certificate = false

  subject = merge({ common_name = var.fqdn }, try(var.puppet.certificates.self.subject, {}))

  dns_names = [
    var.fqdn
  ]

  expiry_days = 5 * 365  # 5 years

  ca = {
    private_key_pem = local.generate_ca ? module.puppet_certificate_authority[0].private_key_pem : var.puppet.certificates.ca_private_key_pem
    certificate_pem = local.generate_ca ? module.puppet_certificate_authority[0].certificate_pem : var.puppet.certificates.ca_certificate_pem
  }
}

# Upload Puppet CA Certificates and keys (if needed) into S3 bucket
resource "aws_s3_object" "puppet_certificate_authority_certificate" {
    count = local.generate_ca ? 1 : 0  # NOTE(AR) Only run if we are not provided with CA details

    bucket = var.puppet.certificates.s3_bucket_name
    key = "ca/public/${local.ca_certificate_filename}"
    content = module.puppet_certificate_authority[0].certificate_pem
    content_type = "application/x-pem-file"
    checksum_algorithm = "SHA256"
    tags = {
        Type        = "certificate"
        Environment = "management"
    }
}

resource "aws_s3_object" "puppet_certificate_authority_public_key" {
    count = local.generate_ca ? 1 : 0  # NOTE(AR) Only run if we are not provided with CA details

    bucket = var.puppet.certificates.s3_bucket_name
    key = "ca/public/${local.ca_public_key_filename}"
    content = module.puppet_certificate_authority[0].public_key_pem
    content_type = "application/x-pem-file"
    checksum_algorithm = "SHA256"
    tags = {
        Type        = "certificate"
        Environment = "management"
    }
}

resource "aws_s3_object" "puppet_certificate_authority_private_key" {
    count = local.generate_ca ? 1 : 0  # NOTE(AR) Only run if we are not provided with CA details

    bucket = var.puppet.certificates.s3_bucket_name
    key = "ca/private/${local.ca_private_key_filename}"
    content = module.puppet_certificate_authority[0].private_key_pem
    content_type = "application/x-pem-file"
    checksum_algorithm = "SHA256"
    tags = {
        Type        = "certificate"
        Environment = "management"
    }
}

# Upload Puppet Agent Certificates and keys (if needed) into S3 bucket
resource "aws_s3_object" "puppet_agent_certificate" {
    count = local.generate_certificate ? 1 : 0  # NOTE(AR) Only run if we are not provided with CA details

    bucket = var.puppet.certificates.s3_bucket_name
    key = "certificates/public/${local.certificate_filename}"
    content = module.puppet_agent_certificate[0].certificate_pem
    content_type = "application/x-pem-file"
    checksum_algorithm = "SHA256"
    tags = {
        Type        = "certificate"
        Environment = "management"
    }
}

resource "aws_s3_object" "puppet_agent_public_key" {
    count = local.generate_certificate ? 1 : 0  # NOTE(AR) Only run if we are not provided with CA details

    bucket = var.puppet.certificates.s3_bucket_name
    key = "certificates/public/${local.public_key_filename}"
    content = module.puppet_agent_certificate[0].public_key_pem
    content_type = "application/x-pem-file"
    checksum_algorithm = "SHA256"
    tags = {
        Type        = "certificate"
        Environment = "management"
    }
}

resource "aws_s3_object" "puppet_agent_private_key" {
    count = local.generate_certificate ? 1 : 0  # NOTE(AR) Only run if we are not provided with CA details

    bucket = var.puppet.certificates.s3_bucket_name
    key = "certificates/private/${local.private_key_filename}"
    content = module.puppet_agent_certificate[0].private_key_pem
    content_type = "application/x-pem-file"
    checksum_algorithm = "SHA256"
    tags = {
        Type        = "certificate"
        Environment = "management"
    }
}

# Puppet Server EC2 Instance Profile
resource "aws_iam_instance_profile" "puppet_server_ec2_iam_instance_profile" {
  count = local.generate_server_ec2_iam_instance_profile ? 1 : 0  # NOTE(AR) Only run if we are generating an EC2 instance profile for a Puppet Server

  name = "${local.hostname}_ec2"
  path = "/puppet/"

  role = aws_iam_role.puppet_server_ec2_iam_role[0].name

  tags = {
    Environment = "management"
  }
}

resource "aws_iam_role" "puppet_server_ec2_iam_role" {
  count = local.generate_server_ec2_iam_instance_profile ? 1 : 0  # NOTE(AR) Only run if we are generating an EC2 instance profile for a Puppet Server

  name = "${local.hostname}_ec2_role"
  path = "/puppet/"
  assume_role_policy = data.aws_iam_policy_document.puppet_ec2_assume_role_policy.json
  managed_policy_arns = concat(
    [
      var.puppet.certificates.s3_bucket_ca_public_policy,
      var.puppet.certificates.s3_bucket_ca_private_policy,
      var.puppet.certificates.s3_bucket_certificates_public_policy,
      aws_iam_policy.puppet_certificates_private_puppet_server_policy[0].arn
    ],
    var.additional_iam_policies
  )
}

# Puppet Server (agent) Private key
resource "aws_iam_policy" "puppet_certificates_private_puppet_server_policy" {
    count = local.generate_server_ec2_iam_instance_profile ? 1 : 0  # NOTE(AR) Only run if we are generating an EC2 instance profile for a Puppet Server

    name = "puppet_certificates_private_${local.hostname}_policy"
    path = "/puppet/"
    policy = data.aws_iam_policy_document.puppet_certificates_private_puppet_server_policy[0].json
}

data "aws_iam_policy_document" "puppet_certificates_private_puppet_server_policy" {
  count = local.generate_server_ec2_iam_instance_profile ? 1 : 0  # NOTE(AR) Only run if we are generating an EC2 instance profile for a Puppet Server

  statement {
    sid = "AllowReadPuppetCertificatesPrivate${local.hostname_title}"

    actions = [
        "s3:GetObject",
        "s3:ListBucket"
    ]

    resources = [
      "${local.s3_bucket_arn_puppet_certificates}/certificates/private/${var.fqdn}.*",
      "${local.s3_bucket_arn_puppet_certificates}"
    ]
  }
}

# Puppet Agent EC2 Instance Profile
resource "aws_iam_instance_profile" "puppet_agent_ec2_iam_instance_profile" {
  count = local.generate_agent_ec2_iam_instance_profile ? 1 : 0  # NOTE(AR) Only run if we are generating an EC2 instance profile for a Puppet Agent

  name = "${local.hostname}_ec2"
  path = "/puppet/"

  role = aws_iam_role.puppet_agent_ec2_iam_role[0].name

  tags = {
    Environment = "management"
  }
}

resource "aws_iam_role" "puppet_agent_ec2_iam_role" {
  count = local.generate_agent_ec2_iam_instance_profile ? 1 : 0  # NOTE(AR) Only run if we are generating an EC2 instance profile for a Puppet Agent

  name = "${local.hostname}_ec2_role"
  path = "/puppet/"
  assume_role_policy = data.aws_iam_policy_document.puppet_ec2_assume_role_policy.json
  managed_policy_arns = concat(
    [
      var.puppet.certificates.s3_bucket_ca_public_policy,
      var.puppet.certificates.s3_bucket_certificates_public_policy,
      aws_iam_policy.puppet_certificates_private_puppet_agent_policy[0].arn
    ],
    var.additional_iam_policies
  )
}

# Puppet Agent Private key
resource "aws_iam_policy" "puppet_certificates_private_puppet_agent_policy" {
  count = local.generate_agent_ec2_iam_instance_profile ? 1 : 0  # NOTE(AR) Only run if we are generating an EC2 instance profile for a Puppet Agent

  name = "puppet_certificates_private_${local.hostname}_policy"
  path = "/puppet/"
  policy = data.aws_iam_policy_document.puppet_certificates_private_puppet_agent_policy[0].json
}

data "aws_iam_policy_document" "puppet_certificates_private_puppet_agent_policy" {
  count = local.generate_agent_ec2_iam_instance_profile ? 1 : 0  # NOTE(AR) Only run if we are generating an EC2 instance profile for a Puppet Agent

  statement {
    sid = "AllowReadPuppetCertificatesPrivate${local.hostname_title}"

    actions = [
        "s3:GetObject",
        "s3:ListBucket"
    ]

    resources = [
      "${local.s3_bucket_arn_puppet_certificates}/certificates/private/${var.fqdn}.*",
      "${local.s3_bucket_arn_puppet_certificates}"
    ]
  }
}

# Policy to allow an EC2 instance to assume a role
data "aws_iam_policy_document" "puppet_ec2_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    principals {
      type = "AWS"

      # TODO(AR) I am not sure why the machines need to be able to assume their own machines role for use with Neptune via `awscurl`... perhaps create a different role that can be assumed from the EC2 instance?
      identifiers = [
        "arn:aws:sts::320289993971:assumed-role/dev-workstation-1_ec2_role/i-0e6927f6331a8a860",
        "arn:aws:sts::320289993971:assumed-role/dev-workstation-2_ec2_role/i-04c94c2c368a1b134",
        "arn:aws:sts::320289993971:assumed-role/dev-workstation-3_ec2_role/i-01e50911a31dd28f4"
      ]
    }
  }
}