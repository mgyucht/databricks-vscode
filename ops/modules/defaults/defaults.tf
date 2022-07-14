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
  ]
}

output "tags" {
  value = {
    "Owner" : "eng-dev-ecosystem-team@databricks.com"
  }
}

output "azure_development_sub" {
  description = "Databricks Development worker"
  value = "36f75872-9ace-4c20-911c-aea8eba2945c"
}

output "azure_staging_sub" {
  description = "Databricks Staging worker"
  value = "596df088-441c-4a6f-881e-5511128a3f1c"
}

output "azure_production_sub" {
  description = "Databricks Production worker"
  value = "2a5a4578-9ca9-47e2-ba46-f6ee6cc731f2"
}

output "azure_tenant_id" {
  description = "Test Customer Directory"
  value = "e3fe3f22-4b98-4c04-82cc-d8817d1b17da"
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