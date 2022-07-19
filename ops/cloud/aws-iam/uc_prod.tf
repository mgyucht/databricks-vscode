#
# Define Unity Catalog role that can be used by production workspaces.
#

module "uc_prod_role" {
  source = "./modules/uc"

  env_name                     = "prod"
  crossaccount_role_identifier = "arn:aws:iam::414351767826:role/unity-catalog-prod-UCMasterRole-14S5ZJVKOTYTL"
  databricks_account_id        = local.databricks_prod_account_id
}
