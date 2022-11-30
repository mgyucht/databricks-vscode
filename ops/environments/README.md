# Keeping environments up-to-date (on-call)

We need to make sure that AAD SPN and Databricks PAT tokens are regenerated regularly enough. Here's the small SOP about doing this:

Please make sure to run `az login --tenant e3fe3f22-4b98-4c04-82cc-d8817d1b17da` to access Azure Key Vaults.

## AWS

1.1. `cd aws-prod`
1.2. `gimme-aws-creds --roles arn:aws:iam::707343435239:role/aws-dev_databricks-power-user`
1.3. `terraform init`
1.4. `terraform apply`
1.5. `cd -`

## Azure

2.1. `cd azure-prod`
2.2. `terraform init`
2.3. `terraform apply`
2.4. `cd -`

## GCP

If you don't have `gcloud` SDK installed locally, please [install it](https://cloud.google.com/sdk/docs/install).

3.1. `cd gcp-prod`
3.2. `gcloud auth application-default login`
3.3. `terraform init`
3.4. `terraform apply`
3.5. `cd -`

## GitHub Secrets

4.1. `cd meta`
4.2. `terraform init`
4.3. `terraform apply`
4.4. `cd -`

## Wiki for inventory

5.1. `cd wiki`
5.2. `terraform init`
5.3. `terraform apply`
5.4. `cd -`
