output "ca_certificate_pem_exported_filename" {
    description = "The filename of the exported CA Certificate"
    value       = var.export_path == null ? null : local.ca_cert_file

    depends_on = [
        local_file.root_ca_certificate_file
    ]
}

output "ca_public_key_pem_exported_filename" {
    description = "The filename of the exported CA Public Key"
    value       = var.export_path == null ? null : local.ca_public_key_file

    depends_on = [
        local_file.ca_public_key_file
    ]
}

output "ca_private_key_pem_exported_filename" {
    description = "The filename of the exported CA Private Key"
    value       = var.export_path == null ? null : local.ca_private_key_file

    depends_on = [
        local_sensitive_file.ca_private_key_file
    ]
}
