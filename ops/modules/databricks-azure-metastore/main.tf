variable "workspace_ids" {
  type = list(string)
}
variable "name" {}

variable "storage_account_name" {}
variable "storage_container_name" {}

variable "owner_group" {}
variable "data_eng_group" {}
variable "data_sci_group" {}

//  _______ ____  _____   ____
// |__   __/ __ \|  __ \ / __ \
//    | | | |  | | |  | | |  | |
//    | | | |  | | |  | | |  | |
//    | | | |__| | |__| | |__| |
//    |_|  \____/|_____/ \____/
//

// As of 2023-03-10, @pietern saw the following error:
//
// > This account with id 5a8ac58d-9557-497a-8832-90bd35e641bf has reached the limit for metastores in region eastus2
//
// Pinged the team on Slack: https://databricks.slack.com/archives/C029UBNLMGX/p1678454120415499

# resource "databricks_metastore" "this" {
#   name = var.name
#   storage_root = format(
#     "abfss://%s@%s.dfs.core.windows.net/",
#     var.storage_container_name,
#     var.storage_account_name,
#   )

#   owner               = var.owner_group
#   force_destroy       = true
#   delta_sharing_scope = "INTERNAL_AND_EXTERNAL"

#   delta_sharing_recipient_token_lifetime_in_seconds = "300"
# }

# output "metastore_id" {
#   value = databricks_metastore.this.id
# }

# output "global_metastore_id" {
#   value = databricks_metastore.this.global_metastore_id
# }

# // Assign to all workspaces in the account
# // https://github.com/databricks/terraform-provider-databricks/issues/1485
# resource "databricks_metastore_assignment" "this" {
#   for_each             = toset(var.workspace_ids)
#   workspace_id         = each.key
#   metastore_id         = databricks_metastore.this.id
#   default_catalog_name = "hive_metastore"
# }

# resource "databricks_metastore_data_access" "this" {
#   metastore_id = databricks_metastore.this.id
#   name         = "${var.name}-data-access"
#   aws_iam_role {
#     role_arn = var.metastore_data_access_arn
#   }
#   is_default = true
# }

# module "fixtures" {
#   source = "../databricks-common-metastore"

#   metastore_id   = databricks_metastore.this.id
#   data_eng_group = var.data_eng_group
#   data_sci_group = var.data_sci_group

#   depends_on = [databricks_metastore_assignment.this]
# }
