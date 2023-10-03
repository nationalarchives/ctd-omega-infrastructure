# DNS for IPv4
resource "aws_route53_record" "dns_ipv4" {
  zone_id = var.zone_id
  name    = var.fqdn
  type    = "A"
  ttl     = "300"
  records = var.ipv4.addresses
}

# DNS for reverse IPv4
module "reverse_ipv4_address" {
  source = "../reverse-ipv4-address"

  count = var.ipv4.reverse_zone_id == null ? 0 : 1

  ipv4_address = var.ipv4.addresses[0]
}

resource "aws_route53_record" "reverse_dns_ipv4" {
  count = var.ipv4.reverse_zone_id == null ? 0 : 1

  zone_id = var.ipv4.reverse_zone_id
  name    = module.reverse_ipv4_address[0].reverse_dns_zone_name
  type    = "PTR"
  ttl     = "300"
  records = [aws_route53_record.dns_ipv4.name]
}

# DNS for IPv6
resource "aws_route53_record" "dns_ipv6" {
  count =  var.ipv6 == null ? 0 : 1

  zone_id = var.zone_id
  name    = var.fqdn
  type    = "AAAA"
  ttl     = "300"
  records = var.ipv6.addresses
}

# DNS for reverse IPv6
module "reverse_ipv6_address" {
  source = "../reverse-ipv6-address"

  count = var.ipv6 == null || var.ipv6.reverse_zone_id == null ? 0 : 1

  ipv6_address = var.ipv6.addresses[0]
}

resource "aws_route53_record" "reverse_dns_ipv6" {
  count = var.ipv6 == null || var.ipv6.reverse_zone_id == null ? 0 : 1

  zone_id = var.ipv6.reverse_zone_id
  name    = module.reverse_ipv6_address[0].reverse_dns_zone_name
  type    = "PTR"
  ttl     = "300"
  records = [aws_route53_record.dns_ipv6[0].name]
}
