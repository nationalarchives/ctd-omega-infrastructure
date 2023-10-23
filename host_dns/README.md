# Host DNS Terraform module

Terraform module which creates DNS records for a host. You may create:
1. IPv4 A record
2. IPv4 PTR record
3. IPv6 AAAA record
4. IPv6 PTR record

## Usage

### Example 1 - IPv4 and IPv6 forward and reverse DNS

This is an example of DNS for IPv4 and IPv6 forward and reverse records.

```hcl
module my_host_1_dns" {
  source = "../host_dns"

  fqdn = "my_host_1.mydomain.com"

  zone_id = aws_route53_zone.my_zone.zone_id
  ipv4    = {
    addresses       = [data.aws_network_interface.my_host_1.private_ips]
    reverse_zone_id = aws_route53_zone.my_zone_reverse_ipv4.zone_id
  }
  ipv6    = {
    addresses       = data.aws_network_interface.my_host_1.ipv6_addresses
    reverse_zone_id = aws_route53_zone.my_zone_reverse_ipv6.zone_id
  }
}
```
