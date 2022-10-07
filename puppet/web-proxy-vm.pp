###
# Puppet Script for installing Web Proxy VM on Amazon Linux 2
#
# Author: Adam Retter @ Evolved Binary
###

include yum

# TODO(AR) make DNS names injectable from Terraform via Facter

$sysops_email = 'adam@evolvedbinary.com'

ufw::allow { 'http':
  port      => '80',
  interface => 'eth0',
}

ufw::allow { 'https':
  port      => '443',
  interface => 'eth0',
}

swap_file::files { 'default':
  ensure => present,
}

# TODO(AR) Temporary until DNS is running correctly
host { 'catalogue.nationalarchives.gov.uk':
  name => 'catalogue.nationalarchives.gov.uk',
  ip => '10.128.238.196',
}

# TODO(AR) Temporary until DNS is running correctly
host { 'www.catalogue.nationalarchives.gov.uk':
  name => 'www.catalogue.nationalarchives.gov.uk',
  ip => '10.128.238.196',
}

# TODO(AR) Temporary until DNS is running correctly
host { 'mvpbeta.catalogue.nationalarchives.gov.uk':
  name => 'mvpbeta.catalogue.nationalarchives.gov.uk',
  ip => '10.128.238.196',
}

# TODO(AR) Temporary until DNS is running correctly
host { 'www.mvpbeta.catalogue.nationalarchives.gov.uk':
  name => 'www.mvpbeta.catalogue.nationalarchives.gov.uk',
  ip => '10.128.238.196',
}

class { 'openssl':
  package_ensure         => latest,
  ca_certificates_ensure => latest,
  require => Swap_file::Files['default'],
}

# TODO(AR) Temporary until letsencrypt/certbot is running correctly
openssl::dhparam { '/etc/letsencrypt/ssl-dhparams.pem':
  size => 2048,
  require => Swap_file::Files['default'],
}

# TODO(AR) Temporary until letsencrypt/certbot is running correctly
file { '/etc/letsencrypt/live':
  ensure => directory,
  require => Class['letsencrypt'],
}

# TODO(AR) Temporary until letsencrypt/certbot is running correctly
file { '/etc/letsencrypt/live/catalogue.nationalarchives.gov.uk':
  ensure => directory,
  require => File['/etc/letsencrypt/live'],
}

# TODO(AR) Temporary until letsencrypt/certbot is running correctly
file { '/etc/letsencrypt/live/mvpbeta.catalogue.nationalarchives.gov.uk':
  ensure => directory,
  require => File['/etc/letsencrypt/live'],
}

# TODO(AR) Temporary until letsencrypt/certbot is running correctly
class { '::openssl::certificates':
  x509_certs => { 
    'catalogue.nationalarchives.gov.uk/cert.pem' => {
      ensure      => 'present',
      base_dir => '/etc/letsencrypt/live',
      commonname  => "catalogue.nationalarchives.gov.uk",
      country      => 'GB',
      organization => 'The National Archives',
      locality     => 'Kew',
      state        => 'Greater London',
      unit         => 'Catalogue',
      email        => $sysops_email,
      crt => '/etc/letsencrypt/live/catalogue.nationalarchives.gov.uk/cert.pem',
      key => '/etc/letsencrypt/live/catalogue.nationalarchives.gov.uk/privkey.pem',
      days        => 365,
      force       => false,
    },
    'mvpbeta.catalogue.nationalarchives.gov.uk/cert.pem' => {
      ensure      => 'present',
      base_dir => '/etc/letsencrypt/live',
      commonname  => "mvpbeta.catalogue.nationalarchives.gov.uk",
      country      => 'GB',
      organization => 'The National Archives',
      locality     => 'Kew',
      state        => 'Greater London',
      unit         => 'Catalogue',
      email        => $sysops_email,
      crt => '/etc/letsencrypt/live/mvpbeta.catalogue.nationalarchives.gov.uk/cert.pem',
      key => '/etc/letsencrypt/live/mvpbeta.catalogue.nationalarchives.gov.uk/privkey.pem',
      days        => 365,
      force       => false,
    },
  },
  require => [
    Swap_file::Files['default'],
    File['/etc/letsencrypt/live/catalogue.nationalarchives.gov.uk'],
    File['/etc/letsencrypt/live/mvpbeta.catalogue.nationalarchives.gov.uk']
  ],
}

