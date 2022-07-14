terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "4.26.1"
    }
  }
}

module "defaults" {
  source = "../../modules/defaults"
}

provider "azurerm" {
  features {}
  subscription_id = module.defaults.azure_development_sub
  tenant_id       = module.defaults.azure_tenant_id
}

provider "azuread" {
  tenant_id = module.defaults.azure_tenant_id
}
