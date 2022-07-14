module "defaults" {
  source = "../defaults"
}

provider "azurerm" {
  features {}
  subscription_id = module.defaults.azure_development_sub
  tenant_id       = module.defaults.azure_tenant_id
}