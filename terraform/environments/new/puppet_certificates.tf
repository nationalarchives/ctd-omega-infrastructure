# Create Puppet Server CA certificates and keys
module "puppet_server_1_puppet_server_certificate_authority" {
  source = "./certificate"

  id = "puppet-server-1.${local.private_omg_dns_domain}"

  is_ca_certificate = true

  subject = {
    common_name = "Puppet CA: puppet-server-1.${local.private_omg_dns_domain}"
    organizational_unit = "The Cataloguing, Taxonomy, and Data Team"
    organization = "The National Archives"
    locality = "Kew"
    province = "London"
    country = "GB"
    postal_code = "TW9 4DU"

    serial_number = "0x1"
  }

  expiry_days = 5 * 365  # 5 years
  export_path = "../../../ctd-omega-infrastructure-certificates/exported"
}

# Create puppet-server-1 Puppet Agent certificates and keys
module "puppet_server_1_puppet_agent_certificate" {
  source = "./certificate"

  id = "puppet-server-1.${local.private_omg_dns_domain}"

  is_ca_certificate = false

  subject = {
    common_name = "puppet-server-1.${local.private_omg_dns_domain}"
    organizational_unit = "The Cataloguing, Taxonomy, and Data Team"
    organization = "The National Archives"
    locality = "Kew"
    province = "London"
    country = "GB"
    postal_code = "TW9 4DU"

    serial_number = "0x1"
  }

  dns_names = [
    "puppet-server-1.${local.private_omg_dns_domain}"
  ]

  expiry_days = 5 * 365  # 5 years
  export_path = "../../../ctd-omega-infrastructure-certificates/exported"

  ca = {
    private_key_pem = module.puppet_server_1_puppet_server_certificate_authority.private_key_pem
    certificate_pem = module.puppet_server_1_puppet_server_certificate_authority.certificate_pem
  }
}

# Create dev-workstation-1 Puppet Agent certificates and keys
module "dev_workstation_1_puppet_agent_certificate" {
  source = "./certificate"

  id = "dev-workstation-1.${local.private_omg_dns_domain}"

  is_ca_certificate = false

  subject = {
    common_name = "dev-workstation-1.${local.private_omg_dns_domain}"
    organizational_unit = "The Cataloguing, Taxonomy, and Data Team"
    organization = "The National Archives"
    locality = "Kew"
    province = "London"
    country = "GB"
    postal_code = "TW9 4DU"

    serial_number = "0x1"
  }

  dns_names = [
    "dev-workstation-1.${local.private_omg_dns_domain}"
  ]

  expiry_days = 5 * 365  # 5 years
  export_path = "../../../ctd-omega-infrastructure-certificates/exported"

  ca = {
    private_key_pem = module.puppet_server_1_puppet_server_certificate_authority.private_key_pem
    certificate_pem = module.puppet_server_1_puppet_server_certificate_authority.certificate_pem
  }
}

# Create a private S3 'puppet-certificates' bucket to hold the certificates
resource "aws_s3_bucket" "puppet_certificates" {
  bucket = local.s3_bucket_name_puppet_certificates

  tags = {
    Name        = "puppet_certificate"
    Type        = "certificate"
    Environment = "management"
  }
}

# Load Puppet Server CA certificates into S3 'puppet-certificates' bucket
resource "aws_s3_object" "puppet_server_1_puppet_server_certificate_authority_certificate" {
    bucket = aws_s3_bucket.puppet_certificates.id
    key = "ca/public/${basename(module.puppet_server_1_puppet_server_certificate_authority.certificate_pem_exported_filename)}"
    content = module.puppet_server_1_puppet_server_certificate_authority.certificate_pem
    content_type = "application/x-pem-file"
    # checksum_algorithm = "SHA256"  # TODO(AR) requires newer AWS provider
    tags = {
        Type        = "certificate"
        Environment = "management"
    }
}

resource "aws_s3_object" "puppet_server_1_puppet_server_certificate_authority_public_key" {
    bucket = aws_s3_bucket.puppet_certificates.id
    key = "ca/public/${basename(module.puppet_server_1_puppet_server_certificate_authority.public_key_pem_exported_filename)}"
    content = module.puppet_server_1_puppet_server_certificate_authority.public_key_pem
    content_type = "application/x-pem-file"
    # checksum_algorithm = "SHA256"  # TODO(AR) requires newer AWS provider
    tags = {
        Type        = "certificate"
        Environment = "management"
    }
}

