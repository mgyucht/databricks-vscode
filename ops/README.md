# ops

Terraform state for various deployments in this tree is stored in the `deco-terraform-state` bucket in the `aws-dev` account.

Before trying to run Terraform commands, please refresh your access keys and run:

```
gimme-aws-creds --roles arn:aws:iam::707343435239:role/aws-dev_databricks-power-user
```
