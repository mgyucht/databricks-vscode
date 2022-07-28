module "users" {
  source = "../../modules/databricks-decoadmins"
}

module "clusters" {
  source = "../../modules/databricks-clusters"
}