resource "aws_s3_object" "puppet_server_1_puppet_server_certificate_authority_private_key" {
    bucket = aws_s3_bucket.puppet_certificates.id
    key = "ca/private/${basename(module.puppet_server_1_puppet_server_certificate_authority.private_key_pem_exported_filename)}"
    content = module.puppet_server_1_puppet_server_certificate_authority.private_key_pem
    content_type = "application/x-pem-file"
    # checksum_algorithm = "SHA256"  # TODO(AR) requires newer AWS provider
    tags = {
        Type        = "certificate"
        Environment = "management"
    }
}

# Load Puppet Agent certificates into S3 'puppet-certificates' bucket
resource "aws_s3_object" "puppet_server_1_puppet_agent_certificate" {
    bucket = aws_s3_bucket.puppet_certificates.id
    key = "certificates/public/${basename(module.puppet_server_1_puppet_agent_certificate.certificate_pem_exported_filename)}"
    content = module.puppet_server_1_puppet_agent_certificate.certificate_pem
    content_type = "application/x-pem-file"
    # checksum_algorithm = "SHA256"  # TODO(AR) requires newer AWS provider
    tags = {
        Type        = "certificate"
        Environment = "management"
    }
}

resource "aws_s3_object" "puppet_server_1_puppet_agent_public_key" {
    bucket = aws_s3_bucket.puppet_certificates.id
    key = "certificates/public/${basename(module.puppet_server_1_puppet_agent_certificate.public_key_pem_exported_filename)}"
    content = module.puppet_server_1_puppet_agent_certificate.public_key_pem
    content_type = "application/x-pem-file"
    # checksum_algorithm = "SHA256"  # TODO(AR) requires newer AWS provider
    tags = {
        Type        = "certificate"
        Environment = "management"
    }
}

resource "aws_s3_object" "puppet_server_1_puppet_agent_private_key" {
    bucket = aws_s3_bucket.puppet_certificates.id
    key = "certificates/private/${basename(module.puppet_server_1_puppet_agent_certificate.private_key_pem_exported_filename)}"
    content = module.puppet_server_1_puppet_agent_certificate.private_key_pem
    content_type = "application/x-pem-file"
    # checksum_algorithm = "SHA256"  # TODO(AR) requires newer AWS provider
    tags = {
        Type        = "certificate"
        Environment = "management"
    }
}

resource "aws_s3_object" "dev_workstation_1_puppet_agent_certificate" {
    bucket = aws_s3_bucket.puppet_certificates.id
    key = "certificates/public/${basename(module.dev_workstation_1_puppet_agent_certificate.certificate_pem_exported_filename)}"
    content = module.dev_workstation_1_puppet_agent_certificate.certificate_pem
    content_type = "application/x-pem-file"
    # checksum_algorithm = "SHA256"  # TODO(AR) requires newer AWS provider
    tags = {
        Type        = "certificate"
        Environment = "management"
    }
}

resource "aws_s3_object" "dev_workstation_1_puppet_agent_public_key" {
    bucket = aws_s3_bucket.puppet_certificates.id
    key = "certificates/public/${basename(module.dev_workstation_1_puppet_agent_certificate.public_key_pem_exported_filename)}"
    content = module.dev_workstation_1_puppet_agent_certificate.public_key_pem
    content_type = "application/x-pem-file"
    # checksum_algorithm = "SHA256"  # TODO(AR) requires newer AWS provider
    tags = {
        Type        = "certificate"
        Environment = "management"
    }
}

resource "aws_s3_object" "dev_workstation_1_puppet_agent_private_key" {
    bucket = aws_s3_bucket.puppet_certificates.id
    key = "certificates/private/${basename(module.dev_workstation_1_puppet_agent_certificate.private_key_pem_exported_filename)}"
    content = module.dev_workstation_1_puppet_agent_certificate.private_key_pem
    content_type = "application/x-pem-file"
    # checksum_algorithm = "SHA256"  # TODO(AR) requires newer AWS provider
    tags = {
        Type        = "certificate"
        Environment = "management"
    }
}

# Setup access to S3 'puppet-certificates' bucket
resource "aws_iam_instance_profile" "puppet_server_iam_instance_profile" {
  name = "puppet_server"
  path = "/puppet/"

  role = aws_iam_role.puppet_server_iam_role.name

  tags = {
    Environment = "management"
  }
}

