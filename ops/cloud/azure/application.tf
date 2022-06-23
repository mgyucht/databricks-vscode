data "azuread_users" "deco_admins" {
  # Refer to the "Users" dashboard on the Azure portal to find these principal names.
  user_principal_names = [
    "pieter.noordhuis_databricks.com#EXT#@dbtestcustomer.onmicrosoft.com",
  ]
}

resource "azuread_application" "admin" {
  display_name = "Developer Ecosystem (Admin)"

  owners = data.azuread_users.deco_admins.object_ids
}

resource "azuread_service_principal" "admin" {
  application_id = azuread_application.admin.application_id
  owners         = data.azuread_users.deco_admins.object_ids
}

resource "azuread_service_principal_password" "admin" {
  service_principal_id = azuread_service_principal.admin.object_id
}

# Note: these roles can only be assigned if the current user has the "Owner" role.
# You'll see an authoritzation error if you have the "Contributor" role.
#
#module "admin_production" {
#  source = "./modules/assign_role_to_subscription"
#
#  providers = {
#    azurerm = azurerm.production
#  }
#
#  role         = "Contributor"
#  principal_id = azuread_service_principal.admin.id
#}
#
#module "admin_staging" {
#  source = "./modules/assign_role_to_subscription"
#
#  providers = {
#    azurerm = azurerm.staging
#  }
#
#  role         = "Contributor"
#  principal_id = azuread_service_principal.admin.id
#}
#
#module "admin_development" {
#  source = "./modules/assign_role_to_subscription"
#
#  providers = {
#    azurerm = azurerm.development
#  }
#
#  role         = "Contributor"
#  principal_id = azuread_service_principal.admin.id
#}
#
