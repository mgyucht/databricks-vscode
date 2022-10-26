module "workspace" {
  source                  = "../../modules/azure-databricks-workspace"
  azure_databricks_app_id = "4a67d088-db5c-48f1-9ff2-0aace800ae68"
  location                = "eastus2"
  environment             = "staging"
}

module "fixtures" {
  source         = "../../modules/azure-fixtures"
  resource_group = module.workspace.resource_group
  prefix         = "decoteststaging"
}

module "spn" {
  source = "../../modules/azure-service-principal"
  name   = "deco-staging-spn"
  roles_on_resources = {
    "Storage Blob Data Contributor" : module.fixtures.storage_account_id,
    "Key Vault Administrator" : module.fixtures.key_vault_id,
    "Contributor" : module.workspace.resource_group_id,
  }
}

provider "databricks" {
  alias = "workspace"
  host  = module.workspace.workspace_url

  azure_client_id     = module.spn.client_id
  azure_client_secret = module.spn.client_secret
  azure_tenant_id     = module.defaults.azure_tenant_id
  azure_login_app_id  = "4a67d088-db5c-48f1-9ff2-0aace800ae68"
}

module "databricks_fixtures" {
  depends_on = [
    module.spn,
  ]
  providers = {
    databricks = databricks.workspace
  }
  source = "../../modules/databricks-fixtures"
}

// TODO: azurerm_key_vault_access_policy for SPN and team users

module "secrets" {
  source      = "../../modules/github-secrets"
  environment = "azure-stg"
  secrets = merge(module.fixtures.test_env, {
    "CLOUD_ENV" : "azure",
    "DATABRICKS_HOST" : module.workspace.workspace_url,
    "DATABRICKS_AZURE_RESOURCE_ID" : module.workspace.resource_id,
    "ARM_TENANT_ID" : module.defaults.azure_tenant_id,
    "ARM_CLIENT_SECRET" : module.spn.client_secret,
    "ARM_CLIENT_ID" : module.spn.client_id,

    // In staging we need to authenticate with a non-standard login application,
    // before we authenticate for the workspace. The login application ID for
    // production is hardcoded in the SDK.
    "DATABRICKS_AZURE_LOGIN_APP_ID" : "4a67d088-db5c-48f1-9ff2-0aace800ae68",
  })
}
