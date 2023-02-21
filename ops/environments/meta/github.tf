// see README.md
data "azurerm_key_vault_secret" "deco_github_token" {
  name         = "DECO-GITHUB-TOKEN"
  key_vault_id = module.secrets.vault_id
}

provider "github" {
  // https://databricks.atlassian.net/browse/ES-390794
  token = data.azurerm_key_vault_secret.deco_github_token.value
  owner = "databricks"
}

// put a token required for private repo checkouts from github actions
resource "github_actions_secret" "github_token" {
  for_each        = toset(["eng-dev-ecosystem", "bricks"])
  repository      = each.key
  secret_name     = "DECO_GITHUB_TOKEN"
  plaintext_value = data.azurerm_key_vault_secret.deco_github_token.value
}

// list all vaults in resource group
data "azurerm_resources" "vaults" {
  type                = "Microsoft.KeyVault/vaults"
  resource_group_name = azurerm_resource_group.this.name
}

// get metadata about every vault, index by vault name
data "azurerm_key_vault" "all" {
  for_each = toset([
    for v in data.azurerm_resources.vaults.resources : v.name
  ])

  name                = each.value
  resource_group_name = azurerm_resource_group.this.name
}

// get names of secrets per every vault, index by vault name
data "azurerm_key_vault_secrets" "all" {
  for_each     = data.azurerm_key_vault.all
  key_vault_id = each.value.id
}

// "$vault:$secret_name" => {$vault, $secret_name}
locals {
  secrets = { for kv in flatten([
    for vn, v in data.azurerm_key_vault_secrets.all : [
      for ev in v.names : {
        "vault" : vn,
        "secret_name" : ev
      } # if ev != data.azurerm_key_vault_secret.deco_github_token.name
  ]]) : "${kv["vault"]}:${kv["secret_name"]}" => kv }
}

// fetch all secret values, index by $vault:$secret_name
data "azurerm_key_vault_secret" "all" {
  for_each     = local.secrets
  name         = each.value.secret_name
  key_vault_id = data.azurerm_key_vault.all[each.value.vault].id
}

locals {
  // Map GitHub repositories to the list of key vaults they need as environments.
  repositories_to_vaults = {
    "eng-dev-ecosystem" = [
      for v in data.azurerm_key_vault.all : v.name
    ]
    "databricks-vscode" = [
      "deco-gh-azure-prod-usr"
    ]
    "dbt-databricks" = [
      "deco-gh-azure-prod-peco"
    ]
  }

  github_environments = {
    for kv in flatten([
      for repository_name, vaults in local.repositories_to_vaults : [
        for vault_name in vaults : {
          repository_name  = repository_name
          environment_name = replace(replace(replace(vault_name, "deco-github-", ""), "deco-gh-", ""), "-kv", "")
          vault_name       = vault_name
        }
      ]
    ]) : "${kv["repository_name"]}:${kv["vault_name"]}" => kv
  }

  github_environment_secrets = {
    for kv in flatten([
      for environment in values(local.github_environments) : [
        for secret_name in data.azurerm_key_vault_secrets.all[environment.vault_name].names :
        merge(
          environment,
          {
            environment_key = "${environment.repository_name}:${environment.vault_name}"
            secret_key      = "${environment.vault_name}:${secret_name}"
            secret_name     = secret_name
          }
        )
      ]
    ]) : "${kv["repository_name"]}:${kv["vault_name"]}:${kv["secret_name"]}" => kv
  }
}

// Create actions environment. Index by ${repository_name}:${vault_name}.
resource "github_repository_environment" "this" {
  for_each    = local.github_environments
  repository  = each.value.repository_name
  environment = each.value.environment_name
}

// Set actions secrets for redaction. Index by ${repository_name}:${vault_name}:${secret_name}.
resource "github_actions_environment_secret" "tests" {
  for_each        = local.github_environment_secrets
  repository      = each.value.repository_name
  secret_name     = replace(each.value.secret_name, "-", "_")
  environment     = github_repository_environment.this[each.value.environment_key].environment
  plaintext_value = data.azurerm_key_vault_secret.all[each.value.secret_key].value
}

// Global configuration of all environments also used for testing.
// TODO: most likely it's a temporary measure. We'll fix it later.
// p.s. I know that storing plaintext secrets is very very bad.
output "secrets" {
  value = { for k, v in local.secrets :
  k => data.azurerm_key_vault_secret.all[k].value }
  sensitive = true
}
