variable "name" {}

variable "storage_account_name" {}
variable "storage_container_name" {}
variable "databricks_access_connector_id" {}

variable "owner_group" {}
variable "data_eng_group" {}
variable "data_sci_group" {}

variable "workspace_ids" {
  type = list(string)
}

resource "databricks_metastore" "this" {
  name = var.name
  storage_root = format(
    "abfss://%s@%s.dfs.core.windows.net/",
    var.storage_container_name,
    var.storage_account_name,
  )

  owner               = var.owner_group
  force_destroy       = true
  delta_sharing_scope = "INTERNAL_AND_EXTERNAL"

  delta_sharing_recipient_token_lifetime_in_seconds = "300"
}

resource "databricks_metastore_data_access" "this" {
  metastore_id = databricks_metastore.this.id
  name         = "${var.name}-data-access"

  azure_managed_identity {
    access_connector_id = var.databricks_access_connector_id
  }

  is_default = true
}

resource "databricks_metastore_assignment" "this" {
  for_each             = toset(var.workspace_ids)
  workspace_id         = each.key
  metastore_id         = databricks_metastore.this.id
  default_catalog_name = "hive_metastore"
}

module "fixtures" {
  source = "../databricks-common-metastore"

  metastore_id   = databricks_metastore.this.id
  data_eng_group = var.data_eng_group
  data_sci_group = var.data_sci_group

  depends_on = [databricks_metastore_assignment.this]
}
