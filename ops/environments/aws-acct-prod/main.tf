terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
    databricks = {
      source  = "databricks/databricks"
      version = ">= 1.0.0"
    }
  }
}

module "defaults" {
  source = "../../modules/defaults"
}

provider "aws" {
  profile = "aws-dev_databricks-power-user"
  region = module.defaults.aws_region
}

data "local_file" "iam" {
  filename = "../aws-iam/iam-roles.json"
}

locals {
  iam_roles = jsondecode(data.local_file.iam.content)
  prod_crossaccount_arn = local.iam_roles["prod"]["cross-account"]
  prod_unitycatalog_arn = local.iam_roles["prod"]["unity-catalog"]
}

module "fixtures" {
  source         = "../../modules/aws-fixtures"
  databricks_account_id = module.defaults.aws_prod_databricks_account_id
  databricks_cross_account_role = local.prod_crossaccount_arn
  region = module.defaults.aws_region
  tags = module.defaults.tags
  cidr_block = "10.5.0.0/16"
  name = "deco-aws-acct-prod"
}

module "secrets" {
  source      = "../../modules/github-secrets"
  environment = "aws-acct-prod"
  secrets = merge(module.fixtures.test_env, {
    "CLOUD_ENV": "MWS", // may not be the best name in secret...
    "TEST_FILTER": "TestMwsAcc",
    "DATABRICKS_HOST": "https://accounts.cloud.databricks.com/",
    "DATABRICKS_ACCOUNT_ID": module.defaults.aws_prod_databricks_account_id,
    "TEST_CROSSACCOUNT_ARN": local.prod_crossaccount_arn,
    "AWS_ACCOUNT_ID": module.defaults.aws_prod_account_id,
    "AWS_REGION": module.defaults.aws_region,
  })
}
