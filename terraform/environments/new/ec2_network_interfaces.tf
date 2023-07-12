resource "aws_network_interface" "web_proxy_1_private_interface" {
  description        = "Private MVP Beta TNA Network Access Subnet interface for web-proxy-1"
  subnet_id          = module.vpc.private_subnets[8] # 9 of 10
  private_ips        = ["172.28.0.4"]
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
  private_ips        = ["172.27.1.4"]
  ipv6_address_count = 0 # use assign_ipv6_address_on_creation=true from the vpc subnet configuration

  tags = {
    Name        = "eth0_omg_web_app_1"
    Type        = "primary_network_interface"
    Network     = "omg_private"
    Environment = "omg"
  }
}

resource "aws_network_interface" "services_api_1_private_interface" {
  description        = "Private MVP Beta Services Subnet Interface for services-api-1"
  subnet_id          = module.vpc.private_subnets[6] # {7 of 10}
  private_ips        = ["172.27.2.4"]
  ipv6_address_count = 0 # use assign_ipv6_address_on_creation=true from the vpc subnet configuration

  tags = {
    Name        = "eth0_omg_srevices_api_1"
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

data "aws_network_interface" "services_api_1_private_interface" {
  id = aws_network_interface.services_api_1_private_interface.id
}