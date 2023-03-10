variable "workspace_ids" {
  type = list(string)
}
variable "name" {}
variable "bucket" {}
variable "owner_group" {}
variable "data_eng_group" {}
variable "data_sci_group" {}
variable "metastore_data_access_arn" {}

resource "databricks_metastore" "this" {
  name                = var.name
  storage_root        = "s3://${var.bucket}/metastore"
  owner               = var.owner_group
  force_destroy       = true
  delta_sharing_scope = "INTERNAL_AND_EXTERNAL"

  delta_sharing_recipient_token_lifetime_in_seconds = "300"
}

output "metastore_id" {
  value = databricks_metastore.this.id
}

output "global_metastore_id" {
  value = databricks_metastore.this.global_metastore_id
}

// Assign to all workspaces in the account
// https://github.com/databricks/terraform-provider-databricks/issues/1485
resource "databricks_metastore_assignment" "this" {
  for_each             = toset(var.workspace_ids)
  workspace_id         = each.key
  metastore_id         = databricks_metastore.this.id
  default_catalog_name = "hive_metastore"
}

resource "databricks_metastore_data_access" "this" {
  metastore_id = databricks_metastore.this.id
  name         = "${var.name}-data-access"
  aws_iam_role {
    role_arn = var.metastore_data_access_arn
  }
  is_default = true
}

module "fixtures" {
  source = "../databricks-common-metastore"

  metastore_id   = databricks_metastore.this.id
  data_eng_group = var.data_eng_group
  data_sci_group = var.data_sci_group

  depends_on = [databricks_metastore_assignment.this]
}
