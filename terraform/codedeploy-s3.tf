################################################################################################
# Bucket for deployments from
# https://github.com/nationalarchives/ctd-omega-editorial-frontend
################################################################################################
resource "aws_s3_bucket" "ctd-omega-frontend-deployment" {
  bucket = "ctd-omega-frontend-deployment"
}

############################################
# Block public access to deployment bucket #
############################################
resource "aws_s3_bucket_public_access_block" "web_deployment_public_access_block" {
  bucket = aws_s3_bucket.ctd-omega-frontend-deployment.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
