# Install Puppet on Amazon Linux 2

```
sudo rpm -Uvh https://yum.puppet.com/puppet7-release-el-7.noarch.rpm
sudo yum -y install puppet

sudo /opt/puppetlabs/bin/puppet module install puppetlabs-stdlib --version 7.1.0
sudo /opt/puppetlabs/bin/puppet module install saz-ssh
sudo /opt/puppetlabs/bin/puppet module install domkrm-ufw
sudo /opt/puppetlabs/bin/puppet module install puppet-yum
sudo /opt/puppetlabs/bin/puppet module install puppetlabs-sshkeys_core
sudo /opt/puppetlabs/bin/puppet module install puppetlabs-vcsrepo
```

## Installing a Developer VM

Copy the `base.pp` and `developer-vm.pp` files into `/root/omega-puppet-scripts` of the VM and then run:

```
sudo /opt/puppetlabs/bin/puppet apply /root/omega-puppet-scripts
```

# Install the SQL Server VM

Copy the `base.pp` and `sqlserver-vm.pp` files into `/root/omega-puppet-scripts` of the VM and then run:

```
sudo FACTER_sa_password=\!myStrongSqlPassword2019 /opt/puppetlabs/bin/puppet apply /root/omega-puppet-scripts
```

NOTE: In the above you should replace the `\!myStrongSqlPassword2019` with a suitable password.

