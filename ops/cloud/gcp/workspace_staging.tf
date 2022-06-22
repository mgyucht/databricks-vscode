resource "databricks_mws_workspaces" "deco_staging" {
  provider = databricks.staging

  account_id     = "9fcbb245-7c44-4522-9870-e38324104cf8"
  workspace_name = "deco-staging-gcp-us-central1"
  location       = "us-central1"
  pricing_tier   = "PREMIUM"

  cloud_resource_bucket {
    gcp {
      project_id = "eng-dev-ecosystem"
    }
  }
}
