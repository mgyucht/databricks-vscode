module "secrets-patauth" {
  source      = "../../modules/github-secrets"
  environment = "azure-prod-pat"
  secrets = merge(module.fixtures.test_env,
    merge(module.databricks_fixtures.test_env, {
      "CLOUD_ENV" : "azure",
      "DATABRICKS_TOKEN" : module.databricks_fixtures.databricks_token,
      "DATABRICKS_HOST" : module.workspace.workspace_url,
  }))
}
