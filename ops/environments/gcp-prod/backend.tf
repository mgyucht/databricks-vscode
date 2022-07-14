terraform {
  backend "azurerm" {
    resource_group_name  = "eng-dev-ecosystem-rg"
    storage_account_name = "decotfstate"
    container_name       = "tfstate"
    key                  = "ops/environments/gcp-prod/terraform.tfstate"
  }
}