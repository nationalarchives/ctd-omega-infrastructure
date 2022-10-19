
resource "tls_private_key" "jdavey_vpn_client_certificate_private_key" {
  algorithm = "RSA"
  rsa_bits  = "2048"
}

resource "tls_cert_request" "jdavey_vpn_client_certificate_signing_request" {
  private_key_pem = tls_private_key.jdavey_vpn_client_certificate_private_key.private_key_pem

  subject {
    common_name         = "jdavey.vpn-client.cat.nationalarchives.gov.uk"
    organizational_unit = "Engineering"
    organization        = "JD Code"
    street_address      = ["Greatfields Road"]
    locality            = "Barking"
    province            = "Essex"
    country             = "GB"
    postal_code         = "IG11 7TZ"
  }
}

resource "aws_acmpca_certificate" "jdavey_vpn_client_certificate" {
  certificate_authority_arn   = aws_acmpca_certificate_authority.vpn_client_ca.arn
  certificate_signing_request = tls_cert_request.jdavey_vpn_client_certificate_signing_request.cert_request_pem
  signing_algorithm           = "SHA512WITHRSA"
  validity {
    type  = "YEARS"
    value = 1
  }
}

resource "aws_acm_certificate" "jdavey_vpn_client_certificate" {
  private_key       = tls_private_key.jdavey_vpn_client_certificate_private_key.private_key_pem
  certificate_body  = aws_acmpca_certificate.jdavey_vpn_client_certificate.certificate
  certificate_chain = aws_acmpca_certificate.jdavey_vpn_client_certificate.certificate_chain

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = "certificate"
    Scope       = "vpn_client"
    Environment = "vpn"
  }
}

output "jdavey_vpn_client_certificate_private_key" {
  description = "VPN Client 'jdavey' User Certificate Private Key"
  value       = tls_private_key.jdavey_vpn_client_certificate_private_key.private_key_pem

  sensitive = true
}

output "jdavey_vpn_client_certificate" {
  description = "VPN Client 'jdavey' User Certificate"
  value       = aws_acmpca_certificate.jdavey_vpn_client_certificate.certificate
}
