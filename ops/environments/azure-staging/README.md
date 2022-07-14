# Azure AAD Auth doesn't work for this yet

Azure CLI based auth doesn't work for staging workspaces. To repro, try running:

```
az account get-access-token -o json --resource 4a67d088-db5c-48f1-9ff2-0aace800ae68 --subscription 596df088-441c-4a6f-881e-5511128a3f1c
```

The resource ID is the application associated with logging into Databricks workspaces in staging. Also see https://databricks.atlassian.net/wiki/spaces/UN/pages/1536000823/AAD+passthrough+setup+tribal+knowledge. The subscription ID is the one for "Databricks Staging Worker". Attempt (failed) to make this work in Terraform: https://github.com/databricks/terraform-provider-databricks/pull/1399.