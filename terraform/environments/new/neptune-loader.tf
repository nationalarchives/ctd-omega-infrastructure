# Create a private S3 'neptune-loader' bucket to hold the data for loading into neptune
resource "aws_s3_bucket" "neptune_loader" {
  bucket = local.s3_bucket_name_neptune_loader

  tags = {
    Name        = local.s3_bucket_name_neptune_loader
    Type        = "data"
    Environment = "management"
  }
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id       = module.vpc.vpc_id
  vpc_endpoint_type = "Gateway"
  service_name = "com.amazonaws.${local.aws_region}.s3"
  route_table_ids = module.vpc.intra_route_table_ids
}


resource "aws_iam_role" "neptune_loader_iam_role" {
  name = "neptune_loader_role"
  path = "/neptune/"
  assume_role_policy = data.aws_iam_policy_document.neptune_service_assume_role_policy.json
  managed_policy_arns = [
      aws_iam_policy.neptune_loader_policy.arn
  ]
}

resource "aws_iam_policy" "neptune_loader_policy" {
    name = "neptune_loader_policy"
    path = "/neptune/"
    policy = data.aws_iam_policy_document.neptune_loader_policy.json
}

data "aws_iam_policy_document" "neptune_loader_policy" {
  statement {
    sid = "AllowReadNeptuneLoader"

    actions = [
        "s3:GetObject",
        "s3:ListBucket",
        "kms:Decrypt"
    ]

    resources = [
      "${aws_s3_bucket.neptune_loader.arn}/neptune/loader/*",
      "${aws_s3_bucket.neptune_loader.arn}"
    ]
  }
}
