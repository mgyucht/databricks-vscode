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

For every workspace:

* create secrets environment in github actions
* Create PAT, add as `DATABRICKS_TOKEN` secret
* Copy workspace URL, add as `DATABRICKS_HOST` secret

# directories



## modules

holds reusable "terraform modules", that could be included either in other modules or terraform working directories

### admin list

holds static list of admins of developer ecosystem team. affects azure and all created workspace invites. please document every usage of it in this readme.