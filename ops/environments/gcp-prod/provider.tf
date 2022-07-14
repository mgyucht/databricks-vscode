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
  alias = "staging"
  host  = "https://accounts.staging.gcp.databricks.com"

  auth_type              = "google-accounts"
  google_service_account = google_service_account.admin.email
}

provider "databricks" {
  alias = "production"
  host  = "https://accounts.gcp.databricks.com"

  auth_type              = "google-accounts"
  google_service_account = google_service_account.admin.email
}
