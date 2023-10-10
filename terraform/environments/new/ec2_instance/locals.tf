locals {

  scripts_dir = "${path.root}/${path.module}/scripts"

  # default tags for the root_block_device
  default_root_block_device_tags = {
    Name        = "root_${local.hostname}_new"
    Type        = "primary_volume"
    Environment = lookup(var.tags, "Environment", null)
  }

  # default tags for a separate home block_device
  default_home_block_device_tags = {
    Name        = "home_${local.hostname}_new"
    Type        = "home_volume"
    Environment = lookup(var.tags, "Environment", null)
  }

  # default tags for secondary block_device(s)
  default_secondary_block_device_tags = {
    Name        = "secondary_${local.hostname}_new"
    Type        = "secondary_volume"
    Environment = lookup(var.tags, "Environment", null)
  }

  default_ca_certificate_filename = "${local.puppet_server_fqdn}-ca.crt.pem"
  default_ca_public_key_filename  = "${local.puppet_server_fqdn}-ca.public.key.pem"
  default_ca_private_key_filename = "${local.puppet_server_fqdn}-ca.private.key.pem"

  default_certificate_filename    = "${var.fqdn}.crt.pem"
  default_public_key_filename     = "${var.fqdn}.public.key.pem"
  default_private_key_filename    = "${var.fqdn}.private.key.pem"

  hostname = replace(var.fqdn, "/([^.]+).*/", "$1")
  hostname_title = replace(title(replace(local.hostname, "-", " ")), " ", "")

  root_block_device       = merge(var.root_block_device, { tags = merge(local.default_root_block_device_tags, var.root_block_device["tags"]) })
  home_block_device       = var.home_block_device == null ? null : merge(var.home_block_device, { tags = merge(local.default_home_block_device_tags, var.home_block_device["tags"]) })
  secondary_block_devices = [for secondary_block_device in var.secondary_block_devices : merge(secondary_block_device, { tags = merge(local.default_secondary_block_device_tags, secondary_block_device["tags"]) })]

  additional_block_devices = local.home_block_device != null ? concat([local.home_block_device], local.secondary_block_devices) : local.secondary_block_devices

  generate_server_ec2_iam_instance_profile = var.iam_instance_profile == null && try(var.puppet.server != null, false)
  generate_agent_ec2_iam_instance_profile = var.iam_instance_profile == null && try(var.puppet.server == null, false)
  iam_instance_profile = try(coalesce(
    var.iam_instance_profile,
    local.generate_server_ec2_iam_instance_profile ? aws_iam_instance_profile.puppet_server_ec2_iam_instance_profile[0].id : null,
    local.generate_agent_ec2_iam_instance_profile ? aws_iam_instance_profile.puppet_agent_ec2_iam_instance_profile[0].id : null
  ), null)

  puppet_server_fqdn = coalesce(
    can(var.puppet.server_fqdn) ? var.puppet.server_fqdn : null,
    try(var.puppet.server != null ? var.fqdn : null),
    "puppet-server"
  )

  generate_ca          = var.puppet != null && try(var.puppet.server.ca == null, false)
  generate_certificate = var.puppet != null && try(var.puppet.certificates.self == null, false)

  ca_certificate_filename = coalesce(can(var.puppet.certificates.ca_certificate_filename) ? var.puppet.certificates.ca_certificate_filename : null, local.default_ca_certificate_filename)
  ca_public_key_filename  = try(var.puppet.server.ca.public_key, local.default_ca_public_key_filename)
  ca_private_key_filename = try(var.puppet.server.ca.private_key, local.default_ca_private_key_filename)

  certificate_filename    = try(var.puppet.certificates.self.certificate_filename, local.default_certificate_filename)
  public_key_filename     = try(var.puppet.certificates.self.public_key_filename, local.default_public_key_filename)
  private_key_filename    = try(var.puppet.certificates.self.private_key_filename, local.default_private_key_filename)

  s3_bucket_arn_puppet_certificates = try("arn:aws:s3:::${var.puppet.certificates.s3_bucket_name}", null)

  puppet_cloud_init_part_agent_content = var.puppet == null || try(var.puppet.server != null, false) ? null : templatefile("${local.scripts_dir}/install-puppet-agent.sh.tftpl", {
      s3_bucket_name_puppet_certificates = var.puppet.certificates.s3_bucket_name
      puppet_agent_fqdn                  = var.fqdn
      puppet_server_fqdn                 = local.puppet_server_fqdn
      ca_certificate_pem_filename        = local.ca_certificate_filename
      certificate_pem_filename           = local.certificate_filename
      public_key_pem_filename            = local.public_key_filename
      private_key_pem_filename           = local.private_key_filename
  })

  puppet_cloud_init_part_server_content = var.puppet == null || try(var.puppet.server != null, false) == false ? null : templatefile("${local.scripts_dir}/install-puppet-server.sh.tftpl", {
      s3_bucket_name_puppet_certificates = var.puppet.certificates.s3_bucket_name
      puppet_server_fqdn                 = local.puppet_server_fqdn
      ca_certificate_pem_filename        = local.ca_certificate_filename
      ca_public_key_pem_filename         = local.ca_public_key_filename
      ca_private_key_pem_filename        = local.ca_private_key_filename
      puppet_control_repo_url            = var.puppet.server.control_repo_url
      puppet_environment                 = var.puppet.server.environment

      puppet_agents = flatten([
        [{
            fqdn                               = var.fqdn
            certificate_pem_filename           = local.certificate_filename
            public_key_pem_filename            = local.public_key_filename
            private_key_pem_filename           = local.private_key_filename
        }],
        [for puppet_agent in var.puppet.server.agents : {
            fqdn = puppet_agent.fqdn
            certificate_pem_filename = coalesce(puppet_agent.certificate_filename, "${puppet_agent.fqdn}.crt.pem")
            public_key_pem_filename  = coalesce(puppet_agent.public_key_filename, "${puppet_agent.fqdn}.public.key.pem")
            private_key_pem_filename = coalesce(puppet_agent.private_key_filename, "${puppet_agent.fqdn}.private.key.pem")
        }]
      ])
  })

  puppet_cloud_init_part = var.puppet == null ? null : {
    content_type = "text/x-shellscript"
    filename     = var.puppet.server == null ? "01-install-puppet-agent.sh" : "01-install-puppet-server.sh"
    content      = var.puppet.server == null ? local.puppet_cloud_init_part_agent_content : local.puppet_cloud_init_part_server_content
  }
}
