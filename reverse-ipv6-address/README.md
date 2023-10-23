# Reverse IPv6 Address Terraform module

Terraform module which reverses an IPv6 Address. This can be useful when setting up reverse DNS zones.

## Usage

### Example 1 - Reverse DNS PTR Records

```hcl
module "my_reverse_ipv6_address_1" {
  source = "./reverse-ipv6-address"

  ipv6_address = "2a05:d01c:7:1a08:409e:ace2:8440:1334"
}

output "my_reverse_ipv6_address_1" {
  description = "Reverse of my IPv6 Address"
  value       = module.my_reverse_ipv6_address_1.reverse_ipv6_address
}

output "my_reverse_dns_ptr_name_1" {
  description = "Reverse DNS PTR record for my IPv6 Address"
  value       = module.my_reverse_ipv6_address_1.reverse_dns_name
}
```

* The output value of `my_reverse_ipv6_address_1` will be `1334:8440:ace2:409e:1a08:0007:d01c:2a05`.
* The output value of `my_reverse_dns_ptr_name_1` will be `4.3.3.1.0.4.4.8.2.e.c.a.e.9.0.4.8.0.a.1.7.0.0.0.c.1.0.d.5.0.a.2.ip6.arpa`.

### Example 2 - Reverse DNS Zone Naming

```hcl
module "my_reverse_ipv6_zone_name" {
  source = "./reverse-ipv6-address"

  ipv6_address                      = "2a05:d01c:7:1a00::/56"
  reverse_dns_zone_name_class_count = 15
}

output "my_reverse_ipv6_dns_zone_name" {
  description = "Reverse DNS Zone Name record for my IPv6 CIDR"
  value       = module.my_reverse_ipv6_zone_name.reverse_dns_name
}
```

* The output value of `my_reverse_ipv6_dns_zone_name` will be `0.a.1.7.0.0.0.c.1.0.d.5.0.a.2.ip6.arpa`.

## Inputs

| Name | Description |
| ---- | ----------- |
| ipv6_address | The IPv4 Address that should be reversed |
| reverse_dns_zone_name_class_count | The number of clases that should be included in the reversed IPv6 Address (counting from right-to-left in the reversed address). Default: 32 |

## Outputs

| Name | Description |
| ---- | ----------- |
| reverse_ipv6_address_list | The reversed IPv6 Address as a list |
| reverse_ipv6_address | The reversed IPv6 Address as a string |
| reverse_dns_zone_name | The name of a Reverse DNS Zone for the reversed IPv6 Address. The number of classes in the name is controlled by the variable 'reverse_dns_zone_name_class_count' |
