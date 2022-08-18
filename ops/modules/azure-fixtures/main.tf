variable "prefix" {}

variable "resource_group" {}

data "azurerm_resource_group" "this" {
  name = var.resource_group
}

// Create container in storage acc and container for use by blob mount tests
resource "azurerm_storage_account" "v2" {
  name                     = "${var.prefix}adlsv2"
  resource_group_name      = data.azurerm_resource_group.this.name
  location                 = data.azurerm_resource_group.this.location
  tags                     = data.azurerm_resource_group.this.tags
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
}

output "storage_account_id" {
  value = azurerm_storage_account.v2.id
}

resource "azurerm_storage_container" "wasbs" {
  name                  = "${var.prefix}-wasbs"
  storage_account_name  = azurerm_storage_account.v2.name
  container_access_type = "private"
}

data "azurerm_storage_account_blob_container_sas" "this" {
  connection_string = azurerm_storage_account.v2.primary_connection_string
  container_name    = azurerm_storage_container.wasbs.name
  https_only        = true
  start             = "2022-02-01"
  expiry            = "2022-12-31"
  permissions {
    read   = true
    add    = true
    create = true
    write  = true
    delete = true
    list   = true
  }
}

resource "azurerm_storage_blob" "this" {
  name                   = "main.tf"
  storage_account_name   = azurerm_storage_account.v2.name
  storage_container_name = azurerm_storage_container.wasbs.name
  type                   = "Block"
  source                 = "${path.module}/main.tf"
}

resource "azurerm_storage_container" "abfss" {
  name                  = "${var.prefix}-abfss"
  storage_account_name  = azurerm_storage_account.v2.name
  container_access_type = "private"
}

resource "azurerm_storage_blob" "example" {
  name                   = "main.tf"
  storage_account_name   = azurerm_storage_account.v2.name
  storage_container_name = azurerm_storage_container.abfss.name
  type                   = "Block"
  source                 = "${path.module}/main.tf"
}

data "azurerm_client_config" "current" {}

module "defaults" {
  source = "../defaults"
}

data "azuread_users" "admins" {
  user_principal_names = [for u in module.defaults.admins :
  "${replace(u, "@", "_")}#EXT#@dbtestcustomer.onmicrosoft.com"]
}

resource "azurerm_key_vault" "this" {
  name                     = "${var.prefix}-kv"
  resource_group_name      = data.azurerm_resource_group.this.name
  location                 = data.azurerm_resource_group.this.location
  tags                     = data.azurerm_resource_group.this.tags
  tenant_id                = data.azurerm_client_config.current.tenant_id
  purge_protection_enabled = false
  sku_name                 = "standard"

  dynamic "access_policy" {
    // we may want to add the SPN client_id from current caller identity
    // as this thing has to be settable on github actions in automation
    for_each = toset(data.azuread_users.admins.object_ids)
    content {
      object_id = access_policy.value
      tenant_id = module.defaults.azure_tenant_id
      secret_permissions = ["Set", "Get", "List", "Delete",
      "Purge", "Recover", "Restore"]
    }
  }
}

output "key_vault_id" {
  value = azurerm_key_vault.this.id
}

// "Key Vault Administrator" role required for SP
resource "azurerm_key_vault_secret" "this" {
  name         = "answer"
  value        = "42"
  key_vault_id = azurerm_key_vault.this.id
  tags         = data.azurerm_resource_group.this.tags
}

output "test_env" {
  value = {
    "TEST_STORAGE_V2_ACCOUNT" : azurerm_storage_account.v2.name,
    "TEST_STORAGE_V2_KEY" : azurerm_storage_account.v2.primary_access_key,
    "TEST_STORAGE_V2_WASBS" : azurerm_storage_container.wasbs.name,
    "TEST_STORAGE_V2_WASBS_SAS" : data.azurerm_storage_account_blob_container_sas.this.sas,
    "TEST_STORAGE_V2_ABFSS" : azurerm_storage_container.abfss.name,
    "TEST_KEY_VAULT_NAME" : azurerm_key_vault.this.name,
    "TEST_KEY_VAULT_RESOURCE_ID" : azurerm_key_vault.this.id,
    "TEST_KEY_VAULT_DNS_NAME" : azurerm_key_vault.this.vault_uri,
    "TEST_KEY_VAULT_SECRET" : azurerm_key_vault_secret.this.name,
    "TEST_KEY_VAULT_SECRET_VALUE" : azurerm_key_vault_secret.this.value
  }
}

module "dummy" {
  source = "../dummy"
}