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
