module "workspace_staging" {
  source = "./modules/workspace"

  providers = {
    azurerm = azurerm.staging
  }

  location       = "East US 2"
  location_short = "eastus2"
  environment    = "staging"
}
