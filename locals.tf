locals {

  scripts_dir = "${path.root}/${path.module}/scripts"

  aws_region = "eu-west-2"
  aws_azs    = ["${local.aws_region}a", "${local.aws_region}b"]

  /* ID of The National Archives 'intersite' VPC which we use for relaying Route53 DNS to on-premise */
  tna_intersite_vpc_id = "vpc-09fdc740f422062f5"

  /* ID of The National Archives Transit Gateway which we use for site-to-site VPN */
  tna_transit_gateway_id = "tgw-0213325c898e4df09"

  public_dns_domain      = "catalogue.nationalarchives.gov.uk"
  private_omg_dns_domain = "omg.${local.public_dns_domain}"

  vpn_client_cidr_block = "192.168.168.0/22"

  /* Primary CIDR for Private Omega */
  vpc_cidr_block = "10.129.192.0/18"

  /* Public Subnet for General Use (NAT Gateway etc.) */
  vpc_public_subnet_general = {
    ipv4          = ["10.129.192.0/24",        "10.129.212.0/24"]
    # ipv6        = ["2a05:d01c:7:1a0e::/64",  "2a05:d01c:7:1a0f::/64"]
    ipv6_prefixes = [14, 15]
  }

  /* Private Subnet for General Development */
  vpc_private_subnet_dev_general = {
    ipv4          = ["10.129.202.0/24",        "10.129.222.0/24"]
    # ipv6        = ["2a05:d01c:7:1a00::/64",  "2a05:d01c:7:1a01::/64"]
    ipv6_prefixes = [0, 1]
  }

  /* Private Subnet for databases used in Development */
  vpc_database_subnet_dev_databases = {
    ipv4          = ["10.129.203.0/24",        "10.129.223.0/24"]
    # ipv6        = ["2a05:d01c:7:1a0a::/64",  "2a05:d01c:7:1a0b::/64"]
    ipv6_prefixes = [10, 11]
  }

  /* Private Subnet for MVP Beta Web Application */
  vpc_private_subnet_mvpbeta_web = {
    ipv4          = ["10.129.193.0/24",        "10.129.213.0/24"]
    # ipv6        = ["2a05:d01c:7:1a04::/64",  "2a05:d01c:7:1a05::/64"]
    ipv6_prefixes = [4, 5]
  }

  /* Private Subnet for MVP Beta Services */
  vpc_private_subnet_mvpbeta_services = {
    ipv4          = ["10.129.194.0/24",        "10.129.214.0/24"]
    # ipv6        = ["2a05:d01c:7:1a06::/64",  "2a05:d01c:7:1a07::/64"]
    ipv6_prefixes = [6, 7]
  }

  /* Intra Subnet for databases used in MVP Beta */
  vpc_intra_subnet_mvpbeta_databases = {
    ipv4          = ["10.129.196.0/24",        "10.129.216.0/24"]
    # ipv6        = ["2a05:d01c:7:1a0c::/64",  "2a05:d01c:7:1a0d::/64"]
    ipv6_prefixes = [12, 13]
  }

  /* Private Subnet for TNA network access for MVP Beta */
  vpc_private_tna_net_subnet_mvpbeta = {
    ipv4          = ["10.129.199.0/24",        "10.129.219.0/24"]
    # ipv6        = ["2a05:d01c:7:1a08::/64",  "2a05:d01c:7:1a09::/64"]
    ipv6_prefixes = [8, 9]
  }

  /* Private Subnet for Management */
  vpc_private_subnet_management = {
    ipv4          = ["10.129.195.0/24",        "10.129.215.0/24"]
    # ipv6        = ["2a05:d01c:7:1a02::/64",  "2a05:d01c:7:1a03::/64"]
    ipv6_prefixes = [2, 3]
  }

  vpc_private_subnets = tolist(
    concat(
      /* Development private subnets */
      local.vpc_private_subnet_dev_general.ipv4,

      /* Management private subnets */
      local.vpc_private_subnet_management.ipv4,

      /* MVP Beta private subnets */
      local.vpc_private_subnet_mvpbeta_web.ipv4,
      local.vpc_private_subnet_mvpbeta_services.ipv4,
      local.vpc_private_tna_net_subnet_mvpbeta.ipv4
    )
  )

  vpc_private_ipv6_subnets =  tolist(
    concat(
      /* Development private subnets */
      local.vpc_private_subnet_dev_general.ipv6_prefixes,

      /* Management private subnets */
      local.vpc_private_subnet_management.ipv6_prefixes,

      /* MVP Beta private subnets */
      local.vpc_private_subnet_mvpbeta_web.ipv6_prefixes,
      local.vpc_private_subnet_mvpbeta_services.ipv6_prefixes,
      local.vpc_private_tna_net_subnet_mvpbeta.ipv6_prefixes
    )
  )

  // NOTE(AR) these are indexes into `module.vpc.private_subnets_cidr_blocks` and `module.vpc.private_subnets_ipv6_cidr_blocks`
  idx_vpc_private_subnet_dev_general_a      = 0
  idx_vpc_private_subnet_dev_general_b      = 1
  idx_vpc_private_subnet_management_a       = 2
  idx_vpc_private_subnet_management_b       = 3
  idx_vpc_private_subnet_mvpbeta_web_a      = 4
  idx_vpc_private_subnet_mvpbeta_web_b      = 5
  idx_vpc_private_subnet_mvpbeta_services_a = 6
  idx_vpc_private_subnet_mvpbeta_services_b = 7
  idx_vpc_private_tna_net_subnet_mvpbeta_a  = 8
  idx_vpc_private_tna_net_subnet_mvpbeta_b  = 9

  vpc_database_subnets = tolist(
    concat(
      /* Development database subnets */
      local.vpc_database_subnet_dev_databases.ipv4
    )
  )

  vpc_database_ipv6_subnets = tolist(
    concat(
      /* Development database subnets */
      local.vpc_database_subnet_dev_databases.ipv6_prefixes
    )
  )

  // NOTE(AR) these are indexes into `module.vpc.database_subnets_cidr_blocks` and `module.vpc.database_subnets_ipv6_cidr_blocks`
  idx_vpc_database_subnet_dev_databases_a = 0
  idx_vpc_database_subnet_dev_databases_b = 1

  vpc_intra_subnets = tolist(
    concat(
      /* MVP Beta intra subnets */
      local.vpc_intra_subnet_mvpbeta_databases.ipv4
    )
  )

  vpc_intra_ipv6_subnets = tolist(
    concat(
      /* MVP Beta intra subnets */
      local.vpc_intra_subnet_mvpbeta_databases.ipv6_prefixes
    )
  )

  // NOTE(AR) these are indexes into `module.vpc.intra_subnets_cidr_blocks` and `module.vpc.intra_subnets_ipv6_cidr_blocks`
  idx_vpc_intra_subnet_mvpbeta_databases_a = 0
  idx_vpc_intra_subnet_mvpbeta_databases_b = 1

  vpc_public_subnets = tolist(
    concat(
      /* General Use subnet (NAT Gateway etc.) */
      local.vpc_public_subnet_general.ipv4
    )
  )

  /* starts public ipv6 subnets after private ipv6 subnets */
  vpc_public_ipv6_subnets = tolist(
    concat(
      /* General Use subnet (NAT Gateway etc.) */
      local.vpc_public_subnet_general.ipv6_prefixes
    )
  )

  // NOTE(AR) these are indexes into `module.vpc.public_subnets_cidr_blocks` and `module.vpc.public_subnets_ipv6_cidr_blocks`
  idx_vpc_public_subnet_general_a = 0
  idx_vpc_public_subnet_general_b = 1

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

  # S3 Buckets
  s3_bucket_name_neptune_loader      = "ctd-neptune-loader"
  s3_bucket_name_puppet_certificates = "puppet-certificates"
  s3_bucket_name_scratch_space       = "ctd-scratch-space"

  default_sqs_queue_settings = {
    delay_seconds              = 0
    max_message_size           = 262144  # 256 KB
    message_retention_seconds  = 1209600 # 14 days
    receive_wait_time_seconds  = 0
    visibility_timeout_seconds = 30
    sqs_managed_sse_enabled    = true
  }

  default_certificate_subject = {
    organizational_unit = "The Cataloguing, Taxonomy, and Data Team"
    organization        = "The National Archives"
    locality            = "Kew"
    province            = "London"
    country             = "GB"
    postal_code         = "TW9 4DU"
  }

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
  instance_type_dev_mssql_server = "r6i.xlarge" # NOTE(AR): could this be smaller? what is the load when running Pentaho ETL

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
      network_interfaces = [
        {
          subnet_id       = module.vpc.private_subnets[2]
          private_ips     = ["10.129.195.4"]
          security_groups = [
            module.puppet_server_security_group.security_group_id
          ]
        }
      ]
      ami          = local.aws_ami.linux2_x86_64.id
      additional_iam_policies = [
        aws_iam_policy.puppet_server_access_secrets_iam_policy.arn
      ]
      tags = {
        Type                  = "puppet_server"
        Environment           = "mvpbeta"
        scheduler_mon_fri_ec2 = "false"
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
      network_interfaces = [
        {
          subnet_id       = module.vpc.private_subnets[8]
          private_ips     = ["10.129.199.4"],
          security_groups = [
            module.mvpbeta_web_proxy_security_group.security_group_id
          ]
        }
      ]
      ami          = local.aws_ami.linux2_arm64.id
      root_block_device = {
        volume_size = 8 #GiB
      }
      tags = {
        Name                  = "web-proxy-1_new"
        Type                  = "web_proxy"
        Environment           = "mvpbeta"
        scheduler_mon_fri_ec2 = "false"
      }
    }

    web_app_1 = {
      instance_type = local.instance_type_web_app
      hostname      = "web-app-1"
      puppet = {
        type    = "agent"
        version = local.aws_ami.linux2_arm64.compatible_puppet_version
      }
      network_interfaces = [
        {
          subnet_id       = module.vpc.private_subnets[4]
          private_ips     = ["10.129.193.4"]
          security_groups = [
            module.mvpbeta_web_app_security_group.security_group_id
          ]
        }
      ]
      ami          = local.aws_ami.linux2_arm64.id
      root_block_device = {
        volume_size = 8 #GiB
      }
      tags = {
        Name                  = "web-app-1_new"
        Type                  = "web_app"
        Environment           = "mvpbeta"
        scheduler_mon_fri_ec2 = "false"
      }
    }

    services_api_1 = {
      instance_type = local.instance_type_web_app
      hostname      = "services-api-1"
      puppet = {
        type    = "agent"
        version = local.aws_ami.linux2_arm64.compatible_puppet_version
      }
      network_interfaces = [
        {
          subnet_id       = module.vpc.private_subnets[6]
          private_ips     = ["10.129.194.4"]
          security_groups = [
            module.mvpbeta_services_api_security_group.security_group_id
          ]
        }
      ]
      ami          = local.aws_ami.linux2_arm64.id
      additional_iam_policies = [
        aws_iam_policy.neptune_sparql_read_write_policy.arn
      ]
      root_block_device = {
        volume_size = 8 #GiB
      }
      tags = {
        Name                  = "services-api-1_new"
        Type                  = "services_api"
        Environment           = "mvpbeta"
        scheduler_mon_fri_ec2 = "false"
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
      network_interfaces = [
        {
          subnet_id       = module.vpc.private_subnets[0]
          private_ips     = ["10.129.202.4"]
          security_groups = [
            module.dev_workstation_security_group.security_group_id
          ]
        }
      ]
      ami          = local.aws_ami.linux2_x86_64.id
      additional_iam_policies = [
        aws_iam_policy.scratch_space_backup_read_policy.arn,
        aws_iam_policy.scratch_space_write_all_policy.arn,
        aws_iam_policy.neptune_loader_write_policy.arn,
        "arn:aws:iam::aws:policy/NeptuneFullAccess", # TODO(AR) restict this so that it is not FullAccess
      ]
      home_block_device = {
        device_name = "xvdb"
        volume_size = 200 #GiB
      }
      tags = {
        Name                  = "dev-workstation-1_new"
        Type                  = "dev_workstation"
        Environment           = "dev"
        scheduler_mon_fri_ec2 = "true"
      }
    }

    dev_workstation_2 = {
      instance_type = local.instance_type_dev_workstation
      hostname      = "dev-workstation-2"
      puppet = {
        type    = "agent"
        version = local.aws_ami.linux2_x86_64.compatible_puppet_version
      }
      network_interfaces = [
        {
          subnet_id       = module.vpc.private_subnets[0]
          private_ips     = ["10.129.202.5"]
          security_groups = [
            module.dev_workstation_security_group.security_group_id
          ]
        }
      ]
      ami          = local.aws_ami.linux2_x86_64.id
      additional_iam_policies = [
        aws_iam_policy.scratch_space_backup_read_policy.arn,
        aws_iam_policy.neptune_loader_write_policy.arn,
        "arn:aws:iam::aws:policy/NeptuneFullAccess", # TODO(AR) restict this so that it is not FullAccess
      ]
      home_block_device = {
        device_name = "xvdb"
        volume_size = 200 #GiB
      }
      tags = {
        Name                  = "dev-workstation-2_new"
        Type                  = "dev_workstation"
        Environment           = "dev"
        scheduler_mon_fri_ec2 = "true"
      }
    }

    dev_workstation_3 = {
      instance_type = local.instance_type_dev_workstation
      hostname      = "dev-workstation-3"
      puppet = {
        type    = "agent"
        version = local.aws_ami.linux2_x86_64.compatible_puppet_version
      }
      network_interfaces = [
        {
          subnet_id        = module.vpc.private_subnets[0]
          private_ips     = ["10.129.202.6"]
          security_groups = [
            module.dev_workstation_security_group.security_group_id
          ]
        }
      ]
      ami          = local.aws_ami.linux2_x86_64.id
      additional_iam_policies = [
        aws_iam_policy.scratch_space_backup_read_policy.arn,
        aws_iam_policy.neptune_loader_write_policy.arn,
        "arn:aws:iam::aws:policy/NeptuneFullAccess", # TODO(AR) restict this so that it is not FullAccess
      ]
      home_block_device = {
        device_name = "xvdb"
        volume_size = 200 #GiB
      }
      tags = {
        Name                  = "dev-workstation-3_new"
        Type                  = "dev_workstation"
        Environment           = "dev"
        scheduler_mon_fri_ec2 = "true"
      }
    }
  }
}
