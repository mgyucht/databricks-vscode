terraform {
  required_providers {
    databricks = {
      source = "databricks/databricks"
    }
  }
}

provider "google" {
  project = "eng-dev-ecosystem"
  region  = "us-central1"
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
