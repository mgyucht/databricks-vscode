module "defaults" {
  source = "../../modules/defaults"
}

provider "azurerm" {
  features {}
  subscription_id = module.defaults.azure_staging_sub
  tenant_id       = module.defaults.azure_tenant_id
}
