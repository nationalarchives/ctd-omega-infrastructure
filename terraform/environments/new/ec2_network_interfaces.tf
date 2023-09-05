resource "aws_network_interface" "web_proxy_1_private_interface" {
  description = "Private MVP Beta TNA Network Access Subnet interface for web-proxy-1"
  subnet_id   = module.vpc.private_subnets[8]
  private_ips = ["10.129.199.4"]

  tags = {
    Name        = "eth0_omg_web_proxy_1"
    Type        = "primary_network_interface"
    Network     = "omg_private"
    Environment = "omg"
  }
}

resource "aws_network_interface" "web_app_1_private_interface" {
  description = "Private MVP Beta Web Subnet interface for web-app-1"
  subnet_id   = module.vpc.private_subnets[4]
  private_ips = ["10.129.193.4"]

  tags = {
    Name        = "eth0_omg_web_app_1"
    Type        = "primary_network_interface"
    Network     = "omg_private"
    Environment = "omg"
  }
}

resource "aws_network_interface" "services_api_1_private_interface" {
  description = "Private MVP Beta Services Subnet interface for services-api-1"
  subnet_id   = module.vpc.private_subnets[6]
  private_ips = ["10.129.194.4"]

  tags = {
    Name        = "eth0_omg_services_api_1"
    Type        = "primary_network_interface"
    Network     = "omg_private"
    Environment = "omg"
  }
}

resource "aws_network_interface" "puppet_server_1_private_interface" {
  description = "Private Management Subnet interface for puppet_server-1"
  subnet_id   = module.vpc.private_subnets[2]
  private_ips = ["10.129.195.4"]

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
  description = "Private Dev General Subnet interface for Dev Workstation 1"
  subnet_id   = module.vpc.private_subnets[0]
  private_ips = ["10.129.202.4"]

  security_groups = [
    module.dev_workstation_security_group.security_group_id
  ]

  tags = {
    Name        = "eth0_dev-workstation-1"
    Type        = "primary_network_interface"
    Network     = "dev_private"
    Environment = "dev"
  }
}

resource "aws_network_interface" "dev_workstation_2_private_interface" {
  description = "Private Dev General Subnet interface for Dev Workstation 2"
  subnet_id   = module.vpc.private_subnets[0]
  private_ips = ["10.129.202.5"]

  security_groups = [
    module.dev_workstation_security_group.security_group_id
  ]

  tags = {
    Name        = "eth0_dev-workstation-2"
    Type        = "primary_network_interface"
    Network     = "dev_private"
    Environment = "dev"
  }
}

resource "aws_network_interface" "dev_mssql_server_1_database_interface" {
  description = "Private Dev Database Subnet interface for Dev MS SQL Server 1"
  subnet_id   = module.vpc.database_subnets[0]
  private_ips = ["10.129.203.4"]

  security_groups = [
    module.dev_database_security_group.security_group_id
  ]

  tags = {
    Name        = "eth0_dev-mssql-server1"
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
