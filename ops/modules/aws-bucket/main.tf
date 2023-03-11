variable "name" {
  type = string
}

variable "tags" {
  default = {} // todo: merge with defaults
}

variable "aws_account_id" {
  type = number
}

resource "aws_s3_bucket" "this" {
  bucket        = var.name
  force_destroy = true
  tags = merge(var.tags, {
    Name = var.name
  })

  lifecycle {
    ignore_changes = [
      # "IntelligentTieringManagedByCustodian" is added by other automation.
      tags,
      # Rule ID "company-s3-lifecycle-rules-auto-tiering" is added by other automation.
      lifecycle_rule,
    ]
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
  depends_on              = [aws_s3_bucket.this]
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.this.id
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "arn:aws:iam::${var.aws_account_id}:root"
        },
        "Action" : [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ],
        "Resource" : [
          "arn:aws:s3:::${var.name}/*",
          "arn:aws:s3:::${var.name}"
        ]
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.this]
}

output "bucket" {
  value = aws_s3_bucket.this.bucket
}
