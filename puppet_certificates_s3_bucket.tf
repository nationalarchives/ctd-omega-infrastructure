# Create a private S3 'puppet-certificates' bucket to hold the certificates
resource "aws_s3_bucket" "puppet_certificates" {
  bucket = local.s3_bucket_name_puppet_certificates

  tags = {
    Name        = "puppet_certificate"
    Type        = "certificate"
    Environment = "management"
  }
}

# Policy for accessing the CA Private Key
resource "aws_iam_policy" "puppet_ca_private_policy" {
  name   = "puppet_ca_private_policy"
  path   = "/puppet/"
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

# Policy for accessing the CA Public Key and Certificate
resource "aws_iam_policy" "puppet_ca_public_policy" {
  name   = "puppet_ca_public_policy"
  path   = "/puppet/"
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

# Policy for accessing the Agent Public Keys and Certificates
resource "aws_iam_policy" "puppet_certificates_public_policy" {
  name   = "puppet_certificates_public_policy"
  path   = "/puppet/"
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