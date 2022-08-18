variable "name" {}
variable "azure_application_id" {
  default = ""
}

resource "databricks_group" "this" {
  display_name = var.name
}

resource "databricks_service_principal" "this" {
  display_name   = "eng-dev-ecosystem-spn-${var.name}"
  application_id = var.azure_application_id
  force = true
}

resource "databricks_group_member" "this" {
  group_id  = databricks_group.this.id
  member_id = databricks_service_principal.this.id
}

output "result" {
  value = {
    group_id             = databricks_group.this.id
    name                 = databricks_group.this.display_name
    application_id       = databricks_service_principal.this.application_id
    service_principal_id = databricks_service_principal.this.id
  }
}
