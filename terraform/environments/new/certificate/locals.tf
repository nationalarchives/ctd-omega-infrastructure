locals {

    ca_certificate_uses = [
        "cert_signing",
        "crl_signing"
    ]

    certificate_uses = [
        "digital_signature",
        "key_encipherment",
        "client_auth",
        "server_auth"
    ]

    allowed_uses = var.is_ca_certificate ? local.ca_certificate_uses : local.certificate_uses

    filename_postfix = var.is_ca_certificate ? "-ca" : ""

    private_key_file = "${var.export_path}/${var.id}${local.filename_postfix}.private.key.pem"
    public_key_file  = "${var.export_path}/${var.id}${local.filename_postfix}.public.key.pem"
    cert_file        = "${var.export_path}/${var.id}${local.filename_postfix}.crt.pem"
}