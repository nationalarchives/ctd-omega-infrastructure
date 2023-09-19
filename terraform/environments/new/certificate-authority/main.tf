# Private/Public Key for the CA
resource "tls_private_key" "ca_private_key" {
    algorithm = "RSA"
    rsa_bits  = 4096
}

# Persist the CA Public Key, and Private Key
resource "local_file" "ca_public_key_file" {
    count = var.export_path == null ? 0 : 1

    filename = local.ca_public_key_file
    content  = tls_private_key.ca_private_key.public_key_pem
}
resource "local_sensitive_file" "ca_private_key_file" {
    count = var.export_path == null ? 0 : 1

    filename = local.ca_private_key_file
    content  = tls_private_key.ca_private_key.private_key_pem
}
