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

provider "google" {
  project = module.defaults.google_project
  region  = module.defaults.google_region
}

provider "databricks" {
  alias = "accounts"
  host  = "https://accounts.staging.gcp.databricks.com"

  auth_type              = "google-accounts"
  google_service_account = module.service_account.email
}
