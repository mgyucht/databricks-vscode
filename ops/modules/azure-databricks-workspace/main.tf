module "defaults" {
  source = "../defaults"
}

variable "location" {
  type = string
}

variable "environment" {
  type = string
}

variable "azure_databricks_app_id" {
  default = "2ff814a6-3304-4ab8-85cb-cd0e6f879c1d"
  type    = string
}

locals {
  name = "deco-${var.environment}-azure-${var.location}"
}

resource "azurerm_resource_group" "this" {
  name     = "${local.name}-rg"
  location = var.location
  tags     = module.defaults.tags
}

output "resource_group" {
  value = azurerm_resource_group.this.name
}

output "resource_group_id" {
  value = azurerm_resource_group.this.id
}

resource "azurerm_databricks_workspace" "this" {
  name                = local.name
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  sku                 = "premium"

  public_network_access_enabled = true
  tags                          = azurerm_resource_group.this.tags
}
data "databricks_node_type" "smallest" {
  local_disk = true
  depends_on = [azurerm_databricks_workspace.this]
}
resource "databricks_cluster" "default_test_cluster" {
  cluster_name            = "Default Test Cluster"
  spark_version           = "3.0"
  node_type_id            = data.databricks_node_type.smallest.id
  autotermination_minutes = 120
  autoscale {
    min_workers = 1
    max_workers = 50
  }
}
output "default_cluster_id" {
  value = databricks_cluster.default_test_cluster.id
}

output "resource_id" {
  value = azurerm_databricks_workspace.this.id
}

output "workspace_url" {
  value = azurerm_databricks_workspace.this.workspace_url
}
