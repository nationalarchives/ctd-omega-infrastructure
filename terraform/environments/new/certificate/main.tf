# Private/Public Key for the Certificate
resource "tls_private_key" "private_key" {
    algorithm = "RSA"
    rsa_bits  = 4096
}

# Export the Certificate Public Key to a file
resource "local_file" "public_key_file" {
    count = var.export_path == null ? 0 : 1

    filename = local.public_key_file
    content  = tls_private_key.private_key.public_key_pem
}

# Export the Certificate Prvate Key to a file
resource "local_sensitive_file" "private_key_file" {
    count = var.export_path == null ? 0 : 1

    filename = local.private_key_file
    content  = tls_private_key.private_key.private_key_pem
}
