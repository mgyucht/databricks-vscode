terraform {
  backend "azurerm" {
    resource_group_name  = "eng-dev-ecosystem-rg"
    storage_account_name = "decotfstate"
    container_name       = "tfstate"
    key                  = "ops/workspaces/deco-staging-azure-eastus2/terraform.tfstate"
  }
}