# Self-signed Certificate
resource "tls_self_signed_cert" "ss_certificate" {
    count = var.ca == null ? 1 : 0  # only run if we are creating a Self-signed certificate

    private_key_pem = tls_private_key.private_key.private_key_pem

    is_ca_certificate = var.is_ca_certificate

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

    allowed_uses = local.allowed_uses

    dns_names = var.dns_names

    validity_period_hours = var.expiry_days * 24
    early_renewal_hours   = var.early_renewal_hours
    set_authority_key_id  = true
    set_subject_key_id    = true
}

# Persist the Self-signed Certificate
resource "local_file" "ss_certificate_file" {
    count = var.ca == null && var.export_path != null ? 1 : 0  # only run if we are creating a Self-signed certificate

    filename = local.cert_file
    content  = tls_self_signed_cert.ss_certificate[0].cert_pem
}