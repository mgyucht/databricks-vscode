#
# Define Unity Catalog role that can be used by staging workspaces.
#

module "uc_staging_role" {
  source = "./modules/uc"

  env_name                     = "staging"
  crossaccount_role_identifier = "arn:aws:iam::548125073166:role/unity-catalog-staging-UCMasterRole-92NM06GMQ56M"
  databricks_account_id        = local.databricks_staging_account_id
}
