terraform {
  backend "azurerm" {
    resource_group_name  = "eng-dev-ecosystem-rg"
    storage_account_name = "decotfstate"
    container_name       = "tfstate"
    // TODO: rename this state file on backend
    key                  = "ops/environments/aws-prod/terraform.tfstate"
  }
}