variable "databricks_account_id" {}
variable "managed_services_cmk_arn" {}
variable "managed_services_cmk_alias" {}
variable "storage_cmk_arn" {}
variable "storage_cmk_alias" {}
variable "cross_account_role_arn" {}
variable "security_group_ids" {}
variable "bucket_name" {}
variable "subnet_ids" {}
variable "region" {}
variable "vpc_id" {}
variable "prefix" {}

resource "databricks_mws_credentials" "this" {
  account_id       = var.databricks_account_id
  role_arn         = var.cross_account_role_arn
  credentials_name = "${var.prefix}-creds"
}

output "credentials_id" {
  value = databricks_mws_credentials.this.credentials_id
}

resource "databricks_mws_networks" "this" {
  account_id         = var.databricks_account_id
  network_name       = "${var.prefix}-network"
  security_group_ids = var.security_group_ids
  subnet_ids         = var.subnet_ids
  vpc_id             = var.vpc_id
}

resource "databricks_mws_storage_configurations" "this" {
  account_id                 = var.databricks_account_id
  storage_configuration_name = "${var.prefix}-storage"
  bucket_name                = var.bucket_name
}

output "storage_configuration_id" {
  value = databricks_mws_storage_configurations.this.storage_configuration_id
}

resource "databricks_mws_customer_managed_keys" "storage" {
  account_id = var.databricks_account_id
  aws_key_info {
    key_arn   = var.storage_cmk_arn
    key_alias = var.storage_cmk_alias
  }
  use_cases = ["STORAGE"]
}

resource "databricks_mws_customer_managed_keys" "managed_services" {
  account_id = var.databricks_account_id
  aws_key_info {
    key_arn   = var.managed_services_cmk_arn
    key_alias = var.managed_services_cmk_alias
  }
  use_cases = ["MANAGED_SERVICES"]
}

resource "databricks_mws_workspaces" "this" {
  account_id     = var.databricks_account_id
  aws_region     = var.region
  workspace_name = var.prefix

  credentials_id                           = databricks_mws_credentials.this.credentials_id
  storage_configuration_id                 = databricks_mws_storage_configurations.this.storage_configuration_id
  network_id                               = databricks_mws_networks.this.network_id
  managed_services_customer_managed_key_id = databricks_mws_customer_managed_keys.managed_services.customer_managed_key_id
  storage_customer_managed_key_id          = databricks_mws_customer_managed_keys.storage.customer_managed_key_id

  token {
    comment = "Terraform"
  }
}

output "workspace_id" {
  value = databricks_mws_workspaces.this.workspace_id
}

output "databricks_host" {
  value = databricks_mws_workspaces.this.workspace_url
}

output "databricks_token" {
  value     = databricks_mws_workspaces.this.token[0].token_value
  sensitive = true
}