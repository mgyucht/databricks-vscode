module "workspace_prod_role" {
  source = "../../modules/aws-iam-crossaccount"

  env_name                  = "prod"
  databricks_account_id     = module.defaults.aws_prod_databricks_account_id
  aws_databricks_account_id = module.defaults.aws_prod_account_id
}

module "workspace_staging_role" {
  source = "../../modules/aws-iam-crossaccount"

  env_name                  = "staging"
  databricks_account_id     = module.defaults.aws_staging_databricks_account_id
  aws_databricks_account_id = module.defaults.aws_staging_account_id
}

module "uc_prod_role" {
  source = "../../modules/aws-iam-unity-catalog"

  env_name                     = "prod"
  crossaccount_role_identifier = "arn:aws:iam::414351767826:role/unity-catalog-prod-UCMasterRole-14S5ZJVKOTYTL"
  databricks_account_id        = module.defaults.aws_prod_databricks_account_id
}

module "uc_staging_role" {
  source = "../../modules/aws-iam-unity-catalog"

  env_name                     = "staging"
  crossaccount_role_identifier = "arn:aws:iam::548125073166:role/unity-catalog-staging-UCMasterRole-92NM06GMQ56M"
  databricks_account_id        = module.defaults.aws_staging_databricks_account_id
}

resource "local_file" "iam_roles_json" {
  filename = "${path.module}/iam-roles.json"
  content = jsonencode({
    "prod": {
      "cross-account": module.workspace_prod_role.arn,
      "unity-catalog": module.uc_prod_role.arn,
    },
    "staging": {
      "cross-account": module.workspace_staging_role.arn,
      "unity-catalog": module.uc_staging_role.arn,
    }
  })
}