# Reverse IPv4 Address Terraform module

Terraform module which reverses an IPv4 Address. This can be useful when setting up reverse DNS zones.

## Usage

### Example 1 - Reverse DNS PTR Records

```hcl
module "my_reverse_ipv4_address_1" {
  source = "./reverse-ipv4-address"

  ipv4_address = "1.2.3.4"
}

output "my_reverse_ipv4_address_1" {
  description = "Reverse of my IPv4 Address"
  value       = module.my_reverse_ipv4_address_1.reverse_ipv4_address
}

output "my_reverse_dns_ptr_name_1" {
  description = "Reverse DNS PTR record for my IPv4 Address"
  value       = module.my_reverse_ipv4_address_1.reverse_dns_name
}
```

* The output value of `my_reverse_ipv4_address_1` will be `4.3.2.1`.
* The output value of `my_reverse_dns_ptr_name_1` will be `4.3.2.1.in-addr.arpa`.


### Example 2 - Reverse DNS Zone Naming

```hcl
module "my_reverse_ipv4_zone_name" {
  source = "./reverse-ipv4-address"

  ipv4_address                      = "1.2.3.4/18"
  reverse_dns_zone_name_class_count = 2
}

output "my_reverse_ipv4_dns_zone_name" {
  description = "Reverse DNS Zone Name record for my IPv4 CIDR"
  value       = module.my_reverse_ipv4_zone_name.reverse_dns_name
}
```

* The output value of `my_reverse_ipv4_dns_zone_name` will be `2.1.in-addr.arpa`.


## Inputs

| Name | Description |
| ---- | ----------- |
| ipv4_address | The IPv4 Address that should be reversed |
| reverse_dns_zone_name_class_count | The number of clases that should be included in the reversed IPv4 Address (counting from right-to-left in the reversed address). Default: 4 |

## Outputs

| Name | Description |
| ---- | ----------- |
| reverse_ipv4_address_list | The reversed IPv4 Address as a list |
| reverse_ipv4_address | The reversed IPv4 Address as a string |
| reverse_dns_zone_name | The name of a Reverse DNS Zone for the reversed IPv4 Address. The number of classes in the name is controlled by the variable 'reverse_dns_zone_name_class_count' |
