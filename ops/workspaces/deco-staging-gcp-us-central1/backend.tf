terraform {
  backend "s3" {
    region  = "us-west-2"
    bucket  = "deco-terraform-state"
    key     = "terraform/eng-dev-ecosystem/ops/workspaces/deco-staging-gcp-us-central1/terraform.tfstate"
    profile = "aws-dev_databricks-power-user"
  }
}
