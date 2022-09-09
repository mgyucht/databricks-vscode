data "azurerm_key_vault" "meta" {
  name                = "deco-gh-meta"
  resource_group_name = module.defaults.resource_group
}

data "azurerm_key_vault_secret" "username" {
  name         = "DATABRICKS-USERNAME"
  key_vault_id = data.azurerm_key_vault.meta.id
}

data "azurerm_key_vault_secret" "password" {
  name         = "DATABRICKS-PASSWORD"
  key_vault_id = data.azurerm_key_vault.meta.id
}

provider "databricks" {
  alias      = "account"
  host       = module.defaults.aws_prod_account_console
  account_id = module.defaults.aws_prod_databricks_account_id
  username   = data.azurerm_key_vault_secret.username.value
  password   = data.azurerm_key_vault_secret.password.value
}

module "account" {
  source = "../../modules/databricks-account"
  providers = {
    databricks = databricks.account
  }
}

module "account_level_testing" {
  source      = "../../modules/github-secrets"
  environment = "aws-prod-acct"
  secrets = merge(module.fixtures.test_env, {
    "CLOUD_ENV" : "MWS", // may not be the best name in secret...
    "TEST_FILTER" : "TestMwsAcc",
    "DATABRICKS_HOST" : module.defaults.aws_prod_account_console,
    "DATABRICKS_ACCOUNT_ID" : module.defaults.aws_prod_databricks_account_id,
    "DATABRICKS_USERNAME" : data.azurerm_key_vault_secret.username.value,
    "DATABRICKS_PASSWORD" : data.azurerm_key_vault_secret.password.value,
    "TEST_CROSSACCOUNT_ARN" : local.prod_crossaccount_arn,
    "AWS_ACCOUNT_ID" : module.defaults.aws_prod_account_id,
    "AWS_REGION" : module.defaults.aws_region,
  })
}
