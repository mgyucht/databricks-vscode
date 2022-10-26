terraform {
  required_providers {
    databricks = {
      source = "databricks/databricks"
    }
  }
}

module "defaults" {
  source = "../../modules/defaults"
}

provider "azurerm" {
  features {}
  subscription_id = module.defaults.azure_production_sub
  tenant_id       = module.defaults.azure_tenant_id
}

provider "azuread" {
  tenant_id = module.defaults.azure_tenant_id
}
