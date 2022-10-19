###
# Puppet Script for installing Web App VM on Amazon Linux 2
#
# Author: Adam Retter @ Evolved Binary
###

ufw::allow { 'Play https from vpc_private_subnet_dev_general':
  port      => '9443',
  from      => '10.128.238.0/27',              # TODO(AR) make this injectable from Terraform via Facter
  interface => 'eth0',
}

ufw::allow { 'Play https from web-proxy-1':
  port      => '9443',
  from      => '10.128.238.196',               # TODO(AR) make this injectable from Terraform via Facter
  interface => 'eth0',
}

package { 'java-11-amazon-corretto':
  ensure => installed,
}