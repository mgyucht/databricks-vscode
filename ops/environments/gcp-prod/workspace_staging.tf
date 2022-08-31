resource "databricks_mws_workspaces" "deco_staging" {
  provider = databricks.staging

  account_id     = module.defaults.google_staging_account
  workspace_name = "deco-staging-gcp-us-central1"
  location       = module.defaults.google_region
  pricing_tier   = "PREMIUM"

  cloud_resource_bucket {
    gcp {
      project_id = module.defaults.google_project
    }
  }
}

module "secrets_staging" {
  source      = "../../modules/github-secrets"
  environment = "gcp-staging"
  secrets = {
    "CLOUD_ENV" : "gcp",
    "DATABRICKS_HOST" : databricks_mws_workspaces.deco_staging.workspace_url,
    "DATABRICKS_GOOGLE_SERVICE_ACCOUNT" : google_service_account.admin.email,
  }
}
