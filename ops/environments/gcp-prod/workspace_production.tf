resource "databricks_mws_workspaces" "deco_production" {
  provider = databricks.production

  account_id     = module.defaults.google_production_account
  workspace_name = "deco-prod-gcp-us-central1"
  location       = module.defaults.google_region
  pricing_tier   = "PREMIUM"

  cloud_resource_bucket {
    gcp {
      project_id = module.defaults.google_project
    }
  }

  token {}
}

module "secrets" {
  source      = "../../modules/github-secrets"
  environment = "gcp-prod"
  secrets = {
    "DATABRICKS_HOST" : databricks_mws_workspaces.deco_production.workspace_url,
    "DATABRICKS_TOKEN" : databricks_mws_workspaces.deco_production.token[0].token_value,
  }
}