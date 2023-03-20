// holds static list of admins of developer ecosystem team.
// affects azure and all created workspace invites.
// please document every usage of it in this readme.
output "admins" {
  value = [
    "fabian.jakobs@databricks.com",
    "kartik.gupta@databricks.com",
    "lennart.kats@databricks.com",
    "paul.leventis@databricks.com",
    "pieter.noordhuis@databricks.com",
    "serge.smertin@databricks.com",
    "shreyas.goenka@databricks.com",
    "erzen.kaja@databricks.com",
    "paul.cornell@databricks.com",
    "miles@databricks.com",
    "tanmay.rustagi@databricks.com",
  ]
}

// Static list of friends of the Developer Ecosystem team.
// Users listed here are granted read access to our secret vaults.
output "friends" {
  value = [
    "jesse.whitehouse@databricks.com",
    // Not added to "Test Customer Directory" yet.
    // "andre.furlan@databricks.com",
  ]
}

output "tags" {
  value = {
    "Owner" : "eng-dev-ecosystem-team@databricks.com",
    "Budget" : "opex.eng.deco"
  }
}

output "azure_development_sub" {
  description = "Databricks Development worker"
  value       = "36f75872-9ace-4c20-911c-aea8eba2945c"
}

output "azure_staging_sub" {
  description = "Databricks Staging worker"
  value       = "596df088-441c-4a6f-881e-5511128a3f1c"
}

output "azure_production_sub" {
  description = "Databricks Production worker"
  value       = "2a5a4578-9ca9-47e2-ba46-f6ee6cc731f2"
}

output "azure_tenant_id" {
  description = "Test Customer Directory"
  value       = "e3fe3f22-4b98-4c04-82cc-d8817d1b17da"
}

output "azure_prod_account_id" {
  description = "Unity Catalog Account ID for Azure Prod"
  value       = "5a8ac58d-9557-497a-8832-90bd35e641bf"
}

output "azure_prod_account_console" {
  value = "https://accounts.azuredatabricks.net/"
}

output "azure_staging_account_id" {
  description = "Unity Catalog Account ID for Azure Staging"
  value       = "02945107-4221-4317-9276-5e0e9ed7f194"
}

output "azure_staging_account_console" {
  value = "https://accounts.staging.azuredatabricks.net/"
}

output "resource_group" {
  value = "eng-dev-ecosystem-rg"
}

output "google_project" {
  value = "eng-dev-ecosystem"
}

output "google_region" {
  value = "us-central1"
}

output "google_production_account" {
  value = "e11e38c5-a449-47b9-b37f-0fa36c821612"
}

output "google_staging_account" {
  value = "9fcbb245-7c44-4522-9870-e38324104cf8"
}

output "aws_prod_account_id" {
  description = "Databricks AWS Production"
  value       = 414351767826
}

output "aws_prod_account_console" {
  value = "https://accounts.cloud.databricks.com/"
}

output "aws_staging_account_id" {
  description = "Databricks AWS Staging"
  value       = 548125073166
}

output "aws_staging_account_console" {
  value = "https://accounts.staging.cloud.databricks.com/"
}

output "aws_prod_databricks_account_id" {
  description = "https://accounts.cloud.databricks.com/"
  value       = "4d9d3bc8-66c3-4e5a-8a0a-551f564257f0"
}

output "aws_staging_databricks_account_id" {
  description = "https://accounts.staging.cloud.databricks.com/"
  value       = "ed0ca3c5-fae5-4619-bb38-eebe04a4af4b"
}

output "aws_region" {
  value = "us-west-2"
}