# TODO(AR) Temporary until letsencrypt/certbot is running correctly
file { '/etc/letsencrypt/options-ssl-nginx.conf':
  ensure  => file,
  mode    => '0644',
  content => "ssl_session_cache shared:le_nginx_SSL:10m;
ssl_session_timeout 1440m;
ssl_session_tickets off;

ssl_protocols TLSv1.2 TLSv1.3;
ssl_prefer_server_ciphers off;

ssl_ciphers \"ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384\";
"
}

yum::gpgkey { '/etc/pki/rpm-gpg/nginx_signing.key':
  ensure => present,
  source => 'https://nginx.org/keys/nginx_signing.key',
}

# NOTE(AR): Version of nginx offered by Amazon Linux is outdated, so use the nginx repo
file { '/etc/yum.repos.d/nginx.repo':
  ensure => file,
  content => "[nginx-stable]
name=nginx stable repo
baseurl=http://nginx.org/packages/centos/7/$basearch/
gpgcheck=1
enabled=1
gpgkey=https://nginx.org/keys/nginx_signing.key
module_hotfixes=true
",
  require => Yum::Gpgkey['/etc/pki/rpm-gpg/nginx_signing.key'],
}

class { 'nginx':
  require => [
    File['/etc/yum.repos.d/nginx.repo'],
    Swap_file::Files['default']
  ],
}

# Redirect catalogue.nationalarchives.gov.uk -> www.catalogue.nationalarchives.gov.uk
nginx::resource::server { 'catalogue.nationalarchives.gov.uk':
  ensure       => present,
  listen_options => 'default_server',
  ipv6_enable => true,
  ipv6_listen_options => 'default_server ipv6only=on',
  http2        => on,
  ssl          => true,
  ssl_redirect => true,
  ssl_cert => '/etc/letsencrypt/live/catalogue.nationalarchives.gov.uk/cert.pem',
  ssl_key => '/etc/letsencrypt/live/catalogue.nationalarchives.gov.uk/privkey.pem',
  server_cfg_ssl_append => {
      include => '/etc/letsencrypt/options-ssl-nginx.conf',
      ssl_dhparam => '/etc/letsencrypt/ssl-dhparams.pem',
  },
  location_cfg_append => {
    return       => '302 $scheme://www.catalogue.nationalarchives.gov.uk$request_uri',
  },
  require => [
    Swap_file::Files['default'],
    Class['openssl'],
    Openssl::Dhparam['/etc/letsencrypt/ssl-dhparams.pem'],
    Class['::openssl::certificates'],
    File['/etc/letsencrypt/options-ssl-nginx.conf'],
    Class['nginx']
  ],
}

# Redirect www.catalogue.nationalarchives.gov.uk -> www.mvpbeta.catalogue.nationalarchives.gov.uk
nginx::resource::server { 'www.catalogue.nationalarchives.gov.uk':
  ensure       => present,
  listen_options => '',
  ipv6_enable => true,
  ipv6_listen_options => '',
  http2        => on,
  ssl          => true,
  ssl_redirect => true,
  ssl_cert => '/etc/letsencrypt/live/catalogue.nationalarchives.gov.uk/cert.pem',
  ssl_key => '/etc/letsencrypt/live/catalogue.nationalarchives.gov.uk/privkey.pem',
  server_cfg_ssl_append => {
      include => '/etc/letsencrypt/options-ssl-nginx.conf',
      ssl_dhparam => '/etc/letsencrypt/ssl-dhparams.pem',
  },
  location_cfg_append => {
    return       => '302 $scheme://www.mvpbeta.catalogue.nationalarchives.gov.uk$request_uri',
  },
  require => [
    Swap_file::Files['default'],
    Class['openssl'],
    Openssl::Dhparam['/etc/letsencrypt/ssl-dhparams.pem'],
    Class['::openssl::certificates'],
    File['/etc/letsencrypt/options-ssl-nginx.conf'],
    Class['nginx']
  ],
}

