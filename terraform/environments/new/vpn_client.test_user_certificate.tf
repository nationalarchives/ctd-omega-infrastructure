/*
data "local_sensitive_file" "vpn_client_test_user_private_key" {
  filename = ("../../../../ctd-omega-infrastructure-certificates/exported/vpn-client-test-user.private.key.pem")
}

data "tls_certificate" "vpn_client_test_user_certificate_new" {
  content = file("../../../../ctd-omega-infrastructure-certificates/exported/vpn-client-test-user.crt.pem")
}

resource "aws_acm_certificate" "vpn_client_test_user_certificate" {
  private_key       = data.local_sensitive_file.vpn_client_test_user_private_key.content
  certificate_chain = data.tls_certificate.project_omega_private_vpn_client_root_ca_chain_certificate_new.content
  certificate_body  = data.tls_certificate.vpn_client_test_user_certificate_new.content

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = "vpn client test user certificate"
    Scope       = "vpn_client"
    Environment = "vpn"
  }
}

output "vpn_client_test_user_certificate_private_key" {
  description = "VPN Client 'test' User Certificate Private Key"
  value       = data.local_sensitive_file.vpn_client_test_user_private_key.content
  sensitive = true
}

output "vpn_client_test_user_certificate" {
  description = "VPN Client 'test' User Certificate"
  value       = aws_acm_certificate.vpn_client_test_user_certificate
  sensitive = true
}
*/
