module "workspace_ucws" {
  source      = "../../modules/azure-databricks-workspace"
  location    = "eastus2"
  environment = "prod"
  suffix      = "-ucws"
}

provider "databricks" {
  alias = "workspace_ucws"
  host  = module.workspace_ucws.workspace_url

  auth_type                   = "azure-client-secret"
  azure_client_id             = module.account_admin_spn.client_id
  azure_client_secret         = module.account_admin_spn.client_secret
  azure_tenant_id             = module.defaults.azure_tenant_id
  azure_workspace_resource_id = module.workspace_ucws.resource_id
}

// Provision storage container in the prod storage account for metastore.
resource "azurerm_storage_container" "unity_catalog" {
  name                  = "ucws"
  storage_account_name  = module.fixtures.storage_account_name
  container_access_type = "private"
}

module "metastore" {
  source = "../../modules/databricks-azure-metastore"
  providers = {
    databricks = databricks.workspace_ucws
  }

  name = "deco-prod-azure-eastus2"

  storage_account_name   = module.fixtures.storage_account_name
  storage_container_name = azurerm_storage_container.unity_catalog.name
  workspace_ids          = [module.workspace_ucws.workspace_id]

  owner_group    = module.account.admins.name
  data_eng_group = module.account.data_eng.name
  data_sci_group = module.account.data_sci.name

  depends_on = [
    module.workspace_ucws,
    module.account_admin_spn,
  ]
}
