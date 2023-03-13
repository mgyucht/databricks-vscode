variable "name" {}

variable "bucket" {}
variable "metastore_data_access_arn" {}

variable "owner_group" {}
variable "data_eng_group" {}
variable "data_sci_group" {}

variable "workspace_ids" {
  type = list(string)
}

resource "databricks_metastore" "this" {
  name                = var.name
  storage_root        = "s3://${var.bucket}/metastore"
  owner               = var.owner_group
  force_destroy       = true
  delta_sharing_scope = "INTERNAL_AND_EXTERNAL"

  delta_sharing_recipient_token_lifetime_in_seconds = "300"
}

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
