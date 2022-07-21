variable "environment" {
  type = string
  validation {
    condition     = regex("[0-9a-z-]*", var.environment) == var.environment
    error_message = "Only valid environment variable names."
  }
}

// Sensitive values, or values derived from sensitive values, cannot be used as for_each
// arguments. If used, the sensitive value could be exposed as a resource instance key.
variable "secrets" {
  description = "environment variable name to secret map"
  type        = map(string)

  validation {
    condition = toset([for k, _ in var.secrets :
    regex("[0-9A-Z_]*", k)]) == toset([for k, _ in var.secrets : k])
    error_message = "Only valid environment variable names as keys."
  }
}

data "azurerm_resource_group" "this" {
  name = module.defaults.resource_group
}

data "azuread_users" "admins" {
  user_principal_names = [for u in module.defaults.admins :
  "${replace(u, "@", "_")}#EXT#@dbtestcustomer.onmicrosoft.com"]
}

resource "azurerm_key_vault" "this" {
  // historically, this is a hack, because azure key vault names are 32 char maxlen
  name = "deco-gh-${var.environment}"

  resource_group_name = data.azurerm_resource_group.this.name
  location            = data.azurerm_resource_group.this.location
  tags                = data.azurerm_resource_group.this.tags
  tenant_id           = module.defaults.azure_tenant_id

  soft_delete_retention_days = 7
  purge_protection_enabled   = false
  sku_name                   = "standard"

  dynamic "access_policy" {
    // we may want to add the SPN client_id from current caller identity
    // as this thing has to be settable on github actions in automation
    for_each = toset(data.azuread_users.admins.object_ids)
    content {
      object_id          = access_policy.value
      tenant_id          = module.defaults.azure_tenant_id
      secret_permissions = ["Set", "Get", "List", "Delete", 
        "Purge", "Recover", "Restore"]
    }
  }
}

resource "azurerm_key_vault_secret" "this" {
  for_each     = var.secrets
  name         = replace(each.key, "_", "-")
  value        = each.value
  key_vault_id = azurerm_key_vault.this.id
  content_type = "GITHUB_ACTIONS_SECRET"
  tags         = {}
  timeouts {
    create = "1m"
    update = "1m"
    read = "1m"
    delete = "2m"
  }
}

output "vault_id" {
  value = azurerm_key_vault.this.id
}