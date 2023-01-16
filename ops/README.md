# Environments (ops/environments)

### Introduction

##### meta

Contains configuration for

* The `decotfstate` storage Account which contains the terraform states for all envs
* The `deco-kv` Key Vault for various secrets. Only admins of this team can list/get/set secrets in this vault.
* Injects secrets from `deco-kv` into github actions for our integration tests to use

##### wiki

Contains configuration for autogeneration of metadata file (ops/environments/wiki/README.md) for all our envs (accounts and workspaces)

TODO: Add a short summary of functionality of the other environments


### Environment terraform state file locations

All terraform state files are stored in `Azure` -> tenant `Test Customer Directory` -> storage account `decotfstate` -> container `tfstate`

### How to apply changes to an environment

read [ops/environments/README.md](environments/README.md) for steps to update an environment with local changes

### Manual steps to create a new test databricks workspace

For every workspace:

* create secrets environment in github actions
* Create PAT, add as `DATABRICKS_TOKEN` secret
* Copy workspace URL, add as `DATABRICKS_HOST` secret


# modules (ops/modules)

holds reusable "terraform modules", that could be included either in other modules or terraform working directories

### admin list (ops/modules/defaults/defaults.tf)

holds static list of admins of developer ecosystem team. affects azure and all created workspace invites. please document every usage of it in this readme.
