module "secrets_peco" {
  source      = "../../modules/github-secrets"
  environment = "azure-prod-peco"
  secrets = merge(
    {
      "CLOUD_ENV" : "azure",
      "DATABRICKS_HOST" : module.workspace_usr.workspace_url,
      "DATABRICKS_TOKEN" : databricks_token.spn_usr_nonadmin.token_value,
    },
    {
      for k, v in module.databricks_fixtures_usr.test_env : k => v
      if length(regexall("^TEST_PECO_WAREHOUSE", k)) > 0
    },
  )
}
