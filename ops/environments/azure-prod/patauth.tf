resource "databricks_token" "pat" {
  comment  = "Test token"
}
// TODO: azurerm_key_vault_access_policy for SPN and team users

module "secrets-patauth" {
  source      = "../../modules/github-secrets"
  environment = "azure-prod-pat"
  secrets = merge(module.fixtures.test_env, {
    "TEST_DEFAULT_CLUSTER_ID" : module.clusters.default_cluster_id
    "DATABRICKS_TOKEN" : databricks_token.pat.token_value
    "DATABRICKS_HOST" : module.workspace.workspace_url,
  })
}
