locals {
  # Beware: you cannot add new users as owner through the API.
  # You must add them manually through the console.
  #
  # See https://console.cloud.google.com/iam-admin/iam?orgonly=true&project=eng-dev-ecosystem&supportedpurview=organizationId.
  #
  owners = [
    "user:fabian.jakobs@databricks.com",
    "user:kartik.gupta@databricks.com",
    "user:lennart.kats@databricks.com",
    "user:paul.leventis@databricks.com",
    "user:pieter.noordhuis@databricks.com",
    "user:serge.smertin@databricks.com",
  ]
}
