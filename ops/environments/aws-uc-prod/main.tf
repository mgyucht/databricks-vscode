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
  region  = module.defaults.aws_region
}

provider "azurerm" {
  features {}
  subscription_id = module.defaults.azure_development_sub
  tenant_id       = module.defaults.azure_tenant_id
}

data "azurerm_key_vault" "aws_prod_acct" {
  name                = "deco-gh-aws-acct-prod"
  resource_group_name = module.defaults.resource_group
}

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

data "local_file" "iam" {
  filename = "../aws-iam/iam-roles.json"
}

locals {
  iam_roles             = jsondecode(data.local_file.iam.content)
  prod_crossaccount_arn = local.iam_roles["prod"]["cross-account"]
  prod_unitycatalog_arn = local.iam_roles["prod"]["unity-catalog"]
  prefix                = "deco-aws-uc-prod"
}

resource "databricks_mws_credentials" "this" {
  provider         = databricks.account
  account_id       = module.defaults.aws_prod_databricks_account_id
  role_arn         = local.prod_crossaccount_arn
  credentials_name = "${local.prefix}-creds"
}

module "root_bucket" {
  source = "../../modules/aws-bucket"
  name   = "${local.prefix}-bucket"
  tags   = module.defaults.tags
}

resource "databricks_mws_storage_configurations" "this" {
  provider                   = databricks.account
  account_id                 = module.defaults.aws_prod_databricks_account_id
  storage_configuration_name = "${local.prefix}-storage"
  bucket_name                = module.root_bucket.bucket
}

resource "databricks_mws_workspaces" "this" {
  provider       = databricks.account
  account_id     = module.defaults.aws_prod_databricks_account_id
  aws_region     = module.defaults.aws_region
  workspace_name = "${local.prefix}-workaround"

  credentials_id           = databricks_mws_credentials.this.credentials_id
  storage_configuration_id = databricks_mws_storage_configurations.this.storage_configuration_id
}

module "metastore_bucket" {
  source = "../../modules/aws-bucket"
  // See ops/modules/aws-iam-unity-catalog/main.tf
  name = "deco-uc-prod-aws-us-west-2"
  tags = module.defaults.tags
}

provider "databricks" {
  alias    = "workspace"
  host     = databricks_mws_workspaces.this.workspace_url
  username = data.azurerm_key_vault_secret.username.value
  password = data.azurerm_key_vault_secret.password.value
}

module "account" {
  source = "../../modules/databricks-account"
  providers = {
    databricks = databricks.account
  }
}

module "metastore" {
  source = "../../modules/databricks-aws-metastore"
  providers = {
    databricks = databricks.workspace
  }

  name                      = module.metastore_bucket.bucket
  bucket                    = module.metastore_bucket.bucket
  metastore_data_access_arn = local.prod_unitycatalog_arn
  workspace_ids             = [databricks_mws_workspaces.this.workspace_id]
  owner_group               = module.account.admins.name
  data_eng_group            = module.account.data_eng.name
  data_sci_group            = module.account.data_sci.name
}

module "secrets" {
  source      = "../../modules/github-secrets"
  environment = "aws-uc-prod"
  secrets = {
    "CLOUD_ENV": "aws",
    "DATABRICKS_HOST": databricks_mws_workspaces.this.workspace_url,
    "DATABRICKS_USERNAME": data.azurerm_key_vault_secret.username.value,
    "DATABRICKS_PASSWORD": data.azurerm_key_vault_secret.password.value,
    "TEST_DATA_ENG_GROUP": module.account.data_eng.name,
    "TEST_DATA_SCI_GROUP": module.account.data_sci.name,
  }
}
