# Create a private S3 'scratch-space' bucket to hold temporary data used by the CTD project
resource "aws_s3_bucket" "scratch_space" {
  bucket = local.s3_bucket_name_scratch_space

  tags = {
    Name        = local.s3_bucket_name_scratch_space
    Type        = "data"
    Environment = "dev"
  }  
}

resource "aws_iam_policy" "scratch_space_read_policy" {
    name = "scratch_space_read_policy"
    path = "/dev/"
    policy = data.aws_iam_policy_document.scratch_space_read_policy.json
}

data "aws_iam_policy_document" "scratch_space_read_policy" {
  statement {
    sid = "AllowReadScratchSpace"

    actions = [
        "s3:GetObject",
        "s3:ListBucket",
        "kms:Decrypt"
    ]

    resources = [
      "${aws_s3_bucket.scratch_space.arn}"
    ]
  }
}

resource "aws_iam_policy" "scratch_space_write_all_policy" {
    name = "scratch_space_write_all_policy"
    path = "/dev/"
    policy = data.aws_iam_policy_document.scratch_space_write_all_policy.json
}

data "aws_iam_policy_document" "scratch_space_write_all_policy" {
  statement {
    sid = "AllowWriteAllScratchSpace"

    actions = [
        "s3:PutObject",
        "s3:DeleteObject",
        "kms:Decrypt"
    ]

    resources = [
      "${aws_s3_bucket.scratch_space.arn}/*",
      "${aws_s3_bucket.scratch_space.arn}"
    ]
  }
}

resource "aws_iam_policy" "scratch_space_backup_read_policy" {
    name = "scratch_space_backup_read_policy"
    path = "/dev/"
    policy = data.aws_iam_policy_document.scratch_space_backup_read_policy.json
}

data "aws_iam_policy_document" "scratch_space_backup_read_policy" {
  statement {
    sid = "AllowReadScratchSpaceBackup"

    actions = [
        "s3:GetObject",
        "s3:ListBucket",
        "kms:Decrypt"
    ]

    resources = [
      "${aws_s3_bucket.scratch_space.arn}/backup/*",
      "${aws_s3_bucket.scratch_space.arn}"
    ]
  }
}