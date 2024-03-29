locals {
  media_type_cloud_config = "text/cloud-config"
  media_type_shellscript  = "text/x-shellscript"

  scripts_dir = "${path.root}/${path.module}/scripts"

  hostname_part = var.fqdn == null ? [] : [
    {
      content_type = local.media_type_cloud_config
      filename     = "omega-01-set-hostname.yaml"
      content = templatefile("${local.scripts_dir}/omega-01-set-hostname.yaml.tftpl", {
        fqdn     = var.fqdn,
        hostname = replace(var.fqdn, "/([^.]+).*/", "$1")
      })
    }
  ]

  separate_home_volume_part = var.separate_home_volume == null ? [] : [
    # NOTE(AR) it is not clear to me why, but AWS Linux 2 seems to need the cloud-init yaml for the `mount` before the shell script for the `prepare`, otherwise nothing ever gets mounted
    {
      content_type = local.media_type_cloud_config
      filename     = "omega-02-mount-home-volume.yaml"
      content = templatefile("${local.scripts_dir}/omega-02-mount-home-volume.yaml.tftpl", {
        volume      = var.separate_home_volume
        mount_point = "/home"
      })
    },
    {
      content_type = local.media_type_shellscript
      filename     = "omega-03-prepare-home-volume.sh"
      content = templatefile("${local.scripts_dir}/omega-03-prepare-home-volume.sh.tftpl", {
        volume      = var.separate_home_volume
        mount_point = "/home"
      })
    },
  ]

  additional_volumes_part = length(var.additional_volumes) == 0 ? [] : [
    # NOTE(AR) it is not clear to me why, but AWS Linux 2 seems to need the cloud-init yaml for the `mount` before the shell script for the `prepare`, otherwise nothing ever gets mounted
    {
      content_type = local.media_type_cloud_config
      filename     = "omega-04-mount-additional-volumes.yaml"
      content = templatefile("${local.scripts_dir}/omega-04-mount-additional-volumes.yaml.tftpl", {
        additional_volumes = var.additional_volumes
      })
    },
    {
      content_type = local.media_type_shellscript
      filename     = "omega-05-prepare-additional-volumes.sh"
      content = templatefile("${local.scripts_dir}/omega-05-prepare-additional-volumes.sh.tftpl", {
        additional_volumes = var.additional_volumes
      })
    }
  ]

  additional_parts = [
    for additional_part in var.additional_parts : {
      content_type = additional_part.content_type
      filename     = "omega-06-${additional_part.filename}"
      content      = additional_part.content
    }
  ]

  yum_upgrade_part = [
    {
      content_type = local.media_type_cloud_config
      filename     = "omega-08-yum-upgrade.yaml"
      content      = file("${local.scripts_dir}/omega-08-yum-upgrade.yaml")
    }
  ]

  reboot_part = var.reboot != true ? [] : [
    {
      content_type = local.media_type_cloud_config
      filename     = "omega-09-reboot.yaml"
      content      = file("${local.scripts_dir}/omega-09-reboot.yaml")
    }
  ]


  parts = concat(
    local.hostname_part,
    local.separate_home_volume_part,
    local.additional_volumes_part,
    local.additional_parts,
    local.yum_upgrade_part,
    local.reboot_part
  )
}