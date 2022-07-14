module "workspace" {
  source      = "../../modules/azure-databricks-workspace"
  azure_databricks_app_id = "4a67d088-db5c-48f1-9ff2-0aace800ae68"
  location    = "eastus2"
  environment = "staging"
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

// TODO: azurerm_key_vault_access_policy for SPN and team users

module "secrets" {
  source      = "../../modules/github-secrets"
  environment = "azure-stg"
  secrets = merge(module.fixtures.test_env, {
    "DATABRICKS_HOST" : module.workspace.workspace_url,
    // DATABRICKS_TOKEN added manually
  })
}
