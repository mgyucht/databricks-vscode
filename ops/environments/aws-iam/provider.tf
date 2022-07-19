terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
    databricks = {
      source  = "databricks/databricks"
      version = ">= 1.0.0"
    }
  }
}

module "defaults" {
  source = "../../modules/defaults"
}

provider "aws" {
  // comment out before making SSE ticket
  profile = "aws-dev_databricks-power-user"
  region = "us-west-2"
}
