module "workspace" {
  source = "../../modules/aws-databricks-workspace"
  providers = {
    databricks = databricks.account
  }

  prefix                 = "deco-aws-nouc-prod"
  databricks_account_id  = module.defaults.aws_prod_databricks_account_id
  cross_account_role_arn = local.prod_crossaccount_arn
  security_group_ids     = module.fixtures.security_group_ids
  subnet_ids             = module.fixtures.private_subnets
  bucket_name            = module.fixtures.bucket_name
  region                 = module.defaults.aws_region
  vpc_id                 = module.fixtures.vpc_id

  // these require ENTERPRISE tier, which is rolled out via Jenkins job
  // https://jenkins.cloud.databricks.com/job/eng-cal-team/job/UpdateE2Account/
  managed_services_cmk_arn   = module.fixtures.managed_services_cmk_arn
  managed_services_cmk_alias = module.fixtures.managed_services_cmk_alias
  storage_cmk_arn            = module.fixtures.storage_cmk_arn
  storage_cmk_alias          = module.fixtures.storage_cmk_alias
}

provider "databricks" {
  alias = "workspace"
  host  = module.workspace.databricks_host
  token = module.workspace.databricks_token
}

module "databricks_fixtures" {
  providers = {
    databricks = databricks.workspace
  }
  source = "../../modules/databricks-fixtures"
  cloud  = "aws"
}

module "no_uc_workspace" {
  source      = "../../modules/github-secrets"
  environment = "aws-prod"
  secrets = merge(module.databricks_fixtures.test_env, {
    "CLOUD_ENV" : "aws",
    "DATABRICKS_HOST" : module.workspace.databricks_host,
    "DATABRICKS_TOKEN" : module.workspace.databricks_token
  })
}
