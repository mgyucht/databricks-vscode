# ops

Terraform state for various deployments in this tree is stored in the `deco-terraform-state` bucket in the `aws-dev` account.

Before trying to run Terraform commands, please refresh your access keys and run:

```
gimme-aws-creds --roles arn:aws:iam::707343435239:role/aws-dev_databricks-power-user
```

If you see IncorrectClaimException, logging in with Test Customer Tenant is the way to fix it:

```
az login -t e3fe3f22-4b98-4c04-82cc-d8817d1b17da # prod
```

# Manual steps

Create Github PAT at https://github.com/settings/tokens/new and store it in `DECO_GITHUB_PAT` secret

For every workspace:

* create secrets environment in github actions
* Create PAT, add as `DATABRICKS_TOKEN` secret
* Copy workspace URL, add as `DATABRICKS_HOST` secret
* Register DECO_GITHUB_PAT in User Settings / Git Integration
