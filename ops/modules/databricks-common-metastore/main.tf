variable "metastore_id" {}
variable "data_eng_group" {}
variable "data_sci_group" {}

resource "databricks_catalog" "sandbox" {
  metastore_id = var.metastore_id
  name         = "sandbox"
  comment      = "this catalog is managed by terraform"
  properties = {
    purpose = "testing"
  }
}

resource "databricks_grants" "sandbox" {
  catalog = databricks_catalog.sandbox.name

  grant {
    principal = var.data_eng_group
    privileges = [
      "CREATE_SCHEMA",
      "USE_CATALOG",
    ]
  }

  grant {
    principal = var.data_sci_group
    privileges = [
      "USE_CATALOG",
    ]
  }
}

resource "databricks_schema" "things" {
  catalog_name = databricks_catalog.sandbox.id
  name         = "things"
  comment      = "this database is managed by terraform"
  properties = {
    kind = "various"
  }
}

resource "databricks_grants" "things" {
  schema = databricks_schema.things.id

  grant {
    principal = var.data_sci_group
    privileges = [
      "USE_SCHEMA",
    ]
  }
}
