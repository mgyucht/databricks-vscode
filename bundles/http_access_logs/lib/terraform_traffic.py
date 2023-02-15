import pyspark.sql.functions as F
from pyspark.sql import DataFrame, Column


class TerraformTraffic:
    def __init__(self, df: DataFrame) -> None:
        # DataFrame has schema of `deco.http_access_logs`.
        self.df = df

        # Setup common user agent related columns
        self.ua = df["unifiedUserAgent"]["original"]
        self.uaSplitSpaces = F.split(self.ua, r"\s+")
        self.uaProductInfo = F.split(self.uaSplitSpaces[0], "/")
        self.uaProduct = self.uaProductInfo[0]
        self.uaVersion = self.uaProductInfo[1]

        # Setup common path columns
        self.path = df["canonicalPath"]
        self.pathSplit = F.split(self.path, "/")

    def is_gte_030(self) -> Column:
        # Since 0.3.0 the user agent includes the resource.
        # For earlier versions it must be derived from the HTTP path.
        #
        # Also see:
        # * https://github.com/databricks/terraform-provider-databricks/releases/tag/v0.3.0.
        # * https://github.com/databricks/terraform-provider-databricks/commit/daf00d33b98b7584ce970f6799ab6461225a6de3
        #
        # Example: databricks-tf-provider/0.3.0 (+dbfs_file) terraform/0.14.6
        return F.size(self.uaSplitSpaces) > 1

    def derive_resource(self) -> Column:
        # If the version is >= 0.3.0, the user agent has the following format:
        # databricks-tf-provider/0.3.0 (+dbfs_file) terraform/0.14.6
        cond = F.when(
            self.is_gte_030(),
            F.regexp_extract(self.uaSplitSpaces[1], r"\(\+(.*?)\)", 1),
        )

        # For < 0.3.0, try to match HTTP path to resource.
        for pattern, resource in {
            "/api/2.0/clusters%": "cluster",
            "/api/2.0/policies/cluster%": "cluster_policy",
            "/api/2.0/preview/permissions%": "permissions",
            "/api/2.0/preview/scim/v2/M%": "permissions",
            "/api/2.0/libraries%": "cluster_library",
            "/api/2.0/workspace%": "notebook",
            "/api/2.0/token%": "token",
            "/api/2.0/preview/scim/v2/Users%": "user",
            "/api/2.0/preview/scim/v2/Groups%": "groups",
            "/api/2.0/preview/scim/v2/ServicePrincipals%": "service_principal",
            "/api/2.0/instance-profile%": "instance_profile",
            "/api/2.0/secrets/scope%": "secret_scope",
            "/api/2.0/secret%": "secret",
            "/api/2.0/instance-pool%": "instance_pool",
            "/api/2.0/jobs%": "job",
            "/api/2.0/dbfs%": "dbfs_file",
            "/api/1.2%": "mount",
            "/api/2.0/preview/workspace-con%": "workspace_conf",
            "/api/2.0/ip-access-list%": "ip_access_list",
            "/api/2.0/preview/ip-access-list%": "ip_access_list",
        }.items():
            cond = cond.when(self.path.like(pattern), F.lit(resource))

        # For < 0.3.0, try to match HTTP paths for the account console to resource.
        for pathChunk, resource in {
            "workspaces": "mws_workspaces",
            "storage-configurations": "mws_storage_configurations",
            "networks": "mws_networks",
            "credentials": "mws_credentials",
            "customer-managed-keys": "mws_customer_managed_keys",
            "log-delivery": "mws_log_delivery",
            "private-access-settings": "mws_private_access_settings",
            "vpc-endpoints": "mws_vpc_endpoint",
        }.items():
            cond = cond.when(self.pathSplit[5] == F.lit(pathChunk), F.lit(resource))

        return cond.otherwise(F.lit("unknown"))

    def provider_version(self) -> Column:
        return F.when(self.uaVersion == F.lit("dev"), "0.2.0").otherwise(
            F.coalesce(self.uaVersion, F.lit("unknown"))
        )

    def terraform_version(self) -> Column:
        # Example: databricks-tf-provider/0.3.0 (+dbfs_file) terraform/0.14.6
        uaTerraformInfo = F.split(self.uaSplitSpaces[2], "/")

        return F.when(
            uaTerraformInfo[0] == F.lit("terraform"), uaTerraformInfo[1]
        ).otherwise(F.lit("unknown"))

    def cloud_type(self) -> Column:
        host = self.df["hostname"]
        return (
            F.when(host.like("%.cloud.databricks.com"), F.lit("aws"))
            .when(host.like("%.azuredatabricks.net"), F.lit("azure"))
            .when(host.like("%.gcp.databricks.com"), F.lit("gcp"))
            .otherwise("unknown")
        )

    @staticmethod
    def transform(input: DataFrame) -> DataFrame:
        tt = TerraformTraffic(input)
        accountsConsole = input["hostname"] == "accounts.cloud.databricks.com"
        resource = tt.derive_resource()

        df = input.filter(tt.uaProduct == F.lit("databricks-tf-provider"))
        df = df.select(
            "date",
            "timestamp",
            "workspaceId",
            "accountId",
            "unifiedUserAgent",
            "canonicalPath",
            "status",
            "hostname",
        )
        df = df.withColumn(
            "accountId",
            F.when(accountsConsole & resource.like("mws_%"), df["accountId"]),
        )
        df = df.withColumn("resource", resource)
        df = df.withColumn("version", tt.provider_version())
        df = df.withColumn("terraformVersion", tt.terraform_version())
        df = df.withColumn("cloudType", tt.cloud_type())
        df = df.withColumn("received", F.lit(1))

        # 404 is a valid way for terraform to check if resource is removed
        httpStatus = input["status"].cast("int")
        df = df.withColumn(
            "error", F.when(~httpStatus.isin(200, 201, 204, 404), 1).otherwise(0)
        )
        df = df.withColumn("httpStatus", httpStatus)
        df = df.withColumn("accountsConsole", accountsConsole)
        df = df.drop("hostname", "status", "unifiedUserAgent", "canonicalPath")

        return df
