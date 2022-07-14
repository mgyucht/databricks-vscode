variable "name" {
  type = string
}

variable "roles_on_resources" {
  type        = map(string)
  description = "role name is a key and resource id is a value"
}

module "defaults" {
  source = "../defaults"
}

data "azuread_users" "admins" {
  user_principal_names = [for u in module.defaults.admins :
  "${replace(u, "@", "_")}#EXT#@dbtestcustomer.onmicrosoft.com"]
}

resource "azuread_application" "this" {
  display_name = var.name
  owners       = data.azuread_users.admins.object_ids
}

resource "azuread_service_principal" "this" {
  application_id = azuread_application.this.application_id
  owners         = data.azuread_users.admins.object_ids
}

resource "time_rotating" "month" {
  rotation_days = 30
}

resource "azuread_service_principal_password" "this" {
  service_principal_id = azuread_service_principal.this.object_id
  rotate_when_changed = {
    rotation = time_rotating.month.id
  }
}

resource "azurerm_role_assignment" "this" {
  for_each             = var.roles_on_resources
  role_definition_name = each.key
  scope                = each.value
  principal_id         = azuread_service_principal.this.object_id
}

output "client_id" {
  description = "value for ARM_CLIENT_ID environment variable"
  value       = azuread_application.this.application_id
}

output "client_secret" {
  description = "value for ARM_CLIENT_SECRET environment variable"
  value       = azuread_service_principal_password.this.value
  sensitive   = true
}