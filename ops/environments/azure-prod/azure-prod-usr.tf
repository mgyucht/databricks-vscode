//
// NOTE TO THE READER:
//
// Why does this not live in separate module? Terraform doesn't allow modules
// to define provider configuration and we need to authenticate as the new
// service principal to generate their PAT. Therefore it is impossible for
// this to live in a separate module (unfortunately).
//

// Provision non-admin SPN at the AAD level.
module "spn_nonadmin" {
  source = "../../modules/azure-service-principal"
  name   = "deco-prod-spn-nonadmin"
  roles_on_resources = {
    "Reader" : module.workspace.resource_group_id,
  }
}

// Provision non-admin SPN at the workspace level.
resource "databricks_service_principal" "spn_nonadmin" {
  depends_on = [module.spn]
  provider   = databricks.workspace

  application_id             = module.spn_nonadmin.client_id
  active                     = true
  allow_cluster_create       = false
  allow_instance_pool_create = false
}

// Authenticate as non-admin SPN with the workspace.
provider "databricks" {
  alias = "workspace_nonadmin"
  host  = module.workspace.workspace_url

  azure_client_id     = module.spn_nonadmin.client_id
  azure_client_secret = module.spn_nonadmin.client_secret
  azure_tenant_id     = module.defaults.azure_tenant_id
}

resource "time_rotating" "spn_nonadmin_rotation" {
  rotation_days = 30
}

// Provision a PAT for the non-admin SPN.
resource "databricks_token" "spn_nonadmin" {
  depends_on = [
    databricks_service_principal.spn_nonadmin,
    databricks_permissions.tokens,
  ]

  provider = databricks.workspace_nonadmin

  // Force rotation when "time_rotating.spn_nonadmin_rotation" changes.
  comment = "Rotating token (${time_rotating.spn_nonadmin_rotation.id})"

  // Rotation happens every 30 days so set token lifetime to 60 days for safety.
  lifetime_seconds = 60 * 60 * 24 * 60
}

// Allow the non-admin SPN the CAN_RESTART permission on test clusters.
resource "databricks_permissions" "cluster" {
  depends_on = [
    databricks_service_principal.spn_nonadmin,
    databricks_permissions.tokens,
  ]

  provider   = databricks.workspace
  for_each   = module.databricks_fixtures.cluster_ids
  cluster_id = each.key

  access_control {
    service_principal_name = databricks_service_principal.spn_nonadmin.application_id
    permission_level       = "CAN_RESTART"
  }
}

module "secrets_nonadmin" {
  source      = "../../modules/github-secrets"
  environment = "azure-prod-usr"
  secrets = merge(
    {
      "CLOUD_ENV" : "azure",
      "DATABRICKS_HOST" : module.workspace.workspace_url,
      "DATABRICKS_TOKEN" : databricks_token.spn_nonadmin.token_value,
    },
    {
      for k, v in module.databricks_fixtures.test_env : k => v
      if length(regexall("_CLUSTER_ID$", k)) > 0
    },
  )
}
