locals {
    ca_private_key_file = "${var.export_path}/${var.id}-ca.private.key.pem"
    ca_public_key_file  = "${var.export_path}/${var.id}-ca.public.key.pem"
    ca_cert_file        = "${var.export_path}/${var.id}-ca.crt.pem"
}