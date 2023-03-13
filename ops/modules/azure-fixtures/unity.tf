//
// See https://registry.terraform.io/providers/databricks/databricks/latest/docs/guides/unity-catalog-azure#configure-azure-objects
//

resource "azurerm_storage_account" "unity" {
  name                     = "${var.prefix}unity"
  resource_group_name      = data.azurerm_resource_group.this.name
  location                 = data.azurerm_resource_group.this.location
  tags                     = data.azurerm_resource_group.this.tags
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  // Unity Catalog requires Hierarchical Namespaces to be enabled.
  //
  // See:
  // * https://learn.microsoft.com/en-us/azure/databricks/data-governance/unity-catalog/create-metastore
  // * https://learn.microsoft.com/en-us/azure/storage/blobs/create-data-lake-storage-account
  //
  is_hns_enabled = true
}

output "unity_storage_account_id" {
  value = azurerm_storage_account.unity.id
}

output "unity_storage_account_name" {
  value = azurerm_storage_account.unity.name
}

resource "azurerm_storage_container" "unity" {
  name                  = "${var.prefix}-unity"
  storage_account_name  = azurerm_storage_account.unity.name
  container_access_type = "private"
}

output "unity_storage_container_name" {
  value = azurerm_storage_container.unity.name
}

resource "azurerm_databricks_access_connector" "unity" {
  name                = "${var.prefix}-databricks-mi"
  resource_group_name = data.azurerm_resource_group.this.name
  location            = data.azurerm_resource_group.this.location

  identity {
    type = "SystemAssigned"
  }
}

output "unity_access_connector_id" {
  value = azurerm_databricks_access_connector.unity.id
}

// Grant storage contributor to managed identity.
resource "azurerm_role_assignment" "unity" {
  scope                = azurerm_storage_account.unity.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_databricks_access_connector.unity.identity[0].principal_id
}
