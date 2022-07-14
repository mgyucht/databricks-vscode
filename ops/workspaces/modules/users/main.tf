locals {
  admin_users = toset([
    "fabian.jakobs@databricks.com",
    "kartik.gupta@databricks.com",
    "lennart.kats@databricks.com",
    "paul.leventis@databricks.com",
    "pieter.noordhuis@databricks.com",
    "serge.smertin@databricks.com",
    "shreyas.goenka@databricks.com",
  ])
}

data "databricks_group" "admins" {
  display_name = "admins"
}

data "databricks_group" "users" {
  display_name = "users"
}

resource "databricks_user" "admin" {
  for_each  = local.admin_users
  user_name = each.key
  force     = true
}

resource "databricks_group_member" "admin" {
  for_each  = local.admin_users
  group_id  = data.databricks_group.admins.id
  member_id = databricks_user.admin[each.key].id
}
