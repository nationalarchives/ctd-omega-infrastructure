output "ec2_instance_arn" {
  description = "The ARN of the created EC2 instance"
  value       = aws_instance.ec2_instance.arn
}

output "ec2_private_ip" {
  description = "The IPv4 address of the created EC2 instance"
  value       = data.aws_network_interface.ec2_instance_private_interface[0].private_ip
}

output "ec2_private_ipv6" {
  description = "The IPv6 address of the created EC2 instance"
  value       = tolist(data.aws_network_interface.ec2_instance_private_interface[0].ipv6_addresses)[0]
}

output "ec2_iam_instance_profile_arn" {
  description = "The ARN of the assigned IAM Instance Profile assigned to the EC2 host"
  value       = data.aws_iam_instance_profile.ec2_iam_instance_profile.arn
}

output "ec2_iam_instance_profile_role_arn" {
  description = "The ARN of the role of the assigned IAM Instance Profile assigned to the EC2 host"
  value       = data.aws_iam_instance_profile.ec2_iam_instance_profile.role_arn
}

output "puppet_ca_certificate_pem" {
  description = "The Puppet CA Certificate"
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