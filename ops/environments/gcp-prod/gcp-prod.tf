resource "databricks_mws_workspaces" "workspace" {
  provider = databricks.account

  account_id     = module.defaults.google_production_account
  workspace_name = "deco-prod-gcp-us-central1"
  location       = module.defaults.google_region
  pricing_tier   = "PREMIUM"

  cloud_resource_container {
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
  cloud  = "gcp"
}

# DBSQL endpoints in GCP are only available in our production workspace.
# It is explicitly disallowed in our staging workspace because it has HIPAA compliance enabled.
module "sql_warehouses" {
  providers = {
    databricks = databricks.workspace
  }
  source = "../../modules/databricks-sql-warehouses"
}

module "secrets" {
  source      = "../../modules/github-secrets"
  environment = "gcp-prod"
  secrets = merge(
    module.databricks_fixtures.test_env,
    module.sql_warehouses.test_env,
    {
      "CLOUD_ENV" : "gcp",
      "DATABRICKS_HOST" : databricks_mws_workspaces.workspace.workspace_url,
      "GOOGLE_CREDENTIALS" : google_service_account_key.this.private_key,
    },
  )
}
