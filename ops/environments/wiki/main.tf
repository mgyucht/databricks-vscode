terraform {
  backend "azurerm" {
    # Test Customer Directory
    tenant_id = "e3fe3f22-4b98-4c04-82cc-d8817d1b17da"

    # Databricks Development Worker
    subscription_id = "36f75872-9ace-4c20-911c-aea8eba2945c"

    resource_group_name  = "eng-dev-ecosystem-rg"
    storage_account_name = "decotfstate"
    container_name       = "tfstate"
    key                  = "ops/environments/wiki/terraform.tfstate"
  }
}

data "terraform_remote_state" "meta" {
  backend = "azurerm"

  config = {
    # Test Customer Directory
    tenant_id = "e3fe3f22-4b98-4c04-82cc-d8817d1b17da"

    # Databricks Development Worker
    subscription_id = "36f75872-9ace-4c20-911c-aea8eba2945c"

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
        account_id      = module.defaults.aws_prod_databricks_account_id
        account_console = module.defaults.aws_prod_account_console
        features = {
          unity_catalog = "ENABLED"
        }
      }
      staging = {
        account_id      = module.defaults.aws_staging_databricks_account_id
        account_console = module.defaults.aws_prod_account_console
        features        = {}
      }
    }
    azure = {
      prod = {
        account_id      = module.defaults.azure_prod_account_id
        account_console = module.defaults.azure_prod_account_console
        features = {
          identity_federation = "ENABLED"
        }
      }
      staging = {
        account_id      = module.defaults.azure_staging_account_id
        account_console = module.defaults.azure_staging_account_console
        features        = {}
      }
    }
    gcp = {
      prod = {
        account_id      = module.defaults.google_production_account
        account_console = "https://accounts.gcp.databricks.com/"
        features        = {}
      }
      staging = {
        account_id      = "9fcbb245-7c44-4522-9870-e38324104cf8"
        account_console = "https://accounts.staging.gcp.databricks.com/"
        features        = {}
      }
    }
  }

  can_of_worms = data.terraform_remote_state.meta.outputs.secrets
  vaults = toset([for k, _ in local.can_of_worms :
    split(":", k)[0]
  ])
  raw_workspaces = { for env in local.vaults :
    replace(replace(env, "deco-gh-", ""), "deco-github-", "") => {
      workspaces = [for k, v in local.can_of_worms : v if k == "${env}:DATABRICKS-HOST"]
      env        = length(regexall(".*-prod.*", env)) > 0 ? "prod" : "staging"
      variables = sort([for k, v in local.can_of_worms :
      replace(split(":", k)[1], "-", "_") if env == split(":", k)[0]])
  } }
  workspaces = { for k, v in local.raw_workspaces : k => {
    cloud      = split("-", k)[0]
    env        = v.env == "stg" ? "staging" : v.env
    workspaces = v.workspaces
    variables  = v.variables
  } if k != "meta" }
  environments = [for k, v in local.workspaces : {
    name            = k,
    cloud           = v.cloud,
    env             = v.env,
    workspace_url   = substr(v.workspaces[0], 0, 5) == "https" ? v.workspaces[0] : "https://${v.workspaces[0]}",
    account_id      = local.mapping[v.cloud][v.env].account_id,
    account_console = local.mapping[v.cloud][v.env].account_console,
    features        = local.mapping[v.cloud][v.env].features,
    variables       = v.variables,
  }]
  table = [for v in local.environments : join("\n", [
    "## ${v.name}",
    " * Cloud: `${v.cloud}`",
    " * Environment: `${v.env}`",
    // TODO: add workspace id to this report
    " * Databricks Host: ${v.workspace_url}",
    " * Account ID: `${v.account_id}`",
    " * Account Console: ${v.account_console}login?account_id=${v.account_id}",
    " * Available environment: `${join("`, `", v.variables)}`",
    " * Previews: ${yamlencode(v["features"])}"
    ])
  ]
}

resource "local_file" "csv" {
  filename = "envs.csv"
  content = join("\n",
    concat([join(",", ["cloud", "env", "workspace_url", "account_id", "account_console"])],
      [for v in local.environments :
        join(",", [v.cloud, v.env, v.workspace_url, v.account_id, v.account_console])
  ]))
}

resource "local_file" "index" {
  filename = "README.md"
  content  = <<-EOT
  # Developer Ecosystem Environments

  ${join("\n", local.table)}
  EOT
}