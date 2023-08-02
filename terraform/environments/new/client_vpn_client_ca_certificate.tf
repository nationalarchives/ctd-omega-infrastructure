data "local_sensitive_file" "project_omega_private_client_vpn_ca_private_key_new" {
  filename = ("../../../ctd-omega-infrastructure-certificates/exported/project-omega-private-client-vpn-ca.private.key.pem")
}

data "tls_certificate" "project_omega_private_client_vpn_ca_chain_certificate_new" {
  content = file("../../../ctd-omega-infrastructure-certificates/exported/project-omega-private-client-vpn-ca.crt.chain.pem")
}

data "tls_certificate" "project_omega_private_client_vpn_ca_certificate_new" {
  content = file("../../../ctd-omega-infrastructure-certificates/exported/project-omega-private-client-vpn-ca.crt.pem")
}

resource "aws_acm_certificate" "client_vpn_ca_certificate_new" {
  private_key       = data.local_sensitive_file.project_omega_private_client_vpn_ca_private_key_new.content
  certificate_chain = data.tls_certificate.project_omega_private_client_vpn_ca_chain_certificate_new.content
  certificate_body  = data.tls_certificate.project_omega_private_client_vpn_ca_certificate_new.content

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = "client_vpn_ca_certificate_new"
    Scope       = "client-vpn-ca-certificate-new"
    Environment = "vpn"
  }
}
