###
# Puppet Script for a Base System on Amazon Linux 2
###

# TODO(AR) - Update Yum packages
# TODO(AR) - Automatic Updates

include ::ufw
include 'yum'

package { 'deltarpm':
	ensure => installed
}

package { 'zsh':
	ensure => installed
}

group { 'sudo':
	ensure => present,
	auth_membership => true
}

user { 'ec2-user':
	ensure => present,
	gid => 'ec2-user',
	groups => [
		'adm',
		'wheel',
		'sudo',
		'systemd-journal'
	],
	comment => 'EC2 Default User',
	managehome => true,
	shell => '/usr/bin/zsh',
	require => [
		Group['sudo'],
		Package['zsh']
	]
}

file { '/home/ec2-user':
	ensure => directory,
	replace => false,
    owner => 'ec2-user',
    group => 'ec2-user',
	mode => '0750',
    require => User['ec2-user']
}

ssh_authorized_key { 'aretter@hollowcore.local':
	ensure => present,
	user => 'ec2-user',
	type => 'ssh-rsa',
	key => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDHvJ21M2Jfw75K82bEdZIhL9t7N8kUuXOPxKWFs7o6Z+42UGH47lmQrk95OJdhLxlp2paGFng++mMLV1Xf7uLjTUE8lJHJv/TSzC81Q5NSfFXQTn4kpr5BRKgTnXPNYTHcsueeUr6auZDThVG3mU62AvieFeI5MJOE7FlAS4++u2pVG7+H4l48snlKiUDH5oXRLdJtZbED2v6byluSkj6uNThEYoHzHRxvF8Lo12NgQEMBVrHyvBWtHPpZIhCzzzsTEf9+249VqsO3NqTl7vswMhf8z2NYgGjf0w+5A3bJDIpvDRWQ+40uB1bdwqUDuiY8nGSSKwpVOby0cYZjfhjZ',
	require => User['ec2-user']
}

package { 'curl':
	ensure => installed
}

exec { 'install-ohmyzsh':
	command => 'sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"',
	path => '/usr/bin',
	user => 'ec2-user',
	require => [
		Package['curl'],
		Package['zsh'],
		Package['git'],
		User['ec2-user']
	],
	creates => '/home/ec2-user/.oh-my-zsh'
}

package { 'openssh':
	ensure => installed
}

class { 'ssh':
	storeconfigs_enabled => false,
	validate_sshd_file => true,
	server_options => {
		'Port' => [22],
		'HostKey' => [
			'/etc/ssh/ssh_host_rsa_key',
			'/etc/ssh/ssh_host_ecdsa_key',
			'/etc/ssh/ssh_host_ed25519_key'
		],
		'SyslogFacility' => 'AUTHPRIV',
		'AuthorizedKeysFile' => '.ssh/authorized_keys',
		'PermitRootLogin' => 'no',
		'PasswordAuthentication' => 'no',
		'ChallengeResponseAuthentication' => 'no',
		'GSSAPIAuthentication' => 'yes',
		'GSSAPICleanupCredentials' => 'yes',
		'UsePAM' => 'yes',
		'X11Forwarding' => 'yes',
		'PrintMotd' => 'yes',
		'AllowTcpForwarding' => 'no',
		'AcceptEnv' => [
			'LANG LC_CTYPE LC_NUMERIC LC_TIME LC_COLLATE LC_MONETARY LC_MESSAGES',
			'LC_PAPER LC_NAME LC_ADDRESS LC_TELEPHONE LC_MEASUREMENT',
			'LC_IDENTIFICATION LC_ALL LANGUAGE',
			'XMODIFIERS'
		]
	},
	users_client_options => {
		'ec2-user' => {
			options => {
				'HashKnownHosts' => 'yes'
			}
		}
	},
	subscribe => Package['openssh']
}

# TODO(AR) is this okay for overriding the 'ufw' package in the 'ufw' module
Package <| title == 'ufw' |> { require => Package["epel-release"] }

ufw::allow { 'ssh':
	port => '22',
	interface => 'eth0',
	require => Package['openssh']
}

package { 'ntp':
	ensure => installed
}

service { 'ntpd':
	name => 'ntpd',
	ensure => running,
	enable => true,
	require => Package['ntp']
}

package { 'screen':
	ensure => installed
}

package { 'git':
	ensure => installed
}

exec { 'enable-epel':
        command => 'amazon-linux-extras enable epel',
	path => '/usr/bin'
}
-> exec { 'clean-yum-metadata':
	command => 'yum -y clean metadata',
	path => '/usr/bin'
}
-> exec { 'yum-update':
	command => 'yum -y update',
	path => '/usr/bin'
} 
-> package { 'epel-release':
	ensure => installed
}

file { '/home/ec2-user/code':
	ensure => directory,
	replace => false,
	owner => 'ec2-user',
	group => 'ec2-user',
	require => User['ec2-user']
}
