module "workspace_prod" {
  source = "./modules/workspace"

  providers = {
    azurerm = azurerm.production
  }

  location       = "East US 2"
  location_short = "eastus2"
  environment    = "prod"
}

output "prod_workspace_url" {
  value = module.workspace_prod.workspace_url
}
