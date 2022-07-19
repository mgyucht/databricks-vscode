#
# Define workspace role that can be used by staging workspaces.
#

module "workspace_staging_role" {
  source = "./modules/workspace"

  env_name                  = "staging"
  databricks_account_id     = local.databricks_staging_account_id
  aws_databricks_account_id = local.aws_staging_account_id
}
