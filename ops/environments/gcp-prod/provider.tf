terraform {
  required_providers {
    databricks = {
      source = "databricks/databricks"
    }
  }
}

module "defaults" {
  source = "../../modules/defaults"
}

provider "google" {
  project = module.defaults.google_project
  region  = module.defaults.google_region
}
