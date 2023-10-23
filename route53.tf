resource "aws_route53_zone" "omega_public_dns" {
  name = local.public_dns_domain

  force_destroy = false

  tags = {
    name = "dns_zone"
  }
}

# delegate Private Zone (omg.catalogue.nationalarchives.gov.uk) from Public Zone (catalogue.nationalarchives.gov.uk)
resource "aws_route53_record" "omega_public_dns_nameservers" {
  zone_id         = aws_route53_zone.omega_public_dns.zone_id
  name            = local.private_omg_dns_domain
  type            = "NS"
  ttl             = 86400 # 24 Hours
  records         = aws_route53_zone.omega_private_omg_dns.name_servers
  allow_overwrite = true
}

output "omega_public_dns_servers" {
  description = "Public DNS Servers for Omega"
  value       = aws_route53_zone.omega_public_dns.name_servers
}

// TODO(AR) reinstate the www and * lookups when we have a public web presence
# resource "aws_route53_record" "dns_a_wildcard_in_catalogue_nationalarchives_gov_uk" {
#   zone_id = aws_route53_zone.omega_public_dns.zone_id
#   name    = "*.${local.public_dns_domain}"
#   type    = "A"
#   ttl     = "300"
#   records = data.aws_network_interface.web_proxy_1_private_interface.private_ips
# }

# resource "aws_route53_record" "dns_a_www_in_catalogue_nationalarchives_gov_uk" {
#   zone_id = aws_route53_zone.omega_public_dns.zone_id
#   name    = "www.${local.public_dns_domain}"
#   type    = "A"
#   ttl     = "300"
#   records = data.aws_network_interface.web_proxy_1_private_interface.private_ips
# }

# resource "aws_route53_record" "dns_aaaa_www_in_catalogue_nationalarchives_gov_uk" {
#   zone_id = aws_route53_zone.omega_public_dns.zone_id
#   name    = "www.${local.public_dns_domain}"
#   type    = "AAAA"
#   ttl     = "300"
#   records = data.aws_network_interface.web_proxy_1_private_interface.ipv6_addresses
# }

resource "aws_route53_zone" "omega_private_omg_dns" {
  name = local.private_omg_dns_domain

  vpc {
    vpc_id = module.vpc.vpc_id
  }

  force_destroy = true

  tags = {
    name = "dns_zone"
  }
}

module "omega_private_ipv4_omg_reverse_dns_name" {
  source = "./reverse-ipv4-address"

  ipv4_address                      = local.vpc_cidr_block
  reverse_dns_zone_name_class_count = 2
}

resource "aws_route53_zone" "omega_private_ipv4_omg_reverse_dns" {
  name = module.omega_private_ipv4_omg_reverse_dns_name.reverse_dns_zone_name

  vpc {
    vpc_id = module.vpc.vpc_id
  }

  force_destroy = true

  tags = {
    name = "dns_zone"
  }
}

module "omega_private_ipv6_omg_reverse_dns_name" {
  source = "./reverse-ipv6-address"

  ipv6_address                      = module.vpc.vpc_ipv6_cidr_block
  reverse_dns_zone_name_class_count = 15
}

resource "aws_route53_zone" "omega_private_ipv6_omg_reverse_dns" {
  name = module.omega_private_ipv6_omg_reverse_dns_name.reverse_dns_zone_name

  vpc {
    vpc_id = module.vpc.vpc_id
  }

  force_destroy = true

  tags = {
    name = "dns_zone"
  }
}

output "omega_private_omg_dns_servers" {
  description = "DNS Servers for Omega internal environment"
  value       = aws_route53_zone.omega_private_omg_dns.name_servers
}
