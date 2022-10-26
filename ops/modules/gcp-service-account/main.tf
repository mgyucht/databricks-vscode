variable "environment" {
  type = string
}

variable "display_name" {
  type = string
}

module "defaults" {
  source = "../defaults"
}

resource "google_service_account" "admin" {
  account_id   = "deco-${var.environment}-admin"
  display_name = var.display_name
}

// Beware: you cannot add new users as owner through the API.
// You must add them manually through the console.
// https://console.cloud.google.com/iam-admin/iam?orgonly=true&project=eng-dev-ecosystem&supportedpurview=organizationId.
data "google_iam_policy" "this" {
  binding {
    role    = "roles/iam.serviceAccountTokenCreator"
    members = [for u in module.defaults.admins : "user:${u}"]
  }
}

// This policy allows the listed users to create tokens on behalf of the service account.
resource "google_service_account_iam_policy" "impersonatable" {
  service_account_id = google_service_account.admin.name
  policy_data        = data.google_iam_policy.this.policy_data
}

resource "google_project_iam_custom_role" "workspace_creator" {
  role_id = "workspace_creator_${var.environment}"
  title   = "Terraformed Workspace Creator"

  permissions = [
    "iam.serviceAccounts.getIamPolicy",
    "iam.serviceAccounts.setIamPolicy",
    "iam.roles.create",
    "iam.roles.delete",
    "iam.roles.get",
    "iam.roles.update",
    "resourcemanager.projects.get",
    "resourcemanager.projects.getIamPolicy",
    "resourcemanager.projects.setIamPolicy",
    "serviceusage.services.get",
    "serviceusage.services.list",
    "serviceusage.services.enable"
  ]
}

data "google_client_config" "current" {}

resource "google_project_iam_member" "admin_can_create_workspaces" {
  project = data.google_client_config.current.project
  role    = google_project_iam_custom_role.workspace_creator.id
  member  = "serviceAccount:${google_service_account.admin.email}"
}

output "email" {
  value = google_service_account.admin.email
}

output "name" {
  value = google_service_account.admin.name
}
