terraform {
  required_providers {
    databricks = {
      source = "databricks/databricks"
    }
  }
}

provider "databricks" {
  host = "https://734653476174839.9.gcp.databricks.com"

  google_service_account = "deco-admin@eng-dev-ecosystem.iam.gserviceaccount.com"
}
