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
    Name        = "eth0_omg_services_api_1"
    Type        = "primary_network_interface"
    Network     = "omg_private"
    Environment = "omg"
  }
}

resource "aws_network_interface" "puppet_server_1_private_interface" {
  description        = "Private Management Subnet Interface for puppet_server-1"
  subnet_id          = module.vpc.private_subnets[2] # {3 of 10}
  private_ips        = ["172.27.3.4"]
  ipv6_address_count = 0 # use assign_ipv6_address_on_creation=true from the vpc subnet configuration

  tags = {
    Name        = "eth0_omg_puppet_server_1"
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

data "aws_network_interface" "puppet_server_1_private_interface" {
  id = aws_network_interface.puppet_server_1_private_interface.id
}

resource "aws_network_interface" "dev_workstation_1_private_interface" {
  description        = "Private Dev General Subnet Interface for Dev Workstation 1"
  subnet_id          = module.vpc.private_subnets[0]
  private_ips        = ["172.27.64.4"]
  ipv6_address_count = 0 # use assign_ipv6_address_on_creation=true from the vpc subnet configuration

  security_groups = [
    module.dev_workstation_security_group.security_group_id
  ]

  tags = {
    Name        = "eth0_dev1"
    Type        = "primary_network_interface"
    Network     = "dev_private"
    Environment = "dev"
  }
}

resource "aws_network_interface" "dev_workstation_2_private_interface" {
  description        = "Private Dev General Subnet Interface for Dev Workstation 2"
  subnet_id          = module.vpc.private_subnets[0]
  private_ips        = ["172.27.64.5"]
  ipv6_address_count = 0 # use assign_ipv6_address_on_creation=true from the vpc subnet configuration

  security_groups = [
    module.dev_workstation_security_group.security_group_id
  ]

  tags = {
    Name        = "eth0_dev2"
    Type        = "primary_network_interface"
    Network     = "dev_private"
    Environment = "dev"
  }
}

resource "aws_network_interface" "dev_mssql_server_1_database_interface" {
  description        = "Private Dev Database Subnet Interface for Dev MS SQL Server 1"
  subnet_id          = module.vpc.database_subnets[0]
  private_ips        = ["172.27.65.132"]
  ipv6_address_count = 0 # use assign_ipv6_address_on_creation=true from the vpc subnet configuration

  tags = {
    Name        = "eth0_mssql1"
    Type        = "primary_network_interface"
    Network     = "dev_database"
    Environment = "dev"
  }
}

data "aws_network_interface" "dev_workstation_1_private_interface" {
  id = aws_network_interface.dev_workstation_1_private_interface.id
}

data "aws_network_interface" "dev_workstation_2_private_interface" {
  id = aws_network_interface.dev_workstation_2_private_interface.id
}

data "aws_network_interface" "dev_mssql_server_1_database_interface" {
  id = aws_network_interface.dev_mssql_server_1_database_interface.id
}