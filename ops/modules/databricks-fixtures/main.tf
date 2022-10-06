// For the time we decide to pull this module down, we should first 
// perform manual state removals for admin memberships:
// terraform state rm 'module.users.databricks_group_member.admin["serge.smertin@databricks.com"]'
// terraform state rm 'module.users.databricks_user.admin["serge.smertin@databricks.com"]'
// and only then add this new module, otherwise we'll end up in
// the ethernal conflict of user destruction and risk of locking 
// oneself out of the workspace.
module "users" {
  providers = {
    databricks = databricks
  }
  source = "../databricks-decoadmins"
}

module "clusters" {
  providers = {
    databricks = databricks
  }
  source = "../databricks-clusters"
}

output "test_env" {
  value = {
    "TEST_DEFAULT_CLUSTER_ID" : module.clusters.default_cluster_id,
    "TEST_BRICKS_CLUSTER_ID" : module.clusters.bricks_cluster_id,
    "TEST_VSCODE_CLUSTER_ID" : module.clusters.vscode_cluster_id,
    "TEST_DATABRICKS_SDK_GO_CLUSTER_ID" : module.clusters.databricks_sdk_go_cluster_id,
  }
}

resource "databricks_token" "pat" {
  comment = "Test token"
}

output "databricks_token" {
  value = databricks_token.pat.token_value
}
