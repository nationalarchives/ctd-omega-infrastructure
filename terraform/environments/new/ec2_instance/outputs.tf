output "puppet_ca_certificate_pem" {
    description = "The Puppet CA Certificate"
    # value       = element(compact([
    #     one(tls_self_signed_cert.ss_certificate[*].cert_pem),
    #     one(tls_locally_signed_cert.cas_certificate[*].cert_pem)
    # ]), 0)
    value       = one(module.puppet_certificate_authority[*].certificate_pem)
}

output "puppet_ca_public_key_pem" {
    description = "The Puppet CA Public Key"
    value       = one(module.puppet_certificate_authority[*].public_key_pem)
}

output "puppet_ca_private_key_pem" {
    description = "The Puppet CA Private Key"
    value       = one(module.puppet_certificate_authority[*].private_key_pem)
    sensitive   = true
}

output "puppet_agent_certificate_pem" {
    description = "The Puppet Agent Certificate"
    # value       = element(compact([
    #     one(tls_self_signed_cert.ss_certificate[*].cert_pem),
    #     one(tls_locally_signed_cert.cas_certificate[*].cert_pem)
    # ]), 0)
    value       = one(module.puppet_agent_certificate[*].certificate_pem)
}

output "puppet_agent_public_key_pem" {
    description = "The Puppet Agent Public Key"
    value       = one(module.puppet_agent_certificate[*].public_key_pem)
}

output "puppet_agent_private_key_pem" {
    description = "The Puppet Agent Private Key"
    value       = one(module.puppet_agent_certificate[*].private_key_pem)
    sensitive   = true
}