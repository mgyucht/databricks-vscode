terraform {
  required_providers {
    databricks = {
      source  = "databricks/databricks"
      version = ">= 1.0.0"
    }
  }
}

variable "env_name" {
  type = string
}

variable "databricks_account_id" {
  type = string
}

variable "aws_databricks_account_id" {
  type = string
}

data "databricks_aws_assume_role_policy" "workspace" {
  external_id           = var.databricks_account_id
  databricks_account_id = var.aws_databricks_account_id
}

resource "aws_iam_role" "workspace" {
  name               = "deco_workspace_${var.env_name}"
  assume_role_policy = data.databricks_aws_assume_role_policy.workspace.json
  tags = {
    Owner = "eng-dev-ecosystem-team@databricks.com"
  }
}

data "databricks_aws_crossaccount_policy" "workspace" {
  pass_roles = [
  ]
}

resource "aws_iam_role_policy" "workspace" {
  name   = "workspace"
  role   = aws_iam_role.workspace.id
  policy = data.databricks_aws_crossaccount_policy.workspace.json
}

output "arn" {
  value = aws_iam_role.workspace.arn
}