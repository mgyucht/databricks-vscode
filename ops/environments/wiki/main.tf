terraform {
  backend "azurerm" {
    resource_group_name  = "eng-dev-ecosystem-rg"
    storage_account_name = "decotfstate"
    container_name       = "tfstate"
    key                  = "ops/environments/wiki/terraform.tfstate"
  }
}

data "terraform_remote_state" "meta" {
  backend = "azurerm"

  config = {
    resource_group_name  = "eng-dev-ecosystem-rg"
    storage_account_name = "decotfstate"
    container_name       = "tfstate"
    key                  = "ops/environments/meta/terraform.tfstate"
  }
}

module "defaults" {
  source = "../../modules/defaults"
}

locals {
  mapping = {
    aws = {
        prod = {
            account_id = module.defaults.aws_prod_databricks_account_id
            account_console = "https://accounts.cloud.databricks.com/"
            features = {
                unity_catalog = "ENABLED"
            }
        }
        staging = {
            account_id = module.defaults.aws_staging_databricks_account_id
            account_console = "https://accounts.staging.cloud.databricks.com/"
            features = {}
        }
    }
    azure = {
        prod = {
            account_id = "5a8ac58d-9557-497a-8832-90bd35e641bf"
            account_console = "https://accounts.azuredatabricks.net/"
            features = {
                identity_federation = "ENABLED"
            }
        }
        staging = {
            account_id = "02945107-4221-4317-9276-5e0e9ed7f194"
            account_console = "https://accounts.staging.azuredatabricks.net/"
            features = {}
        }
    }
    gcp = {
        prod = {
            account_id = "e11e38c5-a449-47b9-b37f-0fa36c821612"
            account_console = "https://accounts.gcp.databricks.com/"
            features = {}
        }
        staging = {
            account_id = "9fcbb245-7c44-4522-9870-e38324104cf8"
            account_console = "https://accounts.staging.gcp.databricks.com/"
            features = {}
        }
    }
  }

  can_of_worms = data.terraform_remote_state.meta.outputs.secrets
  vaults = toset([for k, _ in local.can_of_worms: 
    split(":", k)[0]
  ])
  raw_workspaces = {for env in local.vaults: 
    replace(replace(env, "deco-gh-", ""), "deco-github-", "") => {
        workspaces = [for k, v in local.can_of_worms: v if k == "${env}:DATABRICKS-HOST"]
        env = split("-", env)[length(split("-", env))-1]
        variables = length([for k, v in local.can_of_worms: v if env == split(":", k)[0]])
    }}
  workspaces = {for k,v in local.raw_workspaces: k => {
    cloud = split("-", k)[0]
    env = v.env == "stg" ? "staging" : v.env
    workspaces = v.workspaces
    variables = v.variables
  } if k != "meta" && k != "aws-acct-prod"}
  environments = [for v in local.workspaces: {
    cloud = v.cloud,
    env = v.env,
    workspace_url = substr(v.workspaces[0], 0, 5) == "https" ? v.workspaces[0] : "https://${v.workspaces[0]}",
    account_id = local.mapping[v.cloud][v.env].account_id,
    account_console = local.mapping[v.cloud][v.env].account_console,
    features = local.mapping[v.cloud][v.env].features,
  }]
  table = [for v in local.environments: join("\n", [
        "## ${v.cloud} ${v.env}",
        " * ${v.workspace_url}",
        " * Account ID: `${v.account_id}`",
        " * Account Console: ${v.account_console}",
        " * Previews: ${yamlencode(v["features"])}"
    ])
  ]
}

resource "local_file" "csv" {
  filename = "envs.csv"
  content = join("\n", 
    concat([join(",", ["cloud", "env", "workspace_url", "account_id", "account_console"])],
    [for v in local.environments:
        join(",", [v.cloud, v.env, v.workspace_url, v.account_id, v.account_console])
    ]))
}

resource "local_file" "index" {
  filename = "${path.module}/README.md"
  content = <<-EOT
  # Developer Ecosystem Environments

  ${join("\n", local.table)}
  EOT
}