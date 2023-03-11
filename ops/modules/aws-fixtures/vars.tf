variable "databricks_account_id" {
  description = "Account Id that could be found in the bottom left corner of https://accounts.cloud.databricks.com/"
}

variable "databricks_cross_account_role" {
  description = "AWS ARN for the Databricks cross account role"
}

variable "aws_account_id" {
  type        = number
  description = "AWS account ID of Databricks (different for production and staging)"
}

variable "tags" {
  default = {}
}

variable "cidr_block" {}

variable "region" {}

variable "name" {}

locals {
  // this module is a port and testbed for the following guide
  // https://registry.terraform.io/providers/databricks/databricks/latest/docs/guides/aws-workspace
  prefix = var.name
}
