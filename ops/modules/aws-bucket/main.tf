variable "name" {
  type = string
}

variable "tags" {
  default = {}
}

resource "aws_s3_bucket" "this" {
  bucket = var.name
  force_destroy = true
  tags = merge(var.tags, {
    Name = var.name
  })
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
  depends_on              = [aws_s3_bucket.this]
}

data "databricks_aws_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.bucket
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket     = aws_s3_bucket.this.id
  policy     = data.databricks_aws_bucket_policy.this.json
  depends_on = [aws_s3_bucket_public_access_block.this]

  lifecycle {
    // TODO: set id of databricks_aws_bucket_policy data resource to "_"
    ignore_changes = [policy]
  }
}

output "bucket" {
  value = aws_s3_bucket.this.bucket
}