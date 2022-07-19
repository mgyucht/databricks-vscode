#
# Define workspace role that can be used by production workspaces.
#

module "workspace_prod_role" {
  source = "./modules/workspace"

  env_name                  = "prod"
  databricks_account_id     = local.databricks_prod_account_id
  aws_databricks_account_id = local.aws_prod_account_id
}
