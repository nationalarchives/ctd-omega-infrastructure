###
# Terraform Script for Services API in AWS Cloud for Omega
#
# Author: Adam Retter @ Evolved Binary
###


## Config for services-api-1 below

module "mvpbeta_services_api_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.13.1"

  name        = "services_api_security_group"
  description = "Security group for Services API ports open within VPC"

  vpc_id = module.vpc.vpc_id

  computed_ingress_with_cidr_blocks = [
    {
      description = "SSH"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = module.vpc.private_subnets_cidr_blocks[0] # NOTE: restricted to vpc_private_subnet_dev_general
    }
  ]
  number_of_computed_ingress_with_cidr_blocks = 1

  computed_ingress_with_ipv6_cidr_blocks = [
    {
      description      = "SSH (IPv6)"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      ipv6_cidr_blocks = module.vpc.private_subnets_ipv6_cidr_blocks[0] # NOTE: restricted to vpc_private_subnet_dev_general (IPv6)
    }
  ]
  number_of_computed_ingress_with_ipv6_cidr_blocks = 1

  egress_with_cidr_blocks = [
    {
      description = "All"
      from_port   = -1
      to_port     = -1
      protocol    = -1
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  egress_with_ipv6_cidr_blocks = [
    {
      description = "All (IPv6)"
      from_port   = -1
      to_port     = -1
      protocol    = -1
      cidr_blocks = "2001:db8::/64"
    }
  ]

  tags = {
    Name        = "sg_services_api"
    Type        = "security_group"
    Environment = "mvpbeta"
  }
}

resource "aws_network_interface" "mvpbeta_services_api_1_interface" {
  description        = "Private Subnet Interface for MVP Beta services-api-1"
  subnet_id          = module.vpc.private_subnets[3]
  private_ips        = ["10.128.238.52"]
  ipv6_address_count = 0 # use assign_ipv6_address_on_creation=true from the vpc subnet configuration

  security_groups = [
    module.mvpbeta_services_api_security_group.security_group_id
  ]

  tags = {
    Name        = "eth0_services-api-1"
    Type        = "primary_network_interface"
    Network     = "mvpbeta_services"
    Environment = "mvpbeta"
  }
}

data "aws_network_interface" "mvpbeta_services_api_1_interface" {
  id = aws_network_interface.mvpbeta_services_api_1_interface.id
}

data "cloudinit_config" "services_api" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    filename     = "yum-upgrade.yaml"
    content      = <<EOF
#cloud-config
package_update: true
package_upgrade: true
EOF
  }

  part {
    content_type = "text/x-shellscript"
    filename     = "omega-01-install-puppet.sh"
    content      = <<EOF
#!/usr/bin/env bash
rpm -Uvh https://yum.puppet.com/puppet7-release-el-7.noarch.rpm
yum -y install puppet
EOF
  }

  part {
    content_type = "text/x-shellscript"
    filename     = "omega-02-install-puppet-modules.sh"
    content      = <<EOF
#!/usr/bin/env bash
/opt/puppetlabs/bin/puppet module install puppetlabs-stdlib --version 7.1.0
/opt/puppetlabs/bin/puppet module install saz-ssh
/opt/puppetlabs/bin/puppet module install domkrm-ufw
/opt/puppetlabs/bin/puppet module install puppet-yum
/opt/puppetlabs/bin/puppet module install puppetlabs-sshkeys_core
/opt/puppetlabs/bin/puppet module install treydock-yum_cron
EOF
  }

  part {
    content_type = "text/x-shellscript"
    filename     = "omega-03-install-puppet-scripts.sh"
    content      = <<EOF
#!/usr/bin/env bash
mkdir /root/omega-puppet-scripts
echo '${filebase64("../puppet/base.pp")}' | base64 -d > /root/omega-puppet-scripts/base.pp
echo '${filebase64("../puppet/services-api-vm.pp")}' | base64 -d > /root/omega-puppet-scripts/services-api-vm.pp
EOF
  }

  part {
    content_type = "text/x-shellscript"
    filename     = "omega-04-run-puppet-scripts.sh"
    content      = <<EOF
#!/usr/bin/env bash
/opt/puppetlabs/bin/puppet apply /root/omega-puppet-scripts
EOF
  }

  part {
    content_type = "text/cloud-config"
    filename     = "reboot.yaml"
    content      = <<EOF
#cloud-config
power_state:
    delay: now
    mode: reboot
    message: Rebooting machine after Omega cloud-init Initialisation Completed
EOF
  }
}

resource "aws_instance" "mvpbeta_services_api_1" {
  availability_zone = local.aws_azs[0]
  ami               = data.aws_ami.amazon_linux_2_20210813_arm64.id
  instance_type     = "t4g.large" # NOTE(AR): My original estimate was for t3.xlarge, lets see how this smaller instance does

  key_name = aws_key_pair.omega_admin_key_pair.key_name

  user_data                   = data.cloudinit_config.services_api.rendered
  user_data_replace_on_change = false

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  monitoring = false

  network_interface {
    network_interface_id = aws_network_interface.mvpbeta_services_api_1_interface.id
    device_index         = 0
  }

  root_block_device {
    delete_on_termination = false
    encrypted             = false
    volume_type           = "gp3"
    volume_size           = 8 # GiB

    tags = {
      Name        = "root_services-api-1"
      Type        = "primary_volume"
      Environment = "mvpbeta"
    }
  }

  tags = {
    Name                      = "services-api-1"
    Type                      = "services_api"
    Environment               = "mvpbeta"
    scheduler_mon_fri_dev_ec2 = "true"
  }
}

resource "aws_ebs_volume" "mvpbeta_services_api_1_volume_message_store" {
  availability_zone = local.aws_az_1

  encrypted = false

  type       = "gp3"
  iops       = 3000
  throughput = 125 # MiB/s
  size       = 10  # GiB

  tags = {
    Name        = "message_store_services-api-1"
    Type        = "message_store_data_volume"
    Environment = "mvpbeta"
  }
}

resource "aws_volume_attachment" "mvpbeta_services_api_1_volume_attachment_message_store" {
  device_name = "xvdb"
  volume_id   = aws_ebs_volume.mvpbeta_services_api_1_volume_message_store.id
  instance_id = aws_instance.mvpbeta_services_api_1.id

  stop_instance_before_detaching = true
}

resource "aws_route53_record" "dns_a_services-api-1_mvpbeta_catalogue_nationalarchives_gov_uk" {
  zone_id = aws_route53_zone.omega_private_mvpbeta_dns.zone_id
  name    = "services-api-1.${local.private_mvpbeta_dns_domain}"
  type    = "A"
  ttl     = "300"
  records = data.aws_network_interface.mvpbeta_services_api_1_interface.private_ips
}
