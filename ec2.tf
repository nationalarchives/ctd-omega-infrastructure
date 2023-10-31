module "ec2_puppet_server_instance" {
  source = "./ec2_instance"

  for_each = local.ec2_puppet_server_instances

  fqdn = "${each.value.hostname}.${local.private_omg_dns_domain}"

  ami           = each.value.ami
  instance_type = each.value.instance_type
  key_name      = data.aws_key_pair.omega_admin_key_pair.key_name

  additional_iam_policies = lookup(each.value, "additional_iam_policies", [])

  # Puppet Server settings
  puppet = {
    version = each.value.puppet.version
    server = {
      control_repo_url = local.puppet_control_repo_url
      environment      = "production"
    }
    certificates = {
      s3_bucket_name                       = aws_s3_bucket.puppet_certificates.id
      s3_bucket_certificates_public_policy = aws_iam_policy.puppet_certificates_public_policy.arn
      s3_bucket_ca_public_policy           = aws_iam_policy.puppet_ca_public_policy.arn
      s3_bucket_ca_private_policy          = aws_iam_policy.puppet_ca_private_policy.arn
    }
  }

  root_block_device       = lookup(each.value, "root_block_device", { volume_size = 20 }) # default: 20 GiB
  home_block_device       = lookup(each.value, "home_block_device", null)
  secondary_block_devices = lookup(each.value, "secondary_block_devices", [])

  network_interfaces = lookup(each.value, "network_interfaces", [])

  dns = {
    zone_id              = aws_route53_zone.omega_private_omg_dns.zone_id
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

  additional_iam_policies = lookup(each.value, "additional_iam_policies", [])

  # Puppet Agent settings
  puppet = each.value.puppet == null ? null : {
    version     = each.value.puppet.version
    server_fqdn = "${local.ec2_puppet_server_instances.puppet_server_1.hostname}.${local.private_omg_dns_domain}"
    certificates = {
      s3_bucket_name                       = aws_s3_bucket.puppet_certificates.id
      s3_bucket_certificates_public_policy = aws_iam_policy.puppet_certificates_public_policy.arn
      s3_bucket_ca_public_policy           = aws_iam_policy.puppet_ca_public_policy.arn
      s3_bucket_ca_private_policy          = aws_iam_policy.puppet_ca_private_policy.arn
      subject                              = local.default_certificate_subject
      ca_private_key_pem                   = module.ec2_puppet_server_instance["puppet_server_1"].puppet_ca_private_key_pem
      ca_certificate_pem                   = module.ec2_puppet_server_instance["puppet_server_1"].puppet_ca_certificate_pem
    }
  }

  root_block_device       = lookup(each.value, "root_block_device", { volume_size = 20 }) # default: 20 GiB
  home_block_device       = lookup(each.value, "home_block_device", null)
  secondary_block_devices = lookup(each.value, "secondary_block_devices", [])

  # TODO(AR) additional data volumes - see https://github.com/hashicorp/terraform/issues/33259

  network_interfaces = lookup(each.value, "network_interfaces", [])

  dns = {
    zone_id              = aws_route53_zone.omega_private_omg_dns.zone_id
    reverse_ipv4_zone_id = aws_route53_zone.omega_private_ipv4_omg_reverse_dns.zone_id
    reverse_ipv6_zone_id = aws_route53_zone.omega_private_ipv6_omg_reverse_dns.zone_id
  }

  tags = each.value.tags
}

data "aws_iam_policy_document" "ec2_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}