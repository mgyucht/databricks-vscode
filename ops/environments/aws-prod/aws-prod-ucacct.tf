module "uc_account" {
  source      = "../../modules/github-secrets"
  environment = "aws-prod-ucacct"
  secrets = {
    "CLOUD_ENV" : "ucacct",
    "TEST_FILTER" : "TestUcAcc",
    "DATABRICKS_HOST" : module.defaults.aws_prod_account_console,
    "DATABRICKS_ACCOUNT_ID" : module.defaults.aws_prod_databricks_account_id,
    "DATABRICKS_USERNAME" : data.azurerm_key_vault_secret.username.value,
    "DATABRICKS_PASSWORD" : data.azurerm_key_vault_secret.password.value,
    "TEST_WORKSPACE_ID" : databricks_mws_workspaces.this.workspace_id,
    "TEST_METASTORE_ID" : module.metastore.metastore_id,
    "TEST_GLOBAL_METASTORE_ID" : module.metastore.global_metastore_id,
    "TEST_DATA_ENG_GROUP" : module.account.data_eng.name,
    "TEST_DATA_SCI_GROUP" : module.account.data_sci.name,
  }
}
