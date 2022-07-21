module "defaults" {
  source = "../defaults"
}

data "databricks_group" "admins" {
  display_name = "admins"
}

resource "databricks_user" "admin" {
  for_each  = toset(module.defaults.admins)
  user_name = each.key
  force     = true
}

resource "databricks_group_member" "admin" {
  for_each  = toset(module.defaults.admins)
  group_id  = data.databricks_group.admins.id
  member_id = databricks_user.admin[each.key].id
}
