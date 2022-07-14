Is a special terraform root, because it's set up semi-manually. It holds configuration for:

* `decotfstate` Storage Account for a terraform states
* `deco-kv` Key Vault for various secrets. Only admins of this team can list/get/set secrets in this vault.

# `deco-github-token` secret
`deco-github-token` secret is added to `deco-github-meta-kv` manually. it's generated from [https://github.com/settings/tokens/new](https://github.com/settings/tokens/new). Expected scope is `Full control of private repositories` with expiration of every 30 days and configured SSO to `databricks` github org. This token can be rotated at [this page](https://portal.azure.com/#@dbtestcustomer.onmicrosoft.com/asset/Microsoft_Azure_KeyVault/Secret/https://deco-github-meta-kv.vault.azure.net/secrets/deco-github-token). This secrets is re-synced to [repository secrets](https://github.com/databricks/eng-dev-ecosystem/settings/secrets/actions) by Terraform, so that it could be used for accessing private databricks repositories.