provider "azurerm" {
  alias = "production"

  features {}

  # Subscription ID for the "Databricks Production worker" subscription.
  subscription_id = "2a5a4578-9ca9-47e2-ba46-f6ee6cc731f2"
  tenant_id       = "e3fe3f22-4b98-4c04-82cc-d8817d1b17da"
}

provider "azurerm" {
  alias = "staging"

  features {}

  # Subscription ID for the "Databricks Staging worker" subscription.
  subscription_id = "596df088-441c-4a6f-881e-5511128a3f1c"
  tenant_id       = "e3fe3f22-4b98-4c04-82cc-d8817d1b17da"
}

provider "azurerm" {
  alias = "development"

  features {}

  # Subscription ID for the "Databricks Development worker" subscription.
  subscription_id = "36f75872-9ace-4c20-911c-aea8eba2945c"
  tenant_id       = "e3fe3f22-4b98-4c04-82cc-d8817d1b17da"
}

provider "azuread" {
  # Tenant ID for the "Test Customer Directory" subscription.
  # See https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/guides/azure_cli
  tenant_id = "e3fe3f22-4b98-4c04-82cc-d8817d1b17da"
}
