data "databricks_node_type" "smallest" {
  local_disk = true
}

data "databricks_spark_version" "latest_lts" {
  long_term_support = true
}

resource "databricks_cluster" "default_test_cluster" {
  cluster_name            = "Default Test Cluster"
  spark_version           = data.databricks_spark_version.latest_lts.id
  node_type_id            = data.databricks_node_type.smallest.id
  autotermination_minutes = 60
  autoscale {
    min_workers = 1
    max_workers = 50
  }
}

resource "databricks_cluster" "databricks_sdk_go_test_cluster" {
  cluster_name            = "databricks-sdk-go Test Cluster"
  spark_version           = data.databricks_spark_version.latest_lts.id
  node_type_id            = data.databricks_node_type.smallest.id
  autotermination_minutes = 60
  autoscale {
    min_workers = 1
    max_workers = 50
  }
}

resource "databricks_cluster" "vscode_test_cluster" {
  cluster_name            = "vscode Test Cluster"
  spark_version           = data.databricks_spark_version.latest_lts.id
  node_type_id            = data.databricks_node_type.smallest.id
  autotermination_minutes = 60
  autoscale {
    min_workers = 1
    max_workers = 50
  }
}

resource "databricks_cluster" "bricks_test_cluster" {
  cluster_name            = "bricks Test Cluster"
  spark_version           = data.databricks_spark_version.latest_lts.id
  node_type_id            = data.databricks_node_type.smallest.id
  autotermination_minutes = 60
  autoscale {
    min_workers = 1
    max_workers = 50
  }
}

output "default_cluster_id" {
  value = databricks_cluster.default_test_cluster.id
}

output "databricks_sdk_go_cluster_id" {
  value = databricks_cluster.databricks_sdk_go_test_cluster.id
}

output "vscode_cluster_id" {
  value = databricks_cluster.vscode_test_cluster.id
}

output "bricks_cluster_id" {
  value = databricks_cluster.bricks_test_cluster.id
}