# Redirect mvpbeta.catalogue.nationalarchives.gov.uk -> www.mvpbeta.catalogue.nationalarchives.gov.uk
nginx::resource::server { 'mvpbeta.catalogue.nationalarchives.gov.uk':
  ensure       => present,
  listen_options => '',
  ipv6_enable => true,
  ipv6_listen_options => '',
  http2        => on,
  ssl          => true,
  ssl_redirect => true,
  ssl_cert => '/etc/letsencrypt/live/mvpbeta.catalogue.nationalarchives.gov.uk/cert.pem',
  ssl_key => '/etc/letsencrypt/live/mvpbeta.catalogue.nationalarchives.gov.uk/privkey.pem',
  server_cfg_ssl_append => {
      include => '/etc/letsencrypt/options-ssl-nginx.conf',
      ssl_dhparam => '/etc/letsencrypt/ssl-dhparams.pem',
  },
  location_cfg_append => {
    return       => '302 $scheme://www.mvpbeta.catalogue.nationalarchives.gov.uk$request_uri',
  },
  require => [
    Swap_file::Files['default'],
    Class['openssl'],
    Openssl::Dhparam['/etc/letsencrypt/ssl-dhparams.pem'],
    Class['::openssl::certificates'],
    File['/etc/letsencrypt/options-ssl-nginx.conf'],
    Class['nginx']
  ],
}

nginx::resource::server { 'www.mvpbeta.catalogue.nationalarchives.gov.uk':
  ensure       => present,
  listen_options => '',
  ipv6_enable => true,
  ipv6_listen_options => '',
  http2        => on,
  ssl          => true,
  ssl_redirect => true,
  ssl_cert => '/etc/letsencrypt/live/mvpbeta.catalogue.nationalarchives.gov.uk/cert.pem',
  ssl_key => '/etc/letsencrypt/live/mvpbeta.catalogue.nationalarchives.gov.uk/privkey.pem',
  server_cfg_ssl_append => {
      include => '/etc/letsencrypt/options-ssl-nginx.conf',
      ssl_dhparam => '/etc/letsencrypt/ssl-dhparams.pem',
  },
  proxy        => 'https://10.128.238.36:9443',         # TODO(AR) make this injectable from Terraform via Facter
  require => [
    Swap_file::Files['default'],
    Class['openssl'],
    Openssl::Dhparam['/etc/letsencrypt/ssl-dhparams.pem'],
    Class['::openssl::certificates'],
    File['/etc/letsencrypt/options-ssl-nginx.conf'],
    Class['nginx']
  ],
}

class { 'letsencrypt':
  package_ensure => latest,
  renew_cron_ensure => present,
  email => $sysops_email,
  require => Swap_file::Files['default'],
}

class { 'letsencrypt::plugin::dns_route53':
  package_name => 'certbot-dns-route53',
  require => Swap_file::Files['default'],
}

# TODO(AR) Temporary until DNS is running correctly
#letsencrypt::certonly { 'catalogue.nationalarchives.gov.uk':
#  plugin  => 'dns-route53',
#  require => Class['letsencrypt::plugin::dns_route53'],
#}

# TODO(AR) Temporary until DNS is running correctly
#letsencrypt::certonly { 'mvpbeta.catalogue.nationalarchives.gov.uk':
#  plugin  => 'dns-route53',
#  require => Class['letsencrypt::plugin::dns_route53'],
#}

