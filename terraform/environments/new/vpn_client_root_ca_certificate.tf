data "local_sensitive_file" "project_omega_private_vpn_client_root_ca_private_key_new" {
  filename = ("../../../../ctd-omega-infrastructure-certificates/exported/project-omega-private-vpn-client-ca.private.key.pem")
}

data "tls_certificate" "project_omega_private_vpn_client_root_ca_chain_certificate_new" {
  content = file("../../../../ctd-omega-infrastructure-certificates/exported/project-omega-private-vpn-client-ca.crt.chain.pem")
}

data "tls_certificate" "project_omega_private_vpn_client_root_ca_certificate_new" {
  content = file("../../../../ctd-omega-infrastructure-certificates/exported/project-omega-private-vpn-client-ca.crt.pem")
}

resource "aws_acm_certificate" "vpn_client_root_ca_certificate_new" {
  private_key       = data.local_sensitive_file.project_omega_private_vpn_client_root_ca_private_key_new.content
  certificate_chain = data.tls_certificate.project_omega_private_vpn_client_root_ca_chain_certificate_new.content
  certificate_body  = data.tls_certificate.project_omega_private_vpn_client_root_ca_certificate_new.content

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = "vpn_client_root_ca_certificate_new"
    Scope       = "vpn-client-root-ca-certificate-new"
    Environment = "vpn"
  }
}