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

provider "azurerm" {
  features {}
  subscription_id = module.defaults.azure_development_sub
  tenant_id       = module.defaults.azure_tenant_id
}

module "defaults" {
  source = "../../modules/defaults"
}

provider "aws" {
  profile = "aws-dev_databricks-power-user"
  region  = module.defaults.aws_region
}

data "local_file" "iam" {
  filename = "../aws-iam/iam-roles.json"
}

locals {
  prefix                = "deco-aws-prod"
  cidr_block            = "10.6.0.0/16"
  iam_roles             = jsondecode(data.local_file.iam.content)
  prod_crossaccount_arn = local.iam_roles["prod"]["cross-account"]
  prod_unitycatalog_arn = local.iam_roles["prod"]["unity-catalog"]
}

module "fixtures" {
  source                        = "../../modules/aws-fixtures"
  databricks_account_id         = module.defaults.aws_prod_databricks_account_id
  databricks_cross_account_role = local.prod_crossaccount_arn
  region                        = module.defaults.aws_region
  tags                          = module.defaults.tags
  cidr_block                    = "10.5.0.0/16"
  name                          = "deco-prod-aws-${module.defaults.aws_region}"
}
