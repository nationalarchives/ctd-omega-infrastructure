locals {
  aws_region = "eu-west-2"
  aws_azs    = ["${local.aws_region}a", "${local.aws_region}b"]

  /* Primary CIDR for Private Omega */
  vpc_cidr_block = "172.27.0.0/16"

  /* Secondary CIDR for TNA Private Networks */
  vpc_secondary_cidr_blocks = ["172.28.0.0/24"] # NOTE(AR) Temporary solution until a larger subnet block is allocated from TNA for the entirety of Project Omega in AWS.

  /* Private Subnet for General Development */
  vpc_private_subnet_dev_general = ["172.27.64.0/24", "172.27.192.0/24"]

  /* Private Subnet for databases used in Development */
  vpc_private_subnet_dev_databases = ["172.27.65.0/24", "172.27.193.0/24"]

  /* Public Subnet for General Use (NAT Gateway etc.) */
  vpc_public_subnet_general = ["172.27.0.0/24", "172.27.128.0/24"]

  /* Private Subnet for MVP Beta Web Application */
  vpc_private_subnet_mvpbeta_web = ["172.27.1.0/24", "172.27.129.0/24"]

  /* Private Subnet for MVP Beta Services */
  vpc_private_subnet_mvpbeta_services = ["172.27.2.0/24", "172.27.130.0/24"]

  /* Intra Subnet for databases used in MVP Beta */
  vpc_intra_subnet_mvpbeta_databases = ["172.27.4.0/24", "172.27.132.0/24"]

  /* Private Subnet for TNA network access for MVP Beta */
  vpc_private_tna_net_subnet_mvpbeta = ["172.28.0.0/27", "172.28.0.128/27"] # NOTE(AR) Temporary solution until a larger subnet block is allocated from TNA for the entirety of Project Omega in AWS.

  /* Private Subnet for Management */
  vpc_private_subnet_management = ["172.27.3.0/24", "172.27.131.0/24"]

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
}