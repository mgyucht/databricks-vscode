# Note: this bucket was created before adding `backend.tf`.
# Obviously, we need to create the bucket before we can use it...
resource "aws_s3_bucket" "terraform_state" {
  bucket = "deco-terraform-state"
  tags = {
    "Owner" = "eng-dev-ecosystem-team@databricks.com"
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
