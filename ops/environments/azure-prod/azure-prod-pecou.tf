// Provision a catalog for this environment.
resource "databricks_catalog" "pecou" {
  provider     = databricks.workspace_ucws_account_admin
  metastore_id = module.metastore.metastore_id
  name         = "peco"
  comment      = "Integration testing for the Partner Ecosystem team"
  properties = {
    purpose = "testing"
  }
}

// Allow the non-admin SPN to create schemas in the "peco" catalog.
resource "databricks_grants" "pecou" {
  depends_on = [module.metastore]
  provider   = databricks.workspace_ucws_account_admin

  catalog = databricks_catalog.pecou.name

  grant {
    principal = databricks_service_principal.spn_ucws_nonadmin.application_id
    privileges = [
      "CREATE_SCHEMA",
      "USE_CATALOG",
    ]
  }
}

module "secrets_pecou" {
  source = "../../modules/github-secrets"

  // This environment name sucks and should really be "azure-prod-peco-uc
  // Unfortunately Azure Key Vault names have a limit of 24 characters.
  // To fix; we can evaluate sticking all secrets for an env in a single global Key Vault.
  // Then we can use the secret name to pull all secrets and not use one Key Vault per environment.
  environment = "azure-prod-pecou"
  secrets = merge(
    {
      "CLOUD_ENV" : "azure",
      "DATABRICKS_HOST" : module.workspace_ucws.workspace_url,
      "DATABRICKS_TOKEN" : databricks_token.spn_ucws_nonadmin.token_value,
    },
    {
      for k, v in module.databricks_fixtures_ucws.test_env : k => v
      if length(regexall("^TEST_PECO_WAREHOUSE_", k)) > 0 || length(regexall("^TEST_PECO_CLUSTER_", k)) > 0
    },
  )
}
