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
  for_each        = toset(["eng-dev-ecosystem"])
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
  for v in data.azurerm_resources.vaults.resources : v.name])
  name                = each.value
  resource_group_name = azurerm_resource_group.this.name
}

// create actions environment, index by vault name
resource "github_repository_environment" "this" {
  for_each    = data.azurerm_key_vault.all
  repository  = "eng-dev-ecosystem"
  environment = replace(replace(replace(each.value.name, "deco-github-", ""), "deco-gh-", ""), "-kv", "")
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

// set all github actions secrets for redaction, index by $vault:$secret_name
resource "github_actions_environment_secret" "tests" {
  for_each        = local.secrets
  repository      = "eng-dev-ecosystem"
  secret_name     = replace(each.value.secret_name, "-", "_")
  environment     = github_repository_environment.this[each.value.vault].environment
  plaintext_value = data.azurerm_key_vault_secret.all[each.key].value
}

// Global configuration of all environments also used for testing.
// TODO: most likely it's a temporary measure. We'll fix it later.
// p.s. I know that storing plaintext secrets is very very bad.
output "secrets" {
  value = { for k, v in local.secrets :
  k => data.azurerm_key_vault_secret.all[k].value }
  sensitive = true
}
