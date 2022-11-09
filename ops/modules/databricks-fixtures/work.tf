variable "cloud" {
  type = string
  validation {
    condition     = regex("^aws|azure|gcp$", var.cloud) == var.cloud
    error_message = "One of `aws`, `azure`, or `gcp`."
  }
}

module "defaults" {
  source = "../defaults"
}

data "databricks_node_type" "smallest" {
  local_disk = true
}

data "databricks_spark_version" "latest" {
}

resource "databricks_instance_pool" "this" {
  min_idle_instances                    = 0
  max_capacity                          = 50
  instance_pool_name                    = "Integration Pool: Smallest Nodes"
  idle_instance_autotermination_minutes = local.autotermination_minutes
  node_type_id                          = data.databricks_node_type.smallest.id
  preloaded_spark_versions              = [data.databricks_spark_version.latest.id]

  // all instances have Owner as DECO email, and will appear in DECO AWS budgets
  custom_tags = var.cloud == "aws" ? module.defaults.tags : {}
}

resource "databricks_cluster" "this" {
  for_each                = local.test_clusters
  cluster_name            = "${each.key} Test Cluster"
  spark_version           = data.databricks_spark_version.latest.id
  instance_pool_id        = databricks_instance_pool.this.id
  autotermination_minutes = local.autotermination_minutes
  is_pinned               = true
  spark_conf = {
    "spark.databricks.cluster.profile" : "singleNode"
    "spark.master" : "local[*]"
  }
  custom_tags = merge(each.value.custom_tags, {
    "ResourceClass" = "SingleNode"
  })
}

locals {
  out_clusters = {
    for k, v in databricks_cluster.this :
    "TEST_${k}_CLUSTER_ID" => v.id
  }
}

resource "databricks_sql_endpoint" "this" {
  for_each             = local.test_warehouses
  name                 = "${each.key} Test Warehouse"
  auto_stop_mins       = local.autotermination_minutes
  spot_instance_policy = "COST_OPTIMIZED"
  cluster_size         = "Small"
  max_num_clusters     = 1
  tags {
    dynamic "custom_tags" {
      for_each = merge({
        "Source" : "databricks/eng-dev-ecosystem"
      }, each.value.custom_tags)
      content {
        key   = custom_tags.key
        value = var.cloud == "gcp" ? replace(custom_tags.value, "[^\\w_]+", "_") : custom_tags.value
      }
    }
  }
}

locals {
  out_warehouses = { for v in flatten([for k, v in databricks_sql_endpoint.this : [
    { key : "TEST_${k}_WAREHOUSE_ID", value : v.id },
    { key : "TEST_${k}_WAREHOUSE_DATASOURCE_ID", value : v.data_source_id },
    { key : "TEST_${k}_WAREHOUSE_JDBC_URL", value : v.jdbc_url },
  ]]) : v.key => v.value }
}
