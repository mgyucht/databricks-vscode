resource "databricks_mws_workspaces" "workspace" {
  provider = databricks.accounts

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

provider "databricks" {
  alias                  = "workspace"
  host                   = databricks_mws_workspaces.workspace.workspace_url
  google_service_account = module.service_account.email
}

module "databricks_fixtures" {
  depends_on = [
    databricks_mws_workspaces.workspace
  ]
  providers = {
    databricks = databricks.workspace
  }
  source = "../../modules/databricks-fixtures"
}

module "secrets" {
  source      = "../../modules/github-secrets"
  environment = "gcp-prod"
  secrets = {
    "CLOUD_ENV" : "gcp",
    "DATABRICKS_HOST" : databricks_mws_workspaces.workspace.workspace_url,
    "DATABRICKS_TOKEN" : databricks_mws_workspaces.workspace.token[0].token_value,
  }
}
