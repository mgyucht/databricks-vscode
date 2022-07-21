variable "prefix" {
  default = "deco"
}

variable "azure_application_ids" {
  description = "Azure needs an application ID of AAD SPN, which is empty for AWS"
  type = object({
    admins   = string
    data_eng = string
    data_sci = string
  })
  default = {
    admins   = ""
    data_eng = ""
    data_sci = ""
  }
}

// create admins group
module "admins" {
  source               = "../databricks-group"
  name                 = "${var.prefix}-admins"
  azure_application_id = var.azure_application_ids.admins
}

// fetch defaults
module "defaults" {
  source = "../defaults"
}

// add deco team users to account
resource "databricks_user" "uc_admin" {
  for_each  = toset(module.defaults.admins)
  user_name = each.key
  force     = true
}

// and add them to uc admin group
resource "databricks_group_member" "uc_admin" {
  for_each  = toset(module.defaults.admins)
  group_id  = module.admins.result.group_id
  member_id = databricks_user.uc_admin[each.key].id
}

// and make the service principal admin
resource "databricks_service_principal_role" "acct_admin" {
  service_principal_id = module.admins.result.service_principal_id
  role                 = "account_admin"
}

output "admins" {
  value = module.admins.result
}

// create "data engineering" fixture group
module "data_eng" {
  source               = "../databricks-group"
  name                 = "${var.prefix}-data-engineering"
  azure_application_id = var.azure_application_ids.data_eng
}

output "data_eng" {
  value = module.data_eng.result
}

// create "data science" fixture group
module "data_sci" {
  source               = "../databricks-group"
  name                 = "${var.prefix}-data-science"
  azure_application_id = var.azure_application_ids.data_sci
}

output "data_sci" {
  value = module.data_sci.result
}