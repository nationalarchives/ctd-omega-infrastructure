output "reverse_ipv6_address_list" {
  description = "The reversed IPv6 Address as a list"
  value       = local.reverse_ipv6_address_list
}

output "reverse_ipv6_address" {
  description = "The reversed IPv6 Address as a string"
  value       = join(":", local.reverse_ipv6_address_list)
}

output "reverse_dns_zone_name" {
  description = "The name of a Reverse DNS Zone for the reversed IPv6 Address. The number of classes in the name is controlled by the variable 'reverse_dns_zone_name_class_count'"
  value       = "${join(".", slice(local.reverse_ipv6_address_list_segments, max(length(local.reverse_ipv6_address_list_segments), var.reverse_dns_zone_name_class_count) - var.reverse_dns_zone_name_class_count, length(local.reverse_ipv6_address_list_segments)))}.ip6.arpa"
}
