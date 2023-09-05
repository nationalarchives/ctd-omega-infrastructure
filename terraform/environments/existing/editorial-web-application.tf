###
# Terraform Script for Editorial Web Application in AWS Cloud for Omega
#
# Author: Adam Retter @ Evolved Binary
###


## Config for web-proxy-1 below

resource "aws_route53_zone" "omega_private_mvpbeta_dns" {
  name = local.private_mvpbeta_dns_domain

  vpc {
    vpc_id = module.vpc.vpc_id
  }

  tags = {
    name = "dns_zone"
  }
}

output "omega_private_mvpbeta_dns_servers" {
  description = "DNS Servers for Omega mvpbeta environment"
  value       = aws_route53_zone.omega_private_mvpbeta_dns.name_servers
}

module "mvpbeta_web_proxy_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.17.2"

  name        = "web_proxy_security_group"
  description = "Security group for Web Proxy ports open within VPC"

  vpc_id = module.vpc.vpc_id

  computed_ingress_with_cidr_blocks = [
    {
      description = "SSH"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = module.vpc.private_subnets_cidr_blocks[0] # NOTE: restricted to vpc_private_subnet_dev_general
    },
    {
      description = "HTTP"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = module.vpc.private_subnets_cidr_blocks[0] # NOTE: restricted to vpc_private_subnet_dev_general
    },
    {
      description = "HTTPS"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = module.vpc.private_subnets_cidr_blocks[0] # NOTE: restricted to vpc_private_subnet_dev_general
    }
  ]
  number_of_computed_ingress_with_cidr_blocks = 3

  computed_ingress_with_ipv6_cidr_blocks = [
    {
      description      = "SSH (IPv6)"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      ipv6_cidr_blocks = module.vpc.private_subnets_ipv6_cidr_blocks[0] # NOTE: restricted to vpc_private_subnet_dev_general (IPv6)
    },
    {
      description      = "HTTP (IPv6)"
      from_port        = 80
      to_port          = 80
      protocol         = "tcp"
      ipv6_cidr_blocks = module.vpc.private_subnets_ipv6_cidr_blocks[0] # NOTE: restricted to vpc_private_subnet_dev_general (IPv6)
    },
    {
      description      = "HTTPS (IPv6)"
      from_port        = 443
      to_port          = 443
      protocol         = "tcp"
      ipv6_cidr_blocks = module.vpc.private_subnets_ipv6_cidr_blocks[0] # NOTE: restricted to vpc_private_subnet_dev_general (IPv6)
    }
  ]
  number_of_computed_ingress_with_ipv6_cidr_blocks = 3

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
    Name        = "sg_web_proxy"
    Type        = "security_group"
    Environment = "mvpbeta"
  }
}

resource "aws_network_interface" "mvpbeta_web_proxy_1_interface" {
  description        = "TNA Public (i.e. Private) Subnet Interface for MVP Beta web-proxy-1"
  subnet_id          = module.vpc.private_subnets[4]
  private_ips        = ["10.128.238.196"]
  ipv6_address_count = 0 # use assign_ipv6_address_on_creation=true from the vpc subnet configuration

  security_groups = [
    module.mvpbeta_web_proxy_security_group.security_group_id
  ]

  tags = {
    Name        = "eth0_web-proxy-1"
    Type        = "primary_network_interface"
    Network     = "mvpbeta_public"
    Environment = "mvpbeta"
  }
}

data "aws_network_interface" "mvpbeta_web_proxy_1_interface" {
  id = aws_network_interface.mvpbeta_web_proxy_1_interface.id
}

