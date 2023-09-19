resource "tls_cert_request" "cas_certificate_request" {
  count = var.ca == null ? 0 : 1  # only run if we are creating a CA signed certificate

  private_key_pem = tls_private_key.private_key.private_key_pem

  subject {
      common_name         = lookup(var.subject, "common_name", null)
      organizational_unit = lookup(var.subject, "organizational_unit", null)
      organization        = lookup(var.subject, "organization", null)
      # street_address      = lookup(var.subject, "street_address", [])
      locality            = lookup(var.subject, "locality", null)
      province            = lookup(var.subject, "province", null)
      country             = lookup(var.subject, "country", null)
      postal_code         = lookup(var.subject, "postal_code", null)
      serial_number       = lookup(var.subject, "serial_number", null)
  }

  dns_names = var.dns_names
}

resource "tls_locally_signed_cert" "cas_certificate" {
  count = var.ca != null ? 1 : 0  # only run if we are creating a CA signed certificate

  cert_request_pem   = tls_cert_request.cas_certificate_request[0].cert_request_pem
  ca_private_key_pem = lookup(var.ca, "private_key_pem", null)
  ca_cert_pem        = lookup(var.ca, "certificate_pem", null)

  is_ca_certificate = var.is_ca_certificate

  allowed_uses = local.allowed_uses

  validity_period_hours = var.expiry_days * 24
  early_renewal_hours   = var.early_renewal_hours
#   set_authority_key_id  = true
  set_subject_key_id    = true
}

# Persist the CA signed certificate
resource "local_file" "cas_certificate_file" {
    count = var.ca != null && var.export_path != null ? 1 : 0  # only run if we are creating a CA signed certificate

    filename = local.cert_file
    content  = tls_locally_signed_cert.cas_certificate[0].cert_pem
}
