# aws-iam

This is a separate directory because we (the developer ecosystem team) don't have IAM write access.

The changes in this directory must be applied by folks on the security engineering team.

To make changes, please:

1. Create a PR

2. Run `terraform plan` (see below)

3. Get a review from a peer

4. File an SSE ticket with the security engineering team
    * Send an email with the following template to security-internal@databricks.com

      ```
      Account: aws-dev
      Service: [e.g. insert the PR title here]
      Owner: @Pieter Noordhuis
      Description:

      [e.g. insert the PR description here]

      The pull request with Terraform code is at https://github.com/databricks/eng-dev-ecosystem/pull/NNN.
      ```

5. Profit!

## Running terraform plan

We don't hardcode the AWS profile name in `provider.tf` because
we (the developer ecosystem team) use `aws-dev_databricks-power-user` while
the security team uses a different role with elevated privileged.

Running `terraform plan`:
```
# Make sure you have accesss to the bucket storing Terraform state
gimme-aws-creds --roles arn:aws:iam::707343435239:role/aws-dev_databricks-power-user

# Explicitly pass the AWS profile to use here.
env AWS_PROFILE=aws-dev_databricks-power-user terraform plan
```
