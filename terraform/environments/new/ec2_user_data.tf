data "cloudinit_config" "dev_workstation_new" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    filename     = "omega-mount-volumes.yaml"
    content      = <<EOF
#cloud-config
mounts:
 - [ "/dev/xvdb", "/home", "xfs", "defaults,nofail", "0", "0" ]
EOF
  }

  part {
    content_type = "text/x-shellscript"
    filename     = "omega-01-format-and-mount-volumes.sh"
    content      = <<EOF
#!/usr/bin/env bash
mkfs -t xfs /dev/xvdb
cp -rp /home/ec2-user /tmp
mount /dev/xvdb /home
mv -f /tmp/ec2-user /home
HOME_VOLUME_UUID=$(blkid /dev/xvdb | sed -n 's/.*UUID=\"\([^\"]*\)\".*/\1/p')
bash -c "echo 'UUID=$HOME_VOLUME_UUID     /home       xfs    defaults 0   0' >> /etc/fstab"
EOF
  }

  part {
    content_type = "text/cloud-config"
    filename     = "yum-upgrade.yaml"
    content      = <<EOF
#cloud-config
package_update: true
package_upgrade: true
EOF
  }
}
