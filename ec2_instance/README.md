# EC2 Instance Terraform module

Terraform module which simplifies creating an EC2 instance.

## Example for an EC2 instance

```hcl
module "dev_workstation_1_ec2_instance" {
  source = "./ec2_instance"

  fqdn = "dev-workstation-1.my-domain.dom"

  ami           = "ami-0443d29a4bc22b3a5"
  instance_type = "t2.micro"
  key_name      = data.aws_key_pair.your_admin_key_pair.key_name

  security_groups = [
    module.dev_workstation_security_group.security_group_id
  ]

  root_block_device = {
    volume_size = 20 #GiB
  }

  home_block_device = {
    device_name = "xvdb"
    volume_size = 200 #GiB
  }

  subnet_id   = module.vpc.private_subnets[0]
  private_ips = ["10.1.2.5"]
  dns = {
    zone_id              = aws_route53_zone.your_private_dns.zone_id
    reverse_ipv4_zone_id = aws_route53_zone.your_private_ipv4_reverse_dns.zone_id
    reverse_ipv6_zone_id = aws_route53_zone.your_private_ipv6_reverse_dns.zone_id
  }

  tags = {
    Type                      = "dev_workstation"
    Environment               = "dev"
    scheduler_mon_fri_dev_ec2 = "true"
  }
}
```

## Example for an EC2 instance which is a Puppet Server

```hcl
module "puppet_server_1_ec2_instance" {
  source = "./ec2_instance"

  fqdn = "puppet-server-1.my-domain.dom"

  ami           = "ami-0443d29a4bc22b3a5"
  instance_type = "t2.micro"
  key_name      = data.aws_key_pair.your_admin_key_pair.key_name

  security_groups = [
    module.puppet_server_security_group.security_group_id
  ]

  puppet = {
    server = {
      control_repo_url = "https://github.com/nationalarchives/ctd-omega-puppet.git"
      environment = "production"
    }
    certificates = {
      s3_bucket_name = aws_s3_bucket.puppet_certificates.id
      s3_bucket_certificates_public_policy = aws_iam_policy.puppet_certificates_public_policy.arn
      s3_bucket_ca_public_policy = aws_iam_policy.puppet_ca_public_policy.arn
      s3_bucket_ca_private_policy = aws_iam_policy.puppet_ca_private_policy.arn
    }
  }

  root_block_device = {
    volume_size = 20 #GiB
  }

  subnet_id   = module.vpc.private_subnets[0]
  private_ips = ["10.1.2.4"]
  dns = {
    zone_id              = aws_route53_zone.your_private_dns.zone_id
    reverse_ipv4_zone_id = aws_route53_zone.your_private_ipv4_reverse_dns.zone_id
    reverse_ipv6_zone_id = aws_route53_zone.your_private_ipv6_reverse_dns.zone_id
  }

  tags = {
    Type                      = "puppet_server"
    Environment               = "mvpb"
    scheduler_mon_fri_dev_ec2 = "false"
  }
}
```

## Example for an EC2 instance with a Puppet Agent

```hcl
module "dev_workstation_1_ec2_instance" {
  source = "./ec2_instance"

  fqdn = "dev-workstation-1.my-domain.dom"

  ami           = "ami-0443d29a4bc22b3a5"
  instance_type = "t2.micro"
  key_name      = data.aws_key_pair.your_admin_key_pair.key_name

  security_groups = [
    module.dev_workstation_security_group.security_group_id
  ]

  puppet = {
    server_fqdn = "puppet-server-1.my-domain.dom"
    certificates = {
      s3_bucket_name = aws_s3_bucket.puppet_certificates.id
      s3_bucket_certificates_public_policy = aws_iam_policy.puppet_certificates_public_policy.arn
      s3_bucket_ca_public_policy = aws_iam_policy.puppet_ca_public_policy.arn
      s3_bucket_ca_private_policy = aws_iam_policy.puppet_ca_private_policy.arn
      subject = local.default_certificate_subject
      ca_private_key_pem = module.puppet_server_1_ec2_instance.puppet_ca_private_key_pem
      ca_certificate_pem = module.puppet_server_1_ec2_instance.puppet_ca_certificate_pem
    }
  }

  root_block_device = {
    volume_size = 20 #GiB
  }

  home_block_device = {
    device_name = "xvdb"
    volume_size = 200 #GiB
  }

  subnet_id   = module.vpc.private_subnets[0]
  private_ips = ["10.1.2.5"]
  dns = {
    zone_id              = aws_route53_zone.your_private_dns.zone_id
    reverse_ipv4_zone_id = aws_route53_zone.your_private_ipv4_reverse_dns.zone_id
    reverse_ipv6_zone_id = aws_route53_zone.your_private_ipv6_reverse_dns.zone_id
  }

  tags = {
    Type                      = "dev_workstation"
    Environment               = "dev"
    scheduler_mon_fri_dev_ec2 = "true"
  }
}
```