resource "aws_iam_role" "puppet_server_iam_role" {
  name = "puppet_server_role"
  path = "/puppet/"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role_policy.json
  managed_policy_arns = [
      aws_iam_policy.puppet_ca_private_policy.arn,
      aws_iam_policy.puppet_ca_public_policy.arn,
      aws_iam_policy.puppet_certificates_private_policy.arn,
      aws_iam_policy.puppet_certificates_public_policy.arn
  ]
}

resource "aws_iam_instance_profile" "dev_workstation_1_ec2_iam_instance_profile" {
  name = "dev_workstation_1_ec2"

  role = aws_iam_role.dev_workstation_1_ec2_iam_role.name

  tags = {
    Environment = "management"
  }
}

resource "aws_iam_role" "dev_workstation_1_ec2_iam_role" {
  name = "dev_workstation_1_ec2_role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role_policy.json
  managed_policy_arns = [
      aws_iam_policy.puppet_ca_public_policy.arn,
      aws_iam_policy.puppet_certificates_public_policy.arn,
      aws_iam_policy.puppet_certificates_private_dev_workstation_1_policy.arn
  ]
}

data "aws_iam_policy_document" "ec2_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "puppet_ca_private_policy" {
    name = "puppet_ca_private_policy"
    path = "/puppet/"
    policy = data.aws_iam_policy_document.puppet_ca_private_policy.json
}

data "aws_iam_policy_document" "puppet_ca_private_policy" {
  statement {
    sid = "AllowReadPuppetCAPrivate"

    actions = [
        "s3:GetObject",
        "s3:ListBucket"
    ]

    resources = [
      "${aws_s3_bucket.puppet_certificates.arn}/ca/private/*",
      "${aws_s3_bucket.puppet_certificates.arn}"
    ]
  }
}

resource "aws_iam_policy" "puppet_ca_public_policy" {
    name = "puppet_ca_public_policy"
    path = "/puppet/"
    policy = data.aws_iam_policy_document.puppet_ca_public_policy.json
}

data "aws_iam_policy_document" "puppet_ca_public_policy" {
  statement {
    sid = "AllowReadPuppetCAPublic"

    actions = [
        "s3:GetObject",
        "s3:ListBucket"
    ]

    resources = [
      "${aws_s3_bucket.puppet_certificates.arn}/ca/public/*",
      "${aws_s3_bucket.puppet_certificates.arn}"
    ]
  }
}

resource "aws_iam_policy" "puppet_certificates_private_policy" {
    name = "puppet_certificates_private_policy"
    path = "/puppet/"
    policy = data.aws_iam_policy_document.puppet_certificates_private_policy.json
}

data "aws_iam_policy_document" "puppet_certificates_private_policy" {
  statement {
    sid = "AllowReadPuppetCertificatesPrivate"

    actions = [
        "s3:GetObject",
        "s3:ListBucket"
    ]

    resources = [
      "${aws_s3_bucket.puppet_certificates.arn}/certificates/private/*",
      "${aws_s3_bucket.puppet_certificates.arn}"
    ]
  }
}

resource "aws_iam_policy" "puppet_certificates_public_policy" {
    name = "puppet_certificates_public_policy"
    path = "/puppet/"
    policy = data.aws_iam_policy_document.puppet_certificates_public_policy.json
}

data "aws_iam_policy_document" "puppet_certificates_public_policy" {
  statement {
    sid = "AllowReadPuppetCertificatesPublic"

    actions = [
        "s3:GetObject",
        "s3:ListBucket"
    ]

    resources = [
      "${aws_s3_bucket.puppet_certificates.arn}/certificates/public/*",
      "${aws_s3_bucket.puppet_certificates.arn}"
    ]
  }
}

// dev-workstation-1 private key!
resource "aws_iam_policy" "puppet_certificates_private_dev_workstation_1_policy" {
    name = "puppet_certificates_private_dev_workstation_1_policy"
    path = "/puppet/"
    policy = data.aws_iam_policy_document.puppet_certificates_private_dev_workstation_1_policy.json
}

data "aws_iam_policy_document" "puppet_certificates_private_dev_workstation_1_policy" {
  statement {
    sid = "AllowReadPuppetCertificatesDevWorkstation1Private"

    actions = [
        "s3:GetObject",
        "s3:ListBucket"
    ]

    resources = [
      "${aws_s3_bucket.puppet_certificates.arn}/certificates/private/dev-workstation-1.*",
      "${aws_s3_bucket.puppet_certificates.arn}"
    ]
  }
}