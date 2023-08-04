locals {
  aws_region = "eu-west-2"
  aws_azs    = ["${local.aws_region}a", "${local.aws_region}b"]

  /* ID of the The National Archives Transit Gateway which we use for site-to-site VPN */
  tna_transit_gateway_id = "tgw-0213325c898e4df09"

  public_dns_domain      = "catalogue.nationalarchives.gov.uk"
  private_omg_dns_domain = "omg.${local.public_dns_domain}"

  vpn_client_cidr_block = "192.168.168.0/22"

  /* Primary CIDR for Private Omega */
  vpc_cidr_block = "10.129.192.0/18"

  /* Private Subnet for General Development */
  vpc_private_subnet_dev_general = ["10.129.202.0/24", "10.129.222.0/24"]

  /* Private Subnet for databases used in Development */
  vpc_private_subnet_dev_databases = ["10.129.203.0/24", "10.129.223.0/24"]

  /* Public Subnet for General Use (NAT Gateway etc.) */
  vpc_public_subnet_general = ["10.129.192.0/24", "10.129.212.0/24"]

  /* Private Subnet for MVP Beta Web Application */
  vpc_private_subnet_mvpbeta_web = ["10.129.193.0/24", "10.129.213.0/24"]

  /* Private Subnet for MVP Beta Services */
  vpc_private_subnet_mvpbeta_services = ["10.129.194.0/24", "10.129.214.0/24"]

  /* Intra Subnet for databases used in MVP Beta */
  vpc_intra_subnet_mvpbeta_databases = ["10.129.196.0/24", "10.129.216.0/24"]

  /* Private Subnet for TNA network access for MVP Beta */
  vpc_private_tna_net_subnet_mvpbeta = ["10.129.199.0/24", "10.129.219.0/24"]

  /* Private Subnet for Management */
  vpc_private_subnet_management = ["10.129.195.0/24", "10.129.215.0/24"]

  vpc_private_subnets = tolist(
    concat(
      /* Development private subnets */
      local.vpc_private_subnet_dev_general,

      /* Management private subnets */
      local.vpc_private_subnet_management,

      /* MVP Beta private subnets */
      local.vpc_private_subnet_mvpbeta_web,
      local.vpc_private_subnet_mvpbeta_services,
      local.vpc_private_tna_net_subnet_mvpbeta
    )
  )

  vpc_private_ipv6_subnets = [for i in local.vpc_private_subnets : index(local.vpc_private_subnets, i)]

  vpc_database_subnets = tolist(
    concat(
      /* Development database subnets */
      local.vpc_private_subnet_dev_databases

      /* MVP Beta database subnets */
    )
  )

  vpc_database_ipv6_subnets = [for i in local.vpc_database_subnets : length(local.vpc_private_subnets) + index(local.vpc_database_subnets, i)]

  vpc_intra_subnets = tolist(
    concat(
      /* Development intra subnets */

      /* MVP Beta intra subnets */
      local.vpc_intra_subnet_mvpbeta_databases
    )
  )

  vpc_intra_ipv6_subnets = [for i in local.vpc_intra_subnets : length(local.vpc_private_subnets) + length(local.vpc_database_subnets) + index(local.vpc_intra_subnets, i)]

  vpc_public_subnets = tolist(
    concat(
      /* General Use subnet (NAT Gateway etc.) */
      local.vpc_public_subnet_general,
    )
  )

  /* starts public ipv6 subnets after private ipv6 subnets */
  vpc_public_ipv6_subnets = [for i in local.vpc_public_subnets : length(local.vpc_private_subnets) + length(local.vpc_database_subnets) + length(local.vpc_intra_subnets) + index(local.vpc_public_subnets, i)]

  # See https://datatracker.ietf.org/doc/html/rfc6056.html#section-2
  unpriviledged_port_start = 1024
  unpriviledged_port_end   = 65535

  # See https://datatracker.ietf.org/doc/html/rfc6056.html#section-2.1
  iana_ephemeral_port_start = 49152
  iana_ephemeral_port_end   = 65535

  # See `cat /proc/net/sys/ipv4/ip_local_port_range`
  linux_ephemeral_port_start = 32768
  linux_ephemeral_port_end   = 60999

  instance_type_dev_workstation = "t2.micro" # "r6i.2xlarge"
}
