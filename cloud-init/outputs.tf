output "rendered" {
  description = "The rendered cloud-init config"
  value       = data.cloudinit_config.computed.rendered
}