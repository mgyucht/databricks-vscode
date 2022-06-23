variable "role" {
  type    = string
  default = "Contributor"
}

variable "principal_id" {
  type = string
}

data "azurerm_subscription" "this" {
}

# Note: these roles can only be assigned if the current user has the "Owner" role.
# You'll see an authoritzation error if you have the "Contributor" role.
resource "azurerm_role_assignment" "contributor" {
  scope                = data.azurerm_subscription.this.id
  role_definition_name = var.role
  principal_id         = var.principal_id
}
