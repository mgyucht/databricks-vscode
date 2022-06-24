terraform {
  required_providers {
    databricks = {
      source = "databrickslabs/databricks"
    }
  }
}

provider "databricks" {
  # Use ~/.databrickscfg for auth on Azure for symmetry with the staging workspace.
  # See [../deco-staging-azure-eastus2/provider.tf].
  profile = "deco-prod-azure-eastus2"
}
