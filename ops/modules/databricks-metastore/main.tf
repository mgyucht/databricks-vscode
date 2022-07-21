variable "workspace_id" {}
variable "storage_root" {}

resource "databricks_metastore" "this" {
  name          = "primary"
  storage_root  = var.storage_root
  owner         = "uc admins"
  force_destroy = true
}

resource "databricks_metastore_assignment" "this" {
  metastore_id = databricks_metastore.this.id
  workspace_id = var.workspace_id
}