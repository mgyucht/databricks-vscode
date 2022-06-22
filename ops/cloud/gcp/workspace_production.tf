resource "databricks_mws_workspaces" "deco_production" {
  provider = databricks.production

  account_id     = "e11e38c5-a449-47b9-b37f-0fa36c821612"
  workspace_name = "deco-prod-gcp-us-central1"
  location       = "us-central1"
  pricing_tier   = "PREMIUM"

  cloud_resource_bucket {
    gcp {
      project_id = "eng-dev-ecosystem"
    }
  }
}
