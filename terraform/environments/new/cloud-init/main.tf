locals {
    media_type_cloud_config = "text/cloud-config"
    media_type_shellscript  = "text/x-shellscript"

    scripts_dir = "${path.root}/${path.module}/scripts"

    hostname_part = var.fqdn == null ? [] : [
        {
            content_type = local.media_type_cloud_config
            filename = "omega-01-set-hostname.yaml"
            content = templatefile("${local.scripts_dir}/omega-01-set-hostname.yaml.tftpl", {
                fqdn = var.fqdn,
                hostname = replace(var.fqdn, "/([^.]+).*/", "$1")
            })
        }
    ]

    separate_home_volume_part = var.separate_home_volume == null ? [] : [
        {
            content_type = local.media_type_shellscript
            filename = "omega-02-prepare-home-volume.sh"
            content = templatefile("${local.scripts_dir}/omega-02-prepare-home-volume.sh.tftpl", {
                separate_home_volume = var.separate_home_volume
            })
        },
        {
            content_type = local.media_type_cloud_config
            filename = "omega-03-mount-home-volume.yaml"
            content = templatefile("${local.scripts_dir}/omega-03-mount-home-volume.yaml.tftpl", {
                separate_home_volume = var.separate_home_volume
            })
        }
    ]

    yum_upgrade_part = [
        {
            content_type = local.media_type_cloud_config
            filename = "omega-08-yum-upgrade.yaml"
            content = file("${local.scripts_dir}/omega-08-yum-upgrade.yaml")
        }
    ]

    reboot_part = var.reboot != true ? [] : [
        {
            content_type = local.media_type_cloud_config
            filename = "omega-09-reboot.yaml"
            content = file("${local.scripts_dir}/omega-09-reboot.yaml")
        }
    ]

    parts = concat(
        local.hostname_part,
        local.separate_home_volume_part,
        local.yum_upgrade_part,
        local.reboot_part
    )
}

data "cloudinit_config" "computed" {
  gzip          = true
  base64_encode = true

  dynamic "part" {
    for_each = local.parts
    content {
      content_type = part.value["content_type"]
      filename = part.value["filename"]
      content = part.value["content"]
    }
  }
}