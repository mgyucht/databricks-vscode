# Keeping environments up-to-date (on-call)

We need to make sure that AAD SPN and Databricks PAT tokens are regenerated regularly enough. Here's the small SOP about doing this:

Please make sure to run `az login --tenant e3fe3f22-4b98-4c04-82cc-d8817d1b17da` to access Azure Key Vaults.

## AWS

**Prerequisites**

You are a power user on aws-dev account. File fresh service ticket if not

**Steps**

1. `cd aws-prod`
2. `gimme-aws-creds --roles arn:aws:iam::707343435239:role/aws-dev_databricks-power-user`
3. `terraform init`
4. `terraform apply`
5. `cd -`

## Azure

1. `cd azure-prod`
2. `az login --tenant e3fe3f22-4b98-4c04-82cc-d8817d1b17da`
3. `terraform init`
4. `terraform apply`
5. `cd -`

## GCP

**Prerequisites**

You are an admin on the deco google cloud account. Request access if not


If you don't have `gcloud` SDK installed locally, please [install it](https://cloud.google.com/sdk/docs/install).

**steps**

1. `cd gcp-prod`
2. `gcloud auth application-default login`
3. `terraform init`
4. `terraform apply`
5. `cd -`

## GitHub Secrets


**Prerequisites**

Install github cli: https://cli.github.com/manual/installation

**steps**

1. `cd meta`
2. `gh auth login`
3. `terraform init`
4. `terraform apply`
5. `cd -`

## Wiki for inventory

1. `cd wiki`
2. `terraform init`
3. `terraform apply`
4. `cd -`


## Known Issues

#### 1. Terraform plan computation on an aws workspace takes forever

Your aws credentials might have expired, wait for the `terraform plan` or `terraform apply` command to timeout (can take ~30 minutes) and then refresh your credentials

#### 2. Error: Error acquiring the state lock

Two things are possible:
1. There is an ongoing deployment by someone else. Check in with the current lock holder to merge pull their changes and avoid merge conflicts
2. The lock was not cleaned up, can happen if the terraform run did not exit gracefully. In this case you need to break the lease on the lock

##### How to break the lease on the state lock

Find SOP with cute screenshots on http://go/deco/sop-break-lease


##### If you see IncorrectClaimException

logging in with Test Customer Directory Tenant is the way to fix it:

```
az login -t e3fe3f22-4b98-4c04-82cc-d8817d1b17da
```
