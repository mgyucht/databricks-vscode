# Workspaces

* Each workspace has its own Terraform deployment.
* Reuse of common configuration is achieved through `./modules`.

### Naming

Use the following pattern: `deco-{env}-{cloud}-{region}`.

For example:

* deco-staging-aws-us-west-2
* deco-prod-azure-eastus2
* deco-staging-azure-southcentralus
* deco-prod-gcp-us-central1
