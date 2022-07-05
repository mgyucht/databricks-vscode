locals {
  name = "deco-${var.environment}-azure-${var.location_short}"
}

resource "azurerm_resource_group" "this" {
  name     = "${local.name}-rg"
  location = var.location

  tags = {
    Owner = "eng-dev-ecosystem-team@databricks.com"
  }
}

resource "azurerm_databricks_workspace" "this" {
  name                = local.name
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  sku                 = "premium"

  public_network_access_enabled = true

  tags = {
    Owner = "eng-dev-ecosystem-team@databricks.com"
  }
}

output "workspace_url" {
  value = azurerm_databricks_workspace.this.workspace_url
}