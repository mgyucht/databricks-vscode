// Enable testing for GCP Accounts
// See https://github.com/databricks/terraform-provider-databricks/pull/1479
resource "google_compute_network" "vpc" {
  project                 = data.google_client_config.current.project
  name                    = "deco-prod-gcp-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "this" {
  name          = "deco-prod-gcp-subnet"
  ip_cidr_range = "10.0.0.0/16"
  region        = module.defaults.google_region
  network       = google_compute_network.vpc.id
  
  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = "10.1.0.0/16"
  }
  
  secondary_ip_range {
    range_name    = "svc"
    ip_cidr_range = "10.2.0.0/20"
  }
}

resource "google_service_account_key" "this" {
  service_account_id = google_service_account.admin.name
}

module "secrets_acct_prod" {
  source      = "../../modules/github-secrets"
  environment = "gcp-acct-prod"
  secrets = {
    "CLOUD_ENV": "gcp-accounts",
    "TEST_PREFIX": "TestGcpAcc",
    "DATABRICKS_HOST": "https://accounts.gcp.databricks.com/",
    "DATABRICKS_ACCOUNT_ID": module.defaults.google_production_account,
    "DATABRICKS_GOOGLE_SERVICE_ACCOUNT": google_service_account.admin.email,
    "GOOGLE_CREDENTIALS": google_service_account_key.this.private_key,
    "GOOGLE_PROJECT": data.google_client_config.current.project,
    "GOOGLE_REGION": module.defaults.google_region,
    "TEST_VPC_ID": google_compute_network.vpc.name,
    "TEST_SUBNET_ID": google_compute_subnetwork.this.name,
  }
}
