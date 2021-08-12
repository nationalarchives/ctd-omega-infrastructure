# Install Puppet on Amazon Linux 2

```
sudo rpm -Uvh https://yum.puppet.com/puppet7-release-el-7.noarch.rpm
sudo yum -y install puppet

sudo /opt/puppetlabs/bin/puppet module install puppetlabs-stdlib
sudo /opt/puppetlabs/bin/puppet module install saz-ssh
sudo /opt/puppetlabs/bin/puppet module install domkrm-ufw
sudo /opt/puppetlabs/bin/puppet module install puppet-yum
sudo /opt/puppetlabs/bin/puppet module install puppetlabs-sshkeys_core
sudo /opt/puppetlabs/bin/puppet module install puppetlabs-vcsrepo
```

## Installing a Developer VM

Copy the developer-vm.pp into ~/ec2-user of the VM and then run:

```
sudo /opt/puppetlabs/bin/puppet apply developer-vm.pp
```


