module deco

go 1.16

require (
	github.com/databrickslabs/terraform-provider-databricks v0.0.0
	github.com/hashicorp/terraform-plugin-sdk/v2 v2.17.0
)

replace github.com/databrickslabs/terraform-provider-databricks v0.0.0 => ../ext/terraform-provider-databricks
