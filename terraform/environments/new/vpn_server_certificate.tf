resource "aws_acm_certificate" "cvpn_server_new" {
  key_algorithm = "RSA_2048"

  domain_name = local.public_dns_domain

  validation_method = "DNS"

  validation_option {
    domain_name       = local.public_dns_domain
    validation_domain = local.public_dns_domain
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "acm-records" {
  for_each = {
    for dvo in aws_acm_certificate.cvpn_server_new.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records = [
    each.value.record
  ]

  ttl     = 60
  type    = each.value.type
  zone_id = aws_route53_zone.omega_public_dns.zone_id
}

resource "aws_acm_certificate_validation" "acm-validation" {
  certificate_arn         = aws_acm_certificate.cvpn_server_new.arn
  validation_record_fqdns = [for record in aws_route53_record.acm-records : record.fqdn]

  timeouts {
    create = "3m"
  }
}
