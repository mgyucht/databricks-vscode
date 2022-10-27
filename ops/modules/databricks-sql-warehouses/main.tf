resource "databricks_sql_endpoint" "bix" {
  name             = "BI-X integration testing"
  cluster_size     = "Small"
  max_num_clusters = 1
  auto_stop_mins   = 10
}

output "test_env" {
  value = {
    "TEST_BIX_SQL_WAREHOUSE_ID" : databricks_sql_endpoint.bix.id,
    "TEST_BIX_SQL_WAREHOUSE_JDBC_URL" : databricks_sql_endpoint.bix.jdbc_url,
    "TEST_BIX_SQL_WAREHOUSE_HTTP_PATH" : split("=", split(";", databricks_sql_endpoint.bix.jdbc_url)[4])[1],
  }
}
