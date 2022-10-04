Is a special terraform root, because it's set up semi-manually. It holds configuration for:

* `decotfstate` Storage Account for a terraform states
* `deco-kv` Key Vault for various secrets. Only admins of this team can list/get/set secrets in this vault.

# Rotating the GitHub token

First:
* This token is for the `eng-dev-ecosystem-bot` GitHub user.
* This user is **NOT** a member of the `databricks/eng-dev-ecosystem` team; it is manually added to the repositories it needs access to.
* The token is scoped to `repo` access.
* We rotate the token every month, at the beginning of the month.
* It is stored in the `deco-github-meta-kv` Azure KeyVault.
* The token is synchronized to GitHub environments so that it can be used for access to private Databricks repositories.


Acquiring a new token:
* Log in as the `eng-dev-ecosystem-bot` GitHub user. You can find credentials in the shared LastPass folder.
* Navigate to [https://github.com/settings/tokens/new](https://github.com/settings/tokens/new).
* Name for the token: `DECO_GITHUB_PAT_OCTOBER_2022` (replace month and year).
* Expiration: custom, select 15 days into the next month (to allow ourselves time to rotate it).
* Select scopes: `Full control of private repositories` (click `repo`).
* Click "Generate token" at the bottom of the page.
* Copy the token to your clipboard (it is only shown once).
* Now click "Authorize SSO" and authorize the token for usage with the Databricks organization.
* You'll be guided through Okta to log in as the service user (credentials in LastPass).

Add it to Azure KeyVault:
* Navigate to [this page][deco-github-token] and add a new version for this secret.
* Enter the token for the "Secret value".
* Set the expiration date equal to the expiration date of the GitHub token.
* Click "Create" at the bottom of the page.

Redeploy the secret to GitHub environments:
* Navigate to `ops/meta`.
* Run `terraform apply`.
* The resulting Terraform plan should show that the GitHub secret will be refreshed in each environment.
* Inspect the set of changes that will be made
* Agree to apply.
* Done!

[deco-github-token]: https://portal.azure.com/#@dbtestcustomer.onmicrosoft.com/asset/Microsoft_Azure_KeyVault/Secret/https://deco-gh-meta.vault.azure.net/secrets/DECO-GITHUB-TOKEN
