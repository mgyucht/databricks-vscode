module "root_bucket" {
  source = "../aws-bucket"
  name   = "${var.name}-root-bucket"
  tags   = var.tags
}

module "metastore_bucket" {
  source = "../aws-bucket"
  name   = "${var.name}-metastore-bucket"
  tags   = var.tags
}

module "other_bucket" {
  source = "../aws-bucket"
  name   = "${var.name}-other-bucket"
  tags   = var.tags
}
