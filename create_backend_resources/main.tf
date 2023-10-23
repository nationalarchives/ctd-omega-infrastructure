###
# Terraform Script to create pre-requisite individual resources for a Terraform Backend using an AWS S3 Bucket for Remote State Storage and a DynamoDB Table for state locking.
#
# Author: Adam Retter @ Evolved Binary
#         Jay Thomas @ DevOps Direct Tooling
###

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.11.0"
    }
  }

  required_version = ">= 1.5.4"
}

provider "aws" {
  profile = var.profile
  region  = var.region
}

resource "aws_kms_key" "tna-ct-omega-remote-state" {
  description             = "Remote State S3 Bucket KMS key"
  deletion_window_in_days = 10
}

resource "aws_s3_bucket" "tna-ct-omega-remote-state" {
  bucket = "tna-ct-omega-remote-state"

  lifecycle {
    prevent_destroy = true
  }

  tags = (merge(
    local.tags_common,
    tomap({
      "Name" = "S3 bucket for Terraform remote state storage",
    })
  ))
}

resource "aws_s3_bucket_ownership_controls" "tna-ct-omega-remote-state" {
  bucket = aws_s3_bucket.tna-ct-omega-remote-state.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "tna-ct-omega-remote-state" {
  depends_on = [aws_s3_bucket_ownership_controls.tna-ct-omega-remote-state]

  bucket = aws_s3_bucket.tna-ct-omega-remote-state.id
  acl    = "private"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tna-ct-omega-remote-state" {
  bucket = aws_s3_bucket.tna-ct-omega-remote-state.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.tna-ct-omega-remote-state.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_versioning" "tna-ct-omega-remote-state" {
  bucket = aws_s3_bucket.tna-ct-omega-remote-state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_dynamodb_table" "tna-ct-omega-remote-state" {
  name           = "tna-ct-omega-remote-state-lock-table"
  hash_key       = "LockID"
  read_capacity  = 20
  write_capacity = 20

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = (merge(
    local.tags_common,
    tomap({
      "Name" = "DynamoDB table for Terraform state lock",
    })
  ))
}
