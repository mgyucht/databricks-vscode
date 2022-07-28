terraform {
  required_providers {
    databricks = {
      source = "databricks/databricks"
    }
  }
}

data "terraform_remote_state" "meta" {
  backend = "azurerm"

  config = {
    resource_group_name  = "eng-dev-ecosystem-rg"
    storage_account_name = "decotfstate"
    container_name       = "tfstate"
    key                  = "ops/environments/meta/terraform.tfstate"
  }
}

locals {
  can_of_worms = data.terraform_remote_state.meta.outputs.secrets
}
provider "databricks" {
  host                = local.can_of_worms["deco-gh-azure-prod:DATABRICKS-HOST"]
  azure_client_id     = local.can_of_worms["deco-gh-azure-prod:ARM-CLIENT-ID"]
  azure_client_secret = local.can_of_worms["deco-gh-azure-prod:ARM-CLIENT-SECRET"]
  azure_tenant_id     = local.can_of_worms["deco-gh-azure-prod:ARM-TENANT-ID"]
}
