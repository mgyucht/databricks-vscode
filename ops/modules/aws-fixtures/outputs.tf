output "private_subnets" {
  value = [
    module.vpc.private_subnets[0],
    module.vpc.private_subnets[1]
  ]
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "security_group_ids" {
  value = [module.vpc.default_security_group_id]
}

output "bucket_name" {
  value = module.root_bucket.bucket
}

output "managed_services_cmk_arn" {
  value = aws_kms_key.managed_services_customer_managed_key.arn
}

output "managed_services_cmk_alias" {
  value = aws_kms_alias.managed_services_customer_managed_key_alias.name
}

output "storage_cmk_arn" {
  value = aws_kms_key.storage_customer_managed_key.arn
}

output "storage_cmk_alias" {
  value = aws_kms_alias.storage_customer_managed_key_alias.name
}

output "test_env" {
  value = {
    // TODO: rename tests
    "TEST_MANAGED_KMS_KEY_ARN" : aws_kms_key.managed_services_customer_managed_key.arn,
    "TEST_MANAGED_KMS_KEY_ALIAS" : aws_kms_alias.managed_services_customer_managed_key_alias.name
    "TEST_STORAGE_KMS_KEY_ARN" : aws_kms_key.storage_customer_managed_key.arn,
    "TEST_STORAGE_KMS_KEY_ALIAS" : aws_kms_alias.storage_customer_managed_key_alias.name

    "TEST_ROOT_BUCKET" : module.root_bucket.bucket,
    "TEST_METASTORE_BUCKET" : module.metastore_bucket.bucket,
    "TEST_OTHER_BUCKET" : module.other_bucket.bucket,

    "TEST_VPC_ID" : module.vpc.vpc_id,
    "TEST_SECURITY_GROUP" : module.vpc.default_security_group_id,
    "TEST_SUBNET_PRIVATE" : module.vpc.private_subnets[2],
    "TEST_SUBNET_PRIVATE2" : module.vpc.private_subnets[3],

    "TEST_RELAY_VPC_ENDPOINT" : aws_vpc_endpoint.relay.id,

    // TODO: https://github.com/databricks/eng-dev-ecosystem/issues/19
    // TODO: TEST_LOGDELIVERY_ARN
    // TODO: TEST_LOGDELIVERY_BUCKET
  }
}