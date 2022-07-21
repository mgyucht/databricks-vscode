provider "databricks" {
  alias = "account"
  host = module.defaults.azure_prod_account_console
  account_id = module.defaults.azure_prod_account_id
}

module "account_admin_spn" {
  source = "../../modules/azure-service-principal"
  name   = "deco-uc-prod-spn"
  roles_on_resources = {
    // TODO: grant required accesses...
  }
}

module "account" {
  source = "../../modules/databricks-account"
  providers = {
    databricks = databricks.account
  }
  azure_application_id = module.account_admin_spn.client_id
}


# module "secrets" {
#   source      = "../../modules/github-secrets"
#   environment = "azure-prod"
#   secrets = merge(module.fixtures.test_env, {
#     "DATABRICKS_HOST" : module.workspace.workspace_url,
#     "DATABRICKS_AZURE_RESOURCE_ID" : module.workspace.resource_id,
#     "ARM_TENANT_ID" : module.defaults.azure_tenant_id,
#     "ARM_CLIENT_SECRET" : module.spn.client_secret,
#     "ARM_CLIENT_ID" : module.spn.client_id,
#   })
# }
