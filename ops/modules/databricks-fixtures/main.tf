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

// use this mapping and only modify work.tf if more properties required for
// any cluster or warehouse
locals {
  // cluster, instance pool, and warehouse node autotermination timeout
  autotermination_minutes = 60

  // use this mapping to add/modify clusters,
  // and NOT the databricks_cluster resource directly
  test_clusters = {
    DEFAULT : {
      custom_tags : {
        Product : "Any"
      },
    },
    GO_SDK : {
      custom_tags : {
        Product : "GoSDK"
      },
    },
    JS_SDK : {
      custom_tags : {
        Product : "JsSDK"
      },
    },
    VSCODE : {
      custom_tags : {
        Product : "VScodeExtension"
      },
    },
    BRICKS : {
      custom_tags : {
        Product : "BricksCLI"
      },
    },
  }

  // every test warehouse must have `custom_tags` setting
  test_warehouses = {
    DEFAULT : {
      custom_tags : merge({}, var.cloud != "gcp" ? module.defaults.tags : {}),
    },
    PECO : {
      custom_tags : merge({}, var.cloud != "gcp" ? module.defaults.tags : {}),
    },
  }
}

output "test_env" {
  value = merge(
    { "TEST_INSTANCE_POOL_ID" : databricks_instance_pool.this.id },
    local.out_clusters,
    local.out_warehouses,
  )
}

resource "databricks_token" "pat" {
  comment          = "Test token"
  lifetime_seconds = 60 * 60 * 24 * 30
}

output "databricks_token" {
  value = databricks_token.pat.token_value
}

resource "databricks_workspace_conf" "this" {
  custom_config = {
    "maxTokenLifetimeDays" : "0"
  }
}
