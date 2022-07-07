terraform {
  required_providers {
    databricks = {
      source = "databricks/databricks"
    }
  }
}

data "terraform_remote_state" "azure" {
  backend = "s3"

  config = {
    region  = "us-west-2"
    bucket  = "deco-terraform-state"
    key     = "terraform/eng-dev-ecosystem/ops/cloud/azure/terraform.tfstate"
    profile = "aws-dev_databricks-power-user"
  }
}

provider "databricks" {
  host = data.terraform_remote_state.azure.outputs.prod_workspace_url
}
