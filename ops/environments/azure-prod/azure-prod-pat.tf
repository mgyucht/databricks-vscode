module "secrets-patauth" {
  source      = "../../modules/github-secrets"
  environment = "azure-prod-pat"
  secrets = merge(module.fixtures.test_env, {
    "CLOUD_ENV" : "azure",
    "TEST_DEFAULT_CLUSTER_ID" : module.databricks_fixtures.default_cluster_id
    "DATABRICKS_TOKEN" : module.databricks_fixtures.databricks_token
    "DATABRICKS_HOST" : module.workspace.workspace_url,
  })
}
