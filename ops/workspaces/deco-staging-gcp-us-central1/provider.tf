terraform {
  required_providers {
    databricks = {
      source = "databricks/databricks"
    }
  }
}

provider "databricks" {
  host = "https://1679816285419850.0.staging.gcp.databricks.com"

  google_service_account = "deco-admin@eng-dev-ecosystem.iam.gserviceaccount.com"
}
