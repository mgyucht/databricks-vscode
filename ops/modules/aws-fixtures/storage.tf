module "root_bucket" {
  source = "../aws-bucket"
  name   = "${var.name}-root-bucket"
  tags   = var.tags

  aws_account_id = var.aws_account_id
}

module "metastore_bucket" {
  source = "../aws-bucket"
  name   = "${var.name}-metastore-bucket"
  tags   = var.tags

  aws_account_id = var.aws_account_id
}

module "other_bucket" {
  source = "../aws-bucket"
  name   = "${var.name}-other-bucket"
  tags   = var.tags

  aws_account_id = var.aws_account_id
}
