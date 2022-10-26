# To make an apply against an empty state work, you need
# to first provision this service account and manually give
# it the admin role in the Databricks account console.
module "service_account" {
  source       = "../../modules/gcp-service-account"
  environment  = "prod"
  display_name = "Service account for provisioning workspaces"
}
