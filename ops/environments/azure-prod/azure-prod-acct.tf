provider "databricks" {
  alias      = "account"
  host       = module.defaults.azure_prod_account_console
  account_id = module.defaults.azure_prod_account_id
}

module "account_admin_spn" {
  source = "../../modules/azure-service-principal"
  name   = "deco-prod-acct-admin-spn"
  roles_on_resources = {
    // TODO: grant required accesses...
  }
}

module "account_dataeng_spn" {
  source = "../../modules/azure-service-principal"
  name   = "deco-prod-acct-dataeng-spn"
  roles_on_resources = {
    // TODO: grant required accesses...
  }
}

module "account_datasci_spn" {
  source = "../../modules/azure-service-principal"
  name   = "deco-prod-acct-datasci-spn"
  roles_on_resources = {
    // TODO: grant required accesses...
  }
}

// In this particular environment, erzen.kaja@databricks.com and had 
// to be manually imported, as `force` didn't work on the account level.
module "account" {
  source = "../../modules/databricks-account"
  providers = {
    databricks = databricks.account
  }
  azure_application_ids = {
    admins   = module.account_admin_spn.client_id
    data_eng = module.account_dataeng_spn.client_id
    data_sci = module.account_datasci_spn.client_id
  }
}

module "secrets-azure-account" {
  source      = "../../modules/github-secrets"
  environment = "azure-prod-acct"
  secrets = {
    "CLOUD_ENV" : "unity-catalog-account",
    "DATABRICKS_HOST" : module.defaults.azure_prod_account_console,
    "DATABRICKS_ACCOUNT_ID" : module.defaults.azure_prod_account_id,
    "ARM_TENANT_ID" : module.defaults.azure_tenant_id,
    "ARM_CLIENT_SECRET" : module.account_admin_spn.client_secret,
    "ARM_CLIENT_ID" : module.account_admin_spn.client_id,
  }
}
