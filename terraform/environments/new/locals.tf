locals {

  scripts_dir = "${path.root}/${path.module}/scripts"

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

  /* IP address of the private Route53 DNS Server in the VPC */
  ipv4_vpc_dns_server = cidrhost(local.vpc_cidr_block, 2) # see: https://docs.aws.amazon.com/vpc/latest/userguide/subnet-sizing.html

  s3_bucket_name_puppet_certificates = "puppet-certificates"

  default_certificate_subject = {
    organizational_unit = "The Cataloguing, Taxonomy, and Data Team"
    organization        = "The National Archives"
    locality            = "Kew"
    province            = "London"
    country             = "GB"
    postal_code         = "TW9 4DU"
  }

  s3_bucket_name_neptune_loader = "ctd-neptune-loader"

  neptune_dev_cluster_a = {
    id                = "dev-neptune-cluster-a"
    subnet_group_name = "dev_neptune_cluster_a"
    instance_prefix   = "dev-neptune-cluster-a-instance"
  }

  puppet_control_repo_url = "https://github.com/nationalarchives/ctd-omega-puppet.git"

  instance_type_puppet_server    = "t3a.medium" # NOTE(AR) the "t3a.small" only has 2GiB RAM which is insufficient # NOTE(AR) ideally we would use "t4g.small", but Puppet doesn't yet officially support ARM CPU
  instance_type_web_proxy        = "t4g.nano"
  instance_type_web_app          = "t4g.small" # NOTE(AR): for initial testing we are using "t4g.small", however for production I anticipate we should use "t4g.large". # NOTE(AR): My original estimate was for t3.xlarge, lets see how this smaller instance does
  instance_type_services_api     = "t4g.small" # NOTE(AR): for initial testing we are using "t4g.small", however for production I anticipate we should use "t4g.large". # NOTE(AR): My original estimate was for t3.xlarge, lets see how this smaller instance does
  instance_type_dev_workstation  = "r6i.2xlarge"
  instance_type_dev_mssql_server = "t2.micro" # "r5.xlarge"

  aws_ami = {
    linux2_x86_64 = {
      name                      = "amzn2-ami-kernel-5.10-hvm-2.0.20230719.0-x86_64-gp2"
      id                        = "ami-0443d29a4bc22b3a5"
      compatible_puppet_version = 8
    }
    linux2_arm64 = {
      name                      = "amzn2-ami-kernel-5.10-hvm-2.0.20230926.0-arm64-gp2"
      id                        = "ami-0fca33b55c6ea10f0"
      compatible_puppet_version = 7 # NOTE(AR) version 8 is not compatible with arm64 on EL7
    }
  }

  ec2_puppet_server_instances = {

    puppet_server_1 = {
      instance_type = local.instance_type_puppet_server
      hostname      = "puppet-server-1"
      puppet = {
        type    = "server"
        version = local.aws_ami.linux2_x86_64.compatible_puppet_version
      }
      subnet_id    = module.vpc.private_subnets[2]
      ipv4_address = "10.129.195.4"
      ami          = local.aws_ami.linux2_x86_64.id
      security_groups = [
        module.puppet_server_security_group.security_group_id
      ]
      tags = {
        Type                      = "puppet_server"
        Environment               = "mvpbeta"
        scheduler_mon_fri_dev_ec2 = "false"
      }
    }
  }

  ec2_instances = {

    web_proxy_1 = {
      instance_type = local.instance_type_web_proxy
      hostname      = "web-proxy-1"
      puppet = {
        type    = "agent"
        version = local.aws_ami.linux2_arm64.compatible_puppet_version
      }
      subnet_id    = module.vpc.private_subnets[8]
      ipv4_address = "10.129.199.4"
      ami          = local.aws_ami.linux2_arm64.id
      security_groups = [
        module.mvpbeta_web_proxy_security_group.security_group_id
      ]
      root_block_device = {
        volume_size = 8 #GiB
      }
      tags = {
        Name                      = "web-proxy-1_new"
        Type                      = "web_proxy"
        Environment               = "mvpbeta"
        scheduler_mon_fri_dev_ec2 = "false"
      }
    }

    web_app_1 = {
      instance_type = local.instance_type_web_app
      hostname      = "web-app-1"
      puppet = {
        type    = "agent"
        version = local.aws_ami.linux2_arm64.compatible_puppet_version
      }
      subnet_id    = module.vpc.private_subnets[4]
      ipv4_address = "10.129.193.4"
      ami          = local.aws_ami.linux2_arm64.id
      security_groups = [
        module.mvpbeta_web_app_security_group.security_group_id
      ]
      root_block_device = {
        volume_size = 8 #GiB
      }
      tags = {
        Name                      = "web-app-1_new"
        Type                      = "web_app"
        Environment               = "mvpbeta"
        scheduler_mon_fri_dev_ec2 = "false"
      }
    }

    services_api_1 = {
      instance_type = local.instance_type_web_app
      hostname      = "services-api-1"
      puppet = {
        type    = "agent"
        version = local.aws_ami.linux2_arm64.compatible_puppet_version
      }
      subnet_id    = module.vpc.private_subnets[6]
      ipv4_address = "10.129.194.4"
      ami          = local.aws_ami.linux2_arm64.id
      security_groups = [
        module.mvpbeta_services_api_security_group.security_group_id
      ]
      root_block_device = {
        volume_size = 8 #GiB
      }
      tags = {
        Name                      = "services-api-1_new"
        Type                      = "services_api"
        Environment               = "mvpbeta"
        scheduler_mon_fri_dev_ec2 = "false"
      }
    }

    /* Dev Workstations below */

    dev_workstation_1 = {
      instance_type = local.instance_type_dev_workstation
      hostname      = "dev-workstation-1"
      puppet = {
        type    = "agent"
        version = local.aws_ami.linux2_x86_64.compatible_puppet_version
      }
      subnet_id    = module.vpc.private_subnets[0]
      ipv4_address = "10.129.202.4"
      ami          = local.aws_ami.linux2_x86_64.id
      security_groups = [
        module.dev_workstation_security_group.security_group_id
      ]
      additional_iam_policies = [
        "arn:aws:iam::aws:policy/NeptuneFullAccess",   # TODO(AR) restict this so that it is not FullAccess
      ]
      home_block_device = {
        device_name = "xvdb"
        volume_size = 200 #GiB
      }
      tags = {
        Name                      = "dev-workstation-1_new"
        Type                      = "dev_workstation"
        Environment               = "dev"
        scheduler_mon_fri_dev_ec2 = "true"
      }
    }

    dev_workstation_2 = {
      instance_type = local.instance_type_dev_workstation
      hostname      = "dev-workstation-2"
      puppet = {
        type    = "agent"
        version = local.aws_ami.linux2_x86_64.compatible_puppet_version
      }
      subnet_id    = module.vpc.private_subnets[0]
      ipv4_address = "10.129.202.5"
      ami          = local.aws_ami.linux2_x86_64.id
      security_groups = [
        module.dev_workstation_security_group.security_group_id
      ]
      additional_iam_policies = [
        "arn:aws:iam::aws:policy/NeptuneFullAccess",   # TODO(AR) restict this so that it is not FullAccess
      ]
      home_block_device = {
        device_name = "xvdb"
        volume_size = 200 #GiB
      }
      tags = {
        Name                      = "dev-workstation-2_new"
        Type                      = "dev_workstation"
        Environment               = "dev"
        scheduler_mon_fri_dev_ec2 = "true"
      }
    }

    dev_workstation_3 = {
      instance_type = local.instance_type_dev_workstation
      hostname      = "dev-workstation-3"
      puppet = {
        type    = "agent"
        version = local.aws_ami.linux2_x86_64.compatible_puppet_version
      }
      subnet_id    = module.vpc.private_subnets[0]
      ipv4_address = "10.129.202.6"
      ami          = local.aws_ami.linux2_x86_64.id
      security_groups = [
        module.dev_workstation_security_group.security_group_id
      ]
      additional_iam_policies = [
        "arn:aws:iam::aws:policy/NeptuneFullAccess",   # TODO(AR) restict this so that it is not FullAccess
      ]
      home_block_device = {
        device_name = "xvdb"
        volume_size = 200 #GiB
      }
      tags = {
        Name                      = "dev-workstation-3_new"
        Type                      = "dev_workstation"
        Environment               = "dev"
        scheduler_mon_fri_dev_ec2 = "true"
      }
    }
  }
}
