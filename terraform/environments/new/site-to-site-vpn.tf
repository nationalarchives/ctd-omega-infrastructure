resource "aws_ec2_transit_gateway_vpc_attachment" "tna-site-to-site-vpn" {

  subnet_ids = [
    module.vpc.private_subnets[8],
    module.vpc.private_subnets[9]
  ]

  transit_gateway_id = local.tna_transit_gateway_id
  vpc_id             = module.vpc.vpc_id

  appliance_mode_support = "disable"

  ipv6_support = "enable"
  dns_support  = "enable"

  transit_gateway_default_route_table_association = true
  transit_gateway_default_route_table_propagation = true

  tags = {
    Name = "tna-transit-gateway-attachment"
  }
}

output "tna-site-to-site-vpn-tgw-attachment-id" {
  value       = aws_ec2_transit_gateway_vpc_attachment.tna-site-to-site-vpn.id
  description = "The ID of Project Omega's Transit Gateway Attachment to the TNA Site-to-Site VPN"
}

// START TEMP site-to-site VPN testing with Steve Hirschorn
resource "aws_route" "tna_steve_hirschorn_test" {
  route_table_id = module.vpc.private_route_table_ids[0]
  destination_cidr_block = "10.112.41.0/24"
  transit_gateway_id = local.tna_transit_gateway_id
}
// END TEMP
