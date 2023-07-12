resource "aws_network_interface" "web_proxy_1_private_interface" {
  description        = "Private MVP Beta TNA Network Access Subnet interface for web-proxy-1"
  subnet_id          = module.vpc.private_subnets[8] # 9 of 10
  private_ips        = ["172.28.0.4"] # ["10.128.200.4"] ## private mvp beta tna access subnet AZ=2a 172.28.0.0/27
  ipv6_address_count = 0 # use assign_ipv6_address_on_creation=true from the vpc subnet configuration

  tags = {
    Name        = "eth0_omg_web_proxy_1"
    Type        = "primary_network_interface"
    Network     = "omg_private"
    Environment = "omg"
  }
}

resource "aws_network_interface" "web_app_1_private_interface" {
  description        = "Private MVP Beta Web Subnet Interface for web-app-1"
  subnet_id          = module.vpc.private_subnets[4] # {5 of 10}
  private_ips        = ["172.27.1.4"] # private mvp beta web subnet AZ=2a 172.27.1.0/24
  ipv6_address_count = 0 # use assign_ipv6_address_on_creation=true from the vpc subnet configuration

  tags = {
    Name        = "eth0_omg_web_app_1"
    Type        = "primary_network_interface"
    Network     = "omg_private"
    Environment = "omg"
  }
}

data "aws_network_interface" "web_proxy_1_private_interface" {
  id = aws_network_interface.web_proxy_1_private_interface.id
}

data "aws_network_interface" "web_app_1_private_interface" {
  id = aws_network_interface.web_app_1_private_interface.id
}

/*
resource "aws_network_interface" "dev_workstation_3_private_interface" {
  description        = "Private Subnet Interface for Dev Workstation 3"
  subnet_id          = module.vpc.private_subnets[0]
  private_ips        = ["10.128.238.6"]
  ipv6_address_count = 0 # use assign_ipv6_address_on_creation=true from the vpc subnet configuration

  security_groups = [
    module.dev_workstation_security_group.security_group_id
  ]

  tags = {
    Name        = "eth0_dev3"
    Type        = "primary_network_interface"
    Network     = "dev_private"
    Environment = "dev"
  }
}

data "aws_network_interface" "dev_workstation_3_private_interface" {
  id = aws_network_interface.dev_workstation_3_private_interface.id
}

resource "aws_network_interface" "dev_workstation_4_private_interface" {
  description        = "Private Subnet Interface for Dev Workstation 4"
  subnet_id          = module.vpc.private_subnets[0]
  private_ips        = ["10.128.238.7"]
  ipv6_address_count = 0 # use assign_ipv6_address_on_creation=true from the vpc subnet configuration

  security_groups = [
    module.dev_workstation_security_group.security_group_id
  ]

  tags = {
    Name        = "eth0_dev4"
    Type        = "primary_network_interface"
    Network     = "dev_private"
    Environment = "dev"
  }
}
*/
