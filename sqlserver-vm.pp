###
# Puppet Script for installing SQL Server (Developer Edition) VM on Amazon Linux 2
###

include ::ufw
include 'yum'

# TODO(AR) is this okay for overriding the 'ufw' package in the 'ufw' module
Package <| title == 'ufw' |> { require => Package["epel-release"] }

exec { 'add-mssql-server-repo':
	command => 'yum-config-manager --add-repo https://packages.microsoft.com/config/rhel/7/mssql-server-2019.repo',
	path => '/usr/bin',
	creates => '/etc/yum.repos.d/mssql-server-2019.repo'
}

package { 'mssql-server':
	ensure => installed,
	require => Exec['add-mssql-server-repo']
}

group { 'mssql':
	ensure => present,
	auth_membership => true,
	system => true
}

user { 'mssql':
	ensure => present,
	gid => 'mssql',
	comment => 'Microsoft SQL Server',
	managehome => false,
	home => '/var/opt/mssql',
	shell => '/bin/bash',
	require => Group['mssql']
}

file { '/opt/mssql':
	ensure => directory,
	replace => false,
	owner => 'mssql',
	group => 'mssql',
	mode => '0750',
	require => [
		User['mssql'],
		Package['mssql-server']
	]
}

file { '/var/opt/mssql':
	ensure => directory,
	replace => false,
	owner => 'mssql',
	group => 'mssql',
	mode => '0750',
	require => [
		User['mssql'],
		Package['mssql-server']
	]
}

file { '/mssql':
	ensure => directory,
	replace => false,
    owner => 'mssql',
    group => 'mssql',
	mode => '0750',
    require => [
		User['mssql'],
		Package['mssql-server']
	]
}

file { '/mssql/data':
	ensure => directory,
	replace => false,
    owner => 'mssql',
    group => 'mssql',
	mode => '0750',
    require => File['/mssql']
}

file { '/mssql/log':
	ensure => directory,
	replace => false,
    owner => 'mssql',
    group => 'mssql',
	mode => '0750',
    require => File['/mssql']
}

file { '/mssql/backup':
	ensure => directory,
	replace => false,
    owner => 'mssql',
    group => 'mssql',
	mode => '0750',
    require => File['/mssql']
}

exec { 'configure-mssql-server':
	environment => [
		'MSSQL_PID=Developer',
		'ACCEPT_EULA=Y',
		"MSSQL_SA_PASSWORD=$facts['sa_password']",
		'MSSQL_DATA_DIR=/mssql/data',
		'MSSQL_LOG_DIR=/mssql/log',
		'MSSQL_BACKUP_DIR=/mssql/backup'

	],
	command => 'mssql-conf -n setup',
	path => '/opt/mssql/bin',
	creates => '/opt/mssql/bin/sqlservr',
	require => [
		File['/mssql/data'],
		File['/mssql/log'],
		File['/mssql/backup']
	]
}

service { 'mssql-server':
	name => 'mssql-server',
	ensure => running,
	enable => true,
	require => [
		Package['mssql-server'],
		Exec['configure-mssql-server']
	]
}

package { 'mssql-tools':
	ensure => installed,
	install_options => [
		{ 'ACCEPT_EULA' => 'Y' }
	],
	require => Exec['add-mssql-server-repo']
}


file { '/etc/profile.d/append-mssql-tools-path.sh':
	content => 'export PATH="${PATH}:/opt/mssql-tools/bin"',
	owner => 'root',
	group => 'root',
	mode => '0644',
	require => Package['mssql-tools']
}

# TODO(AR) should we only allow this on a private interface within the VPC for the VM?

ufw::allow { 'tsql':
	port => '1433',
	interface => 'eth0',
	require => [
		Package['mssql-server'],
		Exec['configure-mssql-server']
	]
}

