module "defaults" {
  source = "../defaults"
}

// Grant admins permission to create schemas in the main catalog.
resource "databricks_grants" "main" {
  catalog = "main"

  dynamic "grant" {
    for_each = module.defaults.admins

    content {
      principal = grant.value
      privileges = [
        "CREATE_SCHEMA",
        "USE_CATALOG",
      ]
    }
  }
}
