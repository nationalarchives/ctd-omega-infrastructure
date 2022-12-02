###
# Puppet Script for installing Services Api VM on Amazon Linux 2
#
# Author: Adam Retter @ Evolved Binary
###

user { 'ctd-omega-services':
  ensure     => present,
  comment    => 'Service User Account for the ctd-omega-services application',
  system     => true,
  membership => inclusive,
  managehome => false,
  home       => '/nonexistent',
  shell      => '/sbin/nologin',
}

package { 'java-11-amazon-corretto':
  ensure => installed,
}
