output "metastore_id" {
  value = databricks_metastore.this.id
}

output "global_metastore_id" {
  value = databricks_metastore.this.global_metastore_id
}
