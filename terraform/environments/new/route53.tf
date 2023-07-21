resource "aws_route53_zone" "omega_public_dns" {
  name = local.public_dns_domain

  tags = {
    name = "dns_zone"
  }
}

resource "aws_route53_record" "omega_public_dns_nameservers" {
  allow_overwrite = true
  name            = local.public_dns_domain
  ttl             = 86400 # 24 Hours
  type            = "NS"
  zone_id         = aws_route53_zone.omega_public_dns.zone_id
  records         = aws_route53_zone.omega_public_dns.name_servers
}

output "omega_public_dns_servers" {
  description = "Public DNS Servers for Omega"
  value       = aws_route53_zone.omega_public_dns.name_servers
}

resource "aws_route53_record" "dns_a_wildcard_in_catalogue_nationalarchives_gov_uk" {
  zone_id = aws_route53_zone.omega_public_dns.zone_id
  name    = "*.${local.public_dns_domain}"
  type    = "A"
  ttl     = "300"
  records = data.aws_network_interface.web_proxy_1_private_interface.private_ips
}

resource "aws_route53_record" "dns_a_www_in_catalogue_nationalarchives_gov_uk" {
  zone_id = aws_route53_zone.omega_public_dns.zone_id
  name    = "www.${local.public_dns_domain}"
  type    = "A"
  ttl     = "300"
  records = data.aws_network_interface.web_proxy_1_private_interface.private_ips
}

resource "aws_route53_zone" "omega_private_omg_dns" {
  name = local.private_omg_dns_domain

  vpc {
    vpc_id = module.vpc.vpc_id
  }

  tags = {
    name = "dns_zone"
  }
}

output "omega_private_omg_dns_servers" {
  description = "DNS Servers for Omega internal environment"
  value       = aws_route53_zone.omega_private_omg_dns.name_servers
}

resource "aws_route53_record" "dns_a_web_proxy_1_in_omg_catalogue_nationalarchives_gov_uk" {
  zone_id = aws_route53_zone.omega_private_omg_dns.zone_id
  name    = "web-proxy-1.${local.private_omg_dns_domain}"
  type    = "A"
  ttl     = "300"
  records = data.aws_network_interface.web_proxy_1_private_interface.private_ips
}

resource "aws_route53_record" "dns_a_web_app_1_in_omg_catalogue_nationalarchives_gov_uk" {
  zone_id = aws_route53_zone.omega_private_omg_dns.zone_id
  name    = "web-app-1.${local.private_omg_dns_domain}"
  type    = "A"
  ttl     = "300"
  records = data.aws_network_interface.web_app_1_private_interface.private_ips
}

resource "aws_route53_record" "dns_a_services_api_1_in_omg_catalogue_nationalarchives_gov_uk" {
  zone_id = aws_route53_zone.omega_private_omg_dns.zone_id
  name    = "services-api-1.${local.private_omg_dns_domain}"
  type    = "A"
  ttl     = "300"
  records = data.aws_network_interface.services_api_1_private_interface.private_ips
}

resource "aws_route53_record" "dns_a_puppet_server_1_in_omg_catalogue_nationalarchives_gov_uk" {
  zone_id = aws_route53_zone.omega_private_omg_dns.zone_id
  name    = "puppet-server-1.${local.private_omg_dns_domain}"
  type    = "A"
  ttl     = "300"
  records = data.aws_network_interface.puppet_server_1_private_interface.private_ips
}

resource "aws_route53_record" "dns_a_dev1_in_omg_catalogue_nationalarchives_gov_uk" {
  zone_id = aws_route53_zone.omega_private_omg_dns.zone_id
  name    = "dev1.${local.private_omg_dns_domain}"
  type    = "A"
  ttl     = "300"
  records = data.aws_network_interface.dev_workstation_1_private_interface.private_ips
}

resource "aws_route53_record" "dns_a_dev2_in_omg_catalogue_nationalarchives_gov_uk" {
  zone_id = aws_route53_zone.omega_private_omg_dns.zone_id
  name    = "dev2.${local.private_omg_dns_domain}"
  type    = "A"
  ttl     = "300"
  records = data.aws_network_interface.dev_workstation_2_private_interface.private_ips
}

resource "aws_route53_record" "dns_a_mssql1_in_omg_catalogue_nationalarchives_gov_uk" {
  zone_id = aws_route53_zone.omega_private_omg_dns.zone_id
  name    = "mssql1.${local.private_omg_dns_domain}"
  type    = "A"
  ttl     = "300"
  records = data.aws_network_interface.dev_mssql_server_1_database_interface.private_ips
}