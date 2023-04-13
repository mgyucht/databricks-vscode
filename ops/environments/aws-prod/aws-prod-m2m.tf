// Provision non-admin SPN at the workspace level.
resource "databricks_service_principal" "spn_ucws_nonadmin" {
  provider = databricks.ucws

  active                     = true
  allow_cluster_create       = false
  allow_instance_pool_create = false
}

resource "databricks_service_principal_secret" "spn_ucws_nonadmin" {
  provider             = databricks.ucws
  service_principal_id = databricks_service_principal.spn_ucws_nonadmin.id
}

module "workspace_m2m_auth" {
  source      = "../../modules/github-secrets"
  environment = "aws-prod-m2m"
  secrets = {
    "DATABRICKS_HOST" : databricks_mws_workspaces.this.workspace_url,
    "DATABRICKS_CLIENT_ID" : databricks_service_principal.spn_ucws_nonadmin.id,
    "DATABRICKS_CLIENT_SECRET" : databricks_service_principal_secret.spn_ucws_nonadmin.secret,
  }
}
