resource "azurerm_resource_group" "this" {
  name     = module.defaults.resource_group
  location = "westeurope"
  tags     = module.defaults.tags
}

resource "azurerm_storage_account" "terraform_state" {
  name                     = "decotfstate" // alphanum only
  resource_group_name      = azurerm_resource_group.this.name
  location                 = azurerm_resource_group.this.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  tags                     = azurerm_resource_group.this.tags
}

resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_name  = azurerm_storage_account.terraform_state.name
  container_access_type = "private"
}

data "azuread_users" "admins" {
  user_principal_names = [for u in module.defaults.admins :
  "${replace(u, "@", "_")}#EXT#@dbtestcustomer.onmicrosoft.com"]
}

resource "azurerm_role_assignment" "can_terraform_apply_locally" {
  for_each             = toset(data.azuread_users.admins.object_ids)
  scope                = azurerm_storage_account.terraform_state.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = each.value
}

module "spn" {
  source = "../../modules/azure-service-principal"
  name   = "deco-meta-spn"
  roles_on_resources = {
    "Storage Blob Data Contributor" : azurerm_storage_account.terraform_state.id,
    "Contributor" : azurerm_resource_group.this.id,
  }
}

data "azurerm_client_config" "current" {}

module "secrets" {
  source      = "../../modules/github-secrets"
  environment = "meta"
  secrets = {
    "ARM_CLIENT_ID" : module.spn.client_id,
    "ARM_CLIENT_SECRET" : module.spn.client_secret,
    "ARM_TENANT_ID" : data.azurerm_client_config.current.tenant_id,
  }
}
