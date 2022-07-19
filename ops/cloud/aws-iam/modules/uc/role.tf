# Allows Unity Catalog in this account to assume this role.
data "aws_iam_policy_document" "uc_assume_role_policy" {
  statement {
    sid     = "allowUnityCatalog"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type = "AWS"
      identifiers = [
        var.crossaccount_role_identifier,
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values   = [var.databricks_account_id]
    }
  }

  statement {
    sid     = "allowEc2"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = [
        "ec2.amazonaws.com",
      ]
    }
  }
}

resource "aws_iam_role" "uc" {
  name               = "deco_uc_${var.env_name}"
  assume_role_policy = data.aws_iam_policy_document.uc_assume_role_policy.json
  tags = {
    Owner = "eng-dev-ecosystem-team@databricks.com"
  }
}

# Allows Unity Catalog access to its own root bucket.
data "aws_iam_policy_document" "uc_root_buckets" {
  statement {
    sid    = "s3AccessPolicy"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:DeleteObject",
      "s3:ListBucket",
      "s3:GetBucketLocation",
    ]

    resources = [
      "arn:aws:s3:::deco-uc-${var.env_name}-aws-us-east-1",
      "arn:aws:s3:::deco-uc-${var.env_name}-aws-us-east-1/*",
      "arn:aws:s3:::deco-uc-${var.env_name}-aws-us-west-2",
      "arn:aws:s3:::deco-uc-${var.env_name}-aws-us-west-2/*",
    ]
  }
}

# Gives the Unity Catalog role read-write access to its own root buckets.
resource "aws_iam_role_policy" "uc_root_buckets" {
  role   = aws_iam_role.uc.name
  policy = data.aws_iam_policy_document.uc_root_buckets.json
}

output "name" {
  value = aws_iam_role.uc.name
}
