output "certificate_pem" {
    description = "The Certificate"
    value       = element(compact([
        one(tls_self_signed_cert.ss_certificate[*].cert_pem),
        one(tls_locally_signed_cert.cas_certificate[*].cert_pem)
    ]), 0)

    depends_on = [
        tls_self_signed_cert.ss_certificate,
        tls_locally_signed_cert.cas_certificate
    ]
}

output "public_key_pem" {
    description = "The Public Key"
    value       = tls_private_key.private_key.public_key_pem
}

output "private_key_pem" {
    description = "The Private Key"
    value       = tls_private_key.private_key.private_key_pem
}

output "certificate_pem_exported_filename" {
    description = "The filename of the exported Certificate"
    value       = local.cert_file

    depends_on = [
        local_file.ss_certificate_file,
        local_file.cas_certificate_file
    ]
}

output "public_key_pem_exported_filename" {
    description = "The filename of the exported Public Key"
    value       = local.public_key_file

    depends_on = [
        local_file.public_key_file
    ]
}

output "private_key_pem_exported_filename" {
    description = "The filename of the exported Private Key"
    value       = local.private_key_file

    depends_on = [
        local_sensitive_file.private_key_file
    ]
}
