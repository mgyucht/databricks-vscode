resource "google_service_account" "admin" {
  account_id   = "deco-admin"
  display_name = "Service account for provisioning workspaces"
}

data "google_iam_policy" "this" {
  binding {
    role    = "roles/iam.serviceAccountTokenCreator"
    members = local.owners
  }
}

# This policy allows the listed users to create tokens on behalf of the service account.
resource "google_service_account_iam_policy" "impersonatable" {
  service_account_id = google_service_account.admin.name
  policy_data        = data.google_iam_policy.this.policy_data
}

resource "google_project_iam_custom_role" "workspace_creator" {
  role_id = "workspace_creator"
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
