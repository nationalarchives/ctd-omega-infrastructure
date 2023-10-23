data "local_sensitive_file" "project_omega_private_client_vpn_server_private_key_new" {
  filename = ("ctd-omega-infrastructure-certificates/exported/project-omega-private-client-vpn-server.private.key.pem")
}

data "tls_certificate" "project_omega_private_client_vpn_server_chain_certificate_new" {
  content = file("ctd-omega-infrastructure-certificates/exported/project-omega-private-client-vpn-server.crt.chain.pem")
}

data "tls_certificate" "project_omega_private_client_vpn_server_certificate_new" {
  content = file("ctd-omega-infrastructure-certificates/exported/project-omega-private-client-vpn-server.crt.pem")
}

resource "aws_acm_certificate" "client_vpn_server_certificate_new" {
  private_key       = data.local_sensitive_file.project_omega_private_client_vpn_server_private_key_new.content
  certificate_chain = data.tls_certificate.project_omega_private_client_vpn_server_chain_certificate_new.content
  certificate_body  = data.tls_certificate.project_omega_private_client_vpn_server_certificate_new.content

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = "client_vpn_server_certificate_new"
    Scope       = "client-vpn-server-certificate-new"
    Environment = "vpn"
  }
}

