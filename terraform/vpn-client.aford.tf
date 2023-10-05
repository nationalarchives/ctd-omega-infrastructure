resource "tls_private_key" "aford_vpn_client_certificate_private_key" {
  algorithm = "RSA"
  rsa_bits  = "2048"
}

resource "tls_cert_request" "aford_vpn_client_certificate_signing_request" {
  private_key_pem = tls_private_key.aford_vpn_client_certificate_private_key.private_key_pem

  subject {
    common_name         = "aford.vpn-client.cat.nationalarchives.gov.uk"

    organizational_unit = "The Cataloguing, Taxonomy, and Data Team"
    organization        = "The National Archives"
    street_address      = ["Bessant Drive"]
    locality            = "Kew"
    province            = "London"
    country             = "GB"
    postal_code         = "TW9 4DU"
  }
}

resource "aws_acmpca_certificate" "aford_vpn_client_certificate" {
  certificate_authority_arn   = aws_acmpca_certificate_authority.vpn_client_ca.arn
  certificate_signing_request = tls_cert_request.aford_vpn_client_certificate_signing_request.cert_request_pem
  signing_algorithm           = "SHA512WITHRSA"
  validity {
    type  = "YEARS"
    value = 1
  }
}

resource "aws_acm_certificate" "aford_vpn_client_certificate" {
  private_key       = tls_private_key.aford_vpn_client_certificate_private_key.private_key_pem
  certificate_body  = aws_acmpca_certificate.aford_vpn_client_certificate.certificate
  certificate_chain = aws_acmpca_certificate.aford_vpn_client_certificate.certificate_chain

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = "certificate"
    Scope       = "vpn_client"
    Environment = "vpn"
  }
}

output "aford_vpn_client_certificate_private_key" {
  description = "VPN Client 'aford' User Certificate Private Key"
  value       = tls_private_key.aford_vpn_client_certificate_private_key.private_key_pem

  sensitive = true
}

output "aford_vpn_client_certificate" {
  description = "VPN Client 'aford' User Certificate"
  value       = aws_acmpca_certificate.aford_vpn_client_certificate.certificate
}
