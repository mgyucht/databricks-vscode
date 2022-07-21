module "defaults" {
  source = "../defaults"
}

// this is account-level group for Unity Catalog
resource "databricks_group" "uc_admins" {
  display_name = "deco-admins"
}

resource "databricks_user" "uc_admin" {
  for_each  = toset(module.defaults.admins)
  user_name = each.key
  force     = true
}

resource "databricks_group_member" "uc_admin" {
  for_each  = toset(module.defaults.admins)
  group_id  = databricks_group.uc_admins.id
  member_id = databricks_user.uc_admin[each.key].id
}

resource "databricks_service_principal" "admin" {
  display_name = "sp-uc-admin"
}

resource "databricks_service_principal_role" "acct_admin" {
  service_principal_id = databricks_service_principal.this.id
  role                 = ""
}

output "admin_sp_application_id" {
  value = databricks_service_principal.uc_admin.application_id
}

resource "databricks_group_member" "sp_uc_admin" {
  group_id  = databricks_group.uc_admins.id
  member_id = databricks_service_principal.admin.id
}

resource "databricks_service_principal" "normal" {
  display_name = "sp-normal"
}
