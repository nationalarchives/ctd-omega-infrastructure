#!/usr/bin/env bash

rpm -Uvh https://yum.puppet.com/puppet7-release-el-7.noarch.rpm
yum -y install puppet

/opt/puppetlabs/bin/puppet module install puppetlabs-stdlib
/opt/puppetlabs/bin/puppet module install saz-ssh
/opt/puppetlabs/bin/puppet module install domkrm-ufw
/opt/puppetlabs/bin/puppet module install puppet-yum
/opt/puppetlabs/bin/puppet module install puppetlabs-sshkeys_core
/opt/puppetlabs/bin/puppet module install puppetlabs-vcsrepo
