//
// NOTE TO THE READER:
//
// Why does this not live in separate module? Terraform doesn't allow modules
// to define provider configuration and we need to authenticate as the new
// service principal to generate their PAT. Therefore it is impossible for
// this to live in a separate module (unfortunately).
//

// TODO: Serge to do a state rewrite to rename this to ucws
module "workspace_usr" {
  source      = "../../modules/azure-databricks-workspace"
  location    = "eastus2"
  environment = "prod"
  suffix      = "-usr"
}

module "spn_usr" {
  source = "../../modules/azure-service-principal"
  name   = "deco-prod-spn-usr"
  roles_on_resources = {
    "Contributor" : module.workspace_usr.resource_group_id,
  }
}

provider "databricks" {
  alias = "workspace_usr"
  host  = module.workspace_usr.workspace_url

  azure_client_id             = module.spn_usr.client_id
  azure_client_secret         = module.spn_usr.client_secret
  azure_tenant_id             = module.defaults.azure_tenant_id
  azure_workspace_resource_id = module.workspace_usr.resource_id
}

module "databricks_fixtures_usr" {
  depends_on = [
    module.spn_usr,
  ]
  providers = {
    databricks = databricks.workspace_usr
  }
  source = "../../modules/databricks-fixtures"
  cloud  = "azure"
}

// Provision non-admin SPN at the AAD level.
module "spn_usr_nonadmin" {
  source = "../../modules/azure-service-principal"
  name   = "deco-prod-spn-usr-nonadmin"
  roles_on_resources = {
    "Reader" : module.workspace_usr.resource_group_id,
  }
}

// Provision non-admin SPN at the workspace level.
resource "databricks_service_principal" "spn_usr_nonadmin" {
  depends_on = [module.spn_usr]
  provider   = databricks.workspace_usr

  application_id             = module.spn_usr_nonadmin.client_id
  active                     = true
  allow_cluster_create       = false
  allow_instance_pool_create = false
}

// Allow the non-admin SPN to create a PAT.
resource "databricks_permissions" "tokens" {
  depends_on = [module.spn_usr]
  provider   = databricks.workspace_usr

  authorization = "tokens"

  access_control {
    service_principal_name = databricks_service_principal.spn_usr_nonadmin.application_id
    permission_level       = "CAN_USE"
  }
}

// Authenticate as non-admin SPN with the workspace.
provider "databricks" {
  alias = "workspace_usr_nonadmin"

  azure_client_id             = module.spn_usr_nonadmin.client_id
  azure_client_secret         = module.spn_usr_nonadmin.client_secret
  azure_tenant_id             = module.defaults.azure_tenant_id
  azure_workspace_resource_id = module.workspace_usr.resource_id
}

resource "time_rotating" "spn_usr_nonadmin_rotation" {
  rotation_days = 30
}

// Provision a PAT for the non-admin SPN.
resource "databricks_token" "spn_usr_nonadmin" {
  depends_on = [
    databricks_service_principal.spn_usr_nonadmin,
    databricks_permissions.tokens,
  ]

  provider = databricks.workspace_usr_nonadmin

  // Force rotation when "time_rotating.spn_nonadmin_rotation" changes.
  comment = "Rotating token (${time_rotating.spn_usr_nonadmin_rotation.id})"

  // Rotation happens every 30 days so set token lifetime to 60 days for safety.
  lifetime_seconds = 60 * 60 * 24 * 60
}

// Allow the non-admin SPN the CAN_RESTART permission on test clusters.
resource "databricks_permissions" "cluster" {
  depends_on = [
    databricks_service_principal.spn_usr_nonadmin,
    databricks_permissions.tokens,
  ]

  provider   = databricks.workspace_usr
  for_each   = module.databricks_fixtures_usr.cluster_ids
  cluster_id = each.value

  access_control {
    service_principal_name = databricks_service_principal.spn_usr_nonadmin.application_id
    permission_level       = "CAN_RESTART"
  }
}

resource "databricks_directory" "tmp_folder" {
  depends_on = [module.spn_usr]
  provider   = databricks.workspace_usr
  path       = "/tmp/js-sdk-jobs-tests"
}

resource "databricks_permissions" "tmp_folder_permissions" {
  depends_on = [module.spn_usr]
  provider   = databricks.workspace_usr

  directory_path = databricks_directory.tmp_folder.path

  access_control {
    service_principal_name = databricks_service_principal.spn_usr_nonadmin.application_id
    permission_level       = "CAN_MANAGE"
  }
}

resource "databricks_directory" "js_sdk_tests_folder" {
  depends_on = [module.spn_usr]
  provider   = databricks.workspace_usr
  path       = "/Repos/js-sdk-tests"
}

resource "databricks_permissions" "js_sdk_tests_folder_permissions" {
  depends_on = [module.spn_usr]
  provider   = databricks.workspace_usr

  directory_path = databricks_directory.js_sdk_tests_folder.path

  access_control {
    service_principal_name = databricks_service_principal.spn_usr_nonadmin.application_id
    permission_level       = "CAN_MANAGE"
  }
}

module "secrets_nonadmin" {
  source      = "../../modules/github-secrets"
  environment = "azure-prod-usr"
  secrets = merge(
    {
      "CLOUD_ENV" : "azure",
      "DATABRICKS_HOST" : module.workspace_usr.workspace_url,
      "DATABRICKS_TOKEN" : databricks_token.spn_usr_nonadmin.token_value,
    },
    {
      for k, v in module.databricks_fixtures_usr.test_env : k => v
      if length(regexall("_CLUSTER_ID$", k)) > 0
    },
  )
}
