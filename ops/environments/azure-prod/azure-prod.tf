module "workspace" {
  source      = "../../modules/azure-databricks-workspace"
  location    = "eastus2"
  environment = "prod"
}

module "fixtures" {
  source         = "../../modules/azure-fixtures"
  resource_group = module.workspace.resource_group
  prefix         = "decotestprod"
}

module "spn" {
  source = "../../modules/azure-service-principal"
  name   = "deco-prod-spn"
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
}

module "databricks_fixtures" {
  depends_on = [
    module.spn,
  ]
  providers = {
    databricks = databricks.workspace
  }
  source = "../../modules/databricks-fixtures"
  cloud  = "azure"
}

// TODO: azurerm_key_vault_access_policy for SPN and team users

module "secrets" {
  source      = "../../modules/github-secrets"
  environment = "azure-prod"
  secrets = merge(module.fixtures.test_env,
    merge(module.databricks_fixtures.test_env, {
      "CLOUD_ENV" : "azure",
      "DATABRICKS_HOST" : module.workspace.workspace_url,
      "DATABRICKS_AZURE_RESOURCE_ID" : module.workspace.resource_id,
      "ARM_TENANT_ID" : module.defaults.azure_tenant_id,
      "ARM_CLIENT_SECRET" : module.spn.client_secret,
      "ARM_CLIENT_ID" : module.spn.client_id,
  }))
}
