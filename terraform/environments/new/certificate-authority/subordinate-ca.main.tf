resource "tls_cert_request" "subordinate_ca_certificate_request" {
  count = var.root_ca == null ? 0 : 1  # only run if we are creating a Subordinate CA

  private_key_pem = tls_private_key.ca_private_key.private_key_pem

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
}

resource "tls_locally_signed_cert" "subordinate_ca_certificate" {
  count = var.root_ca != null ? 1 : 0  # only run if we are creating a Subordinate CA

  cert_request_pem   = tls_cert_request.subordinate_ca_certificate_request[0].cert_request_pem
  ca_private_key_pem = lookup(var.root_ca, "private_key_pem", null)
  ca_cert_pem        = lookup(var.root_ca, "certificate_pem", null)

  is_ca_certificate = true

  allowed_uses = [
        "cert_signing",
        "crl_signing"
  ]

  validity_period_hours = var.expiry_days * 24
  early_renewal_hours   = var.early_renewal_hours
#   set_authority_key_id  = true
  set_subject_key_id    = true
}

# Persist the Subordinate CA Certificate
resource "local_file" "subordinate_ca_certificate_file" {
    count = var.root_ca != null && var.export_path != null ? 1 : 0  # only run if we are creating a Subordinate CA

    filename = local.ca_cert_file
    content  = tls_locally_signed_cert.subordinate_ca_certificate[0].cert_pem
}
