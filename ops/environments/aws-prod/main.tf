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

data "azurerm_key_vault" "aws_prod_acct" {
  name                = "deco-gh-aws-acct-prod"
  resource_group_name = module.defaults.resource_group
}

// This second environment is required because of these two secrets,
// that are added and rotated manually. Currently only the "meta"
// environment is looped onto itselft and cannot be reconstructed
// in a single apply statement.
data "azurerm_key_vault_secret" "username" {
  name         = "DATABRICKS-USERNAME"
  key_vault_id = data.azurerm_key_vault.aws_prod_acct.id
}

data "azurerm_key_vault_secret" "password" {
  name         = "DATABRICKS-PASSWORD"
  key_vault_id = data.azurerm_key_vault.aws_prod_acct.id
}

provider "databricks" {
  alias      = "account"
  host       = module.defaults.aws_prod_account_console
  account_id = module.defaults.aws_prod_databricks_account_id
  username   = data.azurerm_key_vault_secret.username.value
  password   = data.azurerm_key_vault_secret.password.value
}

module "workspace" {
  source = "../../modules/aws-databricks-workspace"
  providers = {
    databricks = databricks.account
  }

  prefix                 = "deco-aws-nouc-prod"
  databricks_account_id  = module.defaults.aws_prod_databricks_account_id
  cross_account_role_arn = local.prod_crossaccount_arn
  security_group_ids     = module.fixtures.security_group_ids
  subnet_ids             = module.fixtures.private_subnets
  bucket_name            = module.fixtures.bucket_name
  region                 = module.defaults.aws_region
  vpc_id                 = module.fixtures.vpc_id

  // these require ENTERPRISE tier, which is rolled out via Jenkins job
  // https://jenkins.cloud.databricks.com/job/eng-cal-team/job/UpdateE2Account/
  managed_services_cmk_arn   = module.fixtures.managed_services_cmk_arn
  managed_services_cmk_alias = module.fixtures.managed_services_cmk_alias
  storage_cmk_arn            = module.fixtures.storage_cmk_arn
  storage_cmk_alias          = module.fixtures.storage_cmk_alias
}

module "secrets" {
  source      = "../../modules/github-secrets"
  environment = "aws-prod"
  secrets = merge(module.fixtures.test_env, {
    "CLOUD_ENV" : "aws",
    "DATABRICKS_HOST" : module.workspace.databricks_host
    "DATABRICKS_TOKEN" : module.workspace.databricks_token
  })
}
