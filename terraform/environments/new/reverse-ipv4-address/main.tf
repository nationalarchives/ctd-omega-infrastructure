locals {
  clean_ipv4_address = replace(var.ipv4_address, "/^([^/]+)(?:/[0-9]+)?/", "$1")

  ipv4_address_list = split(".", local.clean_ipv4_address)

  reverse_ipv4_address_list = reverse(local.ipv4_address_list)
}
