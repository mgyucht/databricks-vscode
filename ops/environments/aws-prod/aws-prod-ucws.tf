resource "databricks_mws_workspaces" "this" {
  provider                 = databricks.account
  account_id               = module.defaults.aws_prod_databricks_account_id
  aws_region               = module.defaults.aws_region
  workspace_name           = "${local.prefix}-ws"
  credentials_id           = module.workspace.credentials_id
  storage_configuration_id = module.workspace.storage_configuration_id
}

resource "databricks_mws_workspaces" "dummy" {
  provider                 = databricks.account
  account_id               = module.defaults.aws_prod_databricks_account_id
  aws_region               = module.defaults.aws_region
  workspace_name           = "${local.prefix}-dummy"
  credentials_id           = module.workspace.credentials_id
  storage_configuration_id = module.workspace.storage_configuration_id
}

provider "databricks" {
  alias     = "workspace"
  auth_type = "basic"
  host      = databricks_mws_workspaces.this.workspace_url
  username  = data.azurerm_key_vault_secret.username.value
  password  = data.azurerm_key_vault_secret.password.value
}

module "metastore_bucket" {
  source = "../../modules/aws-bucket"
  // See ops/modules/aws-iam-unity-catalog/main.tf
  name = "deco-uc-prod-aws-us-west-2"
  tags = module.defaults.tags
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
  depends_on = [
    databricks_mws_workspaces.this
  ]
}

module "workspace_with_assigned_metastore" {
  source      = "../../modules/github-secrets"
  environment = "aws-prod-ucws"
  secrets = {
    "CLOUD_ENV" : "ucws",
    "TEST_FILTER" : "TestUcAcc",
    "DATABRICKS_HOST" : databricks_mws_workspaces.this.workspace_url,
    "DATABRICKS_USERNAME" : data.azurerm_key_vault_secret.username.value,
    "DATABRICKS_PASSWORD" : data.azurerm_key_vault_secret.password.value,
    "TEST_WORKSPACE_ID" : databricks_mws_workspaces.dummy.workspace_id,
    "THIS_WORKSPACE_ID" : databricks_mws_workspaces.this.workspace_id,
    "TEST_METASTORE_ID" : module.metastore.metastore_id,
    "TEST_METASTORE_ADMIN_GROUP_NAME" : module.account.admins.name,
    "TEST_GLOBAL_METASTORE_ID" : module.metastore.global_metastore_id,
    "TEST_BUCKET" : module.metastore_bucket.bucket,
    "TEST_METASTORE_DATA_ACCESS_ARN" : local.prod_unitycatalog_arn,
    "TEST_DATA_ENG_GROUP" : module.account.data_eng.name,
    "TEST_DATA_SCI_GROUP" : module.account.data_sci.name,
  }
}