data "cloudinit_config" "web_proxy" {
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
/opt/puppetlabs/bin/puppet module install petems-swap_file
/opt/puppetlabs/bin/puppet module install puppet-openssl
/opt/puppetlabs/bin/puppet module install puppet-nginx
/opt/puppetlabs/bin/puppet module install puppet-letsencrypt
EOF
  }

  part {
    content_type = "text/x-shellscript"
    filename     = "omega-03-install-puppet-scripts.sh"
    content      = <<EOF
#!/usr/bin/env bash
mkdir /root/omega-puppet-scripts
echo '${filebase64("../puppet/base.pp")}' | base64 -d > /root/omega-puppet-scripts/base.pp
echo '${filebase64("../puppet/web-proxy-vm.pp")}' | base64 -d > /root/omega-puppet-scripts/web-proxy-vm.pp
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

resource "aws_instance" "mvpbeta_web_proxy_1" {
  availability_zone = local.aws_azs[0]
  ami               = data.aws_ami.amazon_linux_2_20210813_arm64.id
  instance_type     = "t4g.nano"

  key_name = aws_key_pair.omega_admin_key_pair.key_name

  user_data                   = data.cloudinit_config.web_proxy.rendered
  user_data_replace_on_change = false

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  monitoring = false

  network_interface {
    network_interface_id = aws_network_interface.mvpbeta_web_proxy_1_interface.id
    device_index         = 0
  }

  root_block_device {
    delete_on_termination = false
    encrypted             = false
    volume_type           = "gp3"
    volume_size           = 8 # GiB

    tags = {
      Name        = "root_web-proxy-1"
      Type        = "primary_volume"
      Environment = "mvpbeta"
    }
  }

  tags = {
    Name        = "web-proxy-1"
    Type        = "web_proxy"
    Environment = "mvpbeta"
    #scheduler_mon_fri_dev_ec2 = "true"
  }
}

resource "aws_route53_record" "dns_a_web-proxy-1_mvpbeta_catalogue_nationalarchives_gov_uk" {
  zone_id = aws_route53_zone.omega_private_mvpbeta_dns.zone_id
  name    = "web-proxy-1.${local.private_mvpbeta_dns_domain}"
  type    = "A"
  ttl     = "300"
  records = data.aws_network_interface.mvpbeta_web_proxy_1_interface.private_ips
}


## Config for web-app-1 below

module "mvpbeta_web_app_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.17.2"

  name        = "web_app_security_group"
  description = "Security group for Web Application ports open within VPC"

  vpc_id = module.vpc.vpc_id

  computed_ingress_with_cidr_blocks = [
    {
      description = "SSH"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = module.vpc.private_subnets_cidr_blocks[0] # NOTE: restricted to vpc_private_subnet_dev_general
    },
    {
      description = "Play HTTPS"
      from_port   = 9443
      to_port     = 9443
      protocol    = "tcp"
      cidr_blocks = "${module.vpc.private_subnets_cidr_blocks[0]},${module.vpc.private_subnets_cidr_blocks[4]}" # NOTE: restricted to vpc_private_subnet_dev_general and vpc_private_tna_net_subnet_mvpbeta
    }
  ]
  number_of_computed_ingress_with_cidr_blocks = 2

  computed_ingress_with_ipv6_cidr_blocks = [
    {
      description      = "SSH (IPv6)"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      ipv6_cidr_blocks = module.vpc.private_subnets_ipv6_cidr_blocks[0] # NOTE: restricted to vpc_private_subnet_dev_general (IPv6)
    },
    {
      description      = "Play HTTPS (IPv6)"
      from_port        = 9443
      to_port          = 9443
      protocol         = "tcp"
      ipv6_cidr_blocks = "${module.vpc.private_subnets_ipv6_cidr_blocks[0]},${module.vpc.private_subnets_ipv6_cidr_blocks[4]}" # NOTE: restricted to vpc_private_subnet_dev_general (IPv6) and vpc_private_tna_net_subnet_mvpbeta (IPv6)
    }
  ]
  number_of_computed_ingress_with_ipv6_cidr_blocks = 2

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
    Name        = "sg_web_app"
    Type        = "security_group"
    Environment = "mvpbeta"
  }
}

resource "aws_network_interface" "mvpbeta_web_app_1_interface" {
  description        = "Private Subnet Interface for MVP Beta web-app-1"
  subnet_id          = module.vpc.private_subnets[2]
  private_ips        = ["10.128.238.36"]
  ipv6_address_count = 0 # use assign_ipv6_address_on_creation=true from the vpc subnet configuration

  security_groups = [
    module.mvpbeta_web_app_security_group.security_group_id
  ]

  tags = {
    Name        = "eth0_web-app-1"
    Type        = "primary_network_interface"
    Network     = "mvpbeta_web"
    Environment = "mvpbeta"
  }
}

data "aws_network_interface" "mvpbeta_web_app_1_interface" {
  id = aws_network_interface.mvpbeta_web_app_1_interface.id
}

data "cloudinit_config" "web_app" {
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
echo '${filebase64("../puppet/web-app-vm.pp")}' | base64 -d > /root/omega-puppet-scripts/web-app-vm.pp
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

resource "aws_instance" "mvpbeta_web_app_1" {
  availability_zone = local.aws_azs[0]
  ami               = data.aws_ami.amazon_linux_2_20210813_arm64.id
  instance_type     = "t4g.large" # NOTE(AR): My original estimate was for t3.xlarge, lets see how this smaller instance does

  key_name = aws_key_pair.omega_admin_key_pair.key_name

  user_data                   = data.cloudinit_config.web_app.rendered
  user_data_replace_on_change = false

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  monitoring = false

  network_interface {
    network_interface_id = aws_network_interface.mvpbeta_web_app_1_interface.id
    device_index         = 0
  }

  root_block_device {
    delete_on_termination = false
    encrypted             = false
    volume_type           = "gp3"
    volume_size           = 8 # GiB

    tags = {
      Name        = "root_web-app-1"
      Type        = "primary_volume"
      Environment = "mvpbeta"
    }
  }

  tags = {
    Name        = "web-app-1"
    Type        = "web_app"
    Environment = "mvpbeta"
    #scheduler_mon_fri_dev_ec2 = "true"
  }
}

resource "aws_route53_record" "dns_a_web-app-1_mvpbeta_catalogue_nationalarchives_gov_uk" {
  zone_id = aws_route53_zone.omega_private_mvpbeta_dns.zone_id
  name    = "web-app-1.${local.private_mvpbeta_dns_domain}"
  type    = "A"
  ttl     = "300"
  records = data.aws_network_interface.mvpbeta_web_app_1_interface.private_ips
}