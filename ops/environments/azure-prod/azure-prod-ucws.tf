module "workspace_ucws" {
  source      = "../../modules/azure-databricks-workspace"
  location    = "eastus2"
  environment = "prod"
  suffix      = "-ucws"
}

module "spn_ucws" {
  source = "../../modules/azure-service-principal"
  name   = "deco-prod-spn-ucws"
  roles_on_resources = {
    "Contributor" : module.workspace_ucws.resource_group_id,
  }
}

provider "databricks" {
  alias = "workspace_ucws"
  host  = module.workspace_ucws.workspace_url

  auth_type                   = "azure-client-secret"
  azure_client_id             = module.spn_ucws.client_id
  azure_client_secret         = module.spn_ucws.client_secret
  azure_tenant_id             = module.defaults.azure_tenant_id
  azure_workspace_resource_id = module.workspace_ucws.resource_id
}

module "databricks_fixtures_ucws" {
  depends_on = [
    module.spn_ucws,
  ]
  providers = {
    databricks = databricks.workspace_ucws
  }
  source = "../../modules/databricks-fixtures"
  cloud  = "azure"
}

provider "databricks" {
  alias = "workspace_ucws_account_admin"
  host  = module.workspace_ucws.workspace_url

  auth_type                   = "azure-client-secret"
  azure_client_id             = module.account_admin_spn.client_id
  azure_client_secret         = module.account_admin_spn.client_secret
  azure_tenant_id             = module.defaults.azure_tenant_id
  azure_workspace_resource_id = module.workspace_ucws.resource_id
}

module "metastore" {
  source = "../../modules/databricks-azure-metastore"
  providers = {
    databricks = databricks.workspace_ucws_account_admin
  }

  name = "deco-prod-azure-eastus2"

  storage_account_name           = module.fixtures.unity_storage_account_name
  storage_container_name         = module.fixtures.unity_storage_container_name
  databricks_access_connector_id = module.fixtures.unity_access_connector_id

  owner_group    = module.account.admins.name
  data_eng_group = module.account.data_eng.name
  data_sci_group = module.account.data_sci.name

  workspace_ids = [module.workspace_ucws.workspace_id]

  depends_on = [
    module.workspace_ucws,
    module.account_admin_spn,
  ]
}

// Provision non-admin SPN at the AAD level.
module "spn_ucws_nonadmin" {
  source = "../../modules/azure-service-principal"
  name   = "deco-prod-spn-ucws-nonadmin"
  roles_on_resources = {
    "Reader" : module.workspace_ucws.resource_group_id,
  }
}

// Provision non-admin SPN at the workspace level.
resource "databricks_service_principal" "spn_ucws_nonadmin" {
  depends_on = [module.spn_ucws]
  provider   = databricks.workspace_ucws

  application_id             = module.spn_ucws_nonadmin.client_id
  active                     = true
  allow_cluster_create       = false
  allow_instance_pool_create = false
}

// Allow the non-admin SPN to create a PAT.
resource "databricks_permissions" "tokens_ucws" {
  depends_on = [module.spn_ucws]
  provider   = databricks.workspace_ucws

  authorization = "tokens"

  access_control {
    service_principal_name = databricks_service_principal.spn_ucws_nonadmin.application_id
    permission_level       = "CAN_USE"
  }
}

// Authenticate as non-admin SPN with the workspace.
provider "databricks" {
  alias = "workspace_ucws_nonadmin"

  auth_type                   = "azure-client-secret"
  azure_client_id             = module.spn_ucws_nonadmin.client_id
  azure_client_secret         = module.spn_ucws_nonadmin.client_secret
  azure_tenant_id             = module.defaults.azure_tenant_id
  azure_workspace_resource_id = module.workspace_ucws.resource_id
}

resource "time_rotating" "spn_ucws_nonadmin_rotation" {
  rotation_days = 30
}

// Provision a PAT for the non-admin SPN.
resource "databricks_token" "spn_ucws_nonadmin" {
  depends_on = [
    databricks_service_principal.spn_ucws_nonadmin,
    databricks_permissions.tokens_ucws,
  ]

  provider = databricks.workspace_ucws_nonadmin

  // Force rotation when "time_rotating.spn_ucws_nonadmin_rotation" changes.
  comment = "Rotating token (${time_rotating.spn_ucws_nonadmin_rotation.id})"

  // Rotation happens every 30 days so set token lifetime to 60 days for safety.
  lifetime_seconds = 60 * 60 * 24 * 60
}

// Allow the non-admin SPN the CAN_RESTART permission on test clusters.
resource "databricks_permissions" "ucws_cluster" {
  depends_on = [
    databricks_service_principal.spn_ucws_nonadmin,
    databricks_permissions.tokens,
  ]

  provider   = databricks.workspace_ucws
  for_each   = module.databricks_fixtures_ucws.cluster_ids
  cluster_id = each.value

  access_control {
    service_principal_name = databricks_service_principal.spn_ucws_nonadmin.application_id
    permission_level       = "CAN_RESTART"
  }
}

// Allow the non-admin SPN the CAN_USE permission on test warehouses.
resource "databricks_permissions" "ucws_warehouse" {
  depends_on = [module.spn_ucws]
  provider   = databricks.workspace_ucws

  for_each        = module.databricks_fixtures_ucws.warehouse_ids
  sql_endpoint_id = each.value

  access_control {
    service_principal_name = databricks_service_principal.spn_ucws_nonadmin.application_id
    permission_level       = "CAN_USE"
  }
}

module "secrets_ucws" {
  source      = "../../modules/github-secrets"
  environment = "azure-prod-ucws"
  secrets = merge(
    {
      "CLOUD_ENV" : "azure",
      "DATABRICKS_HOST" : module.workspace_ucws.workspace_url,
      "DATABRICKS_AZURE_RESOURCE_ID" : module.workspace_ucws.resource_id,
      "ARM_TENANT_ID" : module.defaults.azure_tenant_id,
      "ARM_CLIENT_SECRET" : module.spn_ucws.client_secret,
      "ARM_CLIENT_ID" : module.spn_ucws.client_id,
    },
    {
      for k, v in module.databricks_fixtures_ucws.test_env : k => v
      if length(regexall("_CLUSTER_ID$", k)) > 0 || length(regexall("_WAREHOUSE_", k)) > 0
    },
  )
}
