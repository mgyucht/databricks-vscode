terraform {
  backend "azurerm" {
    # Test Customer Directory
    tenant_id = "e3fe3f22-4b98-4c04-82cc-d8817d1b17da"

    # Databricks Development Worker
    subscription_id = "36f75872-9ace-4c20-911c-aea8eba2945c"

    resource_group_name  = "eng-dev-ecosystem-rg"
    storage_account_name = "decotfstate"
    container_name       = "tfstate"
    key                  = "ops/environments/aws-uc-prod/terraform.tfstate"
  }
}
