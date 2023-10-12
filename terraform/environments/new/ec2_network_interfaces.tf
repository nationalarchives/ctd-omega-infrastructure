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

data "aws_network_interface" "dev_mssql_server_1_database_interface" {
  id = aws_network_interface.dev_mssql_server_1_database_interface.id
}
