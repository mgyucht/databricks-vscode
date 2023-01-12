import pyspark.sql.functions as F
from pyspark.sql import DataFrame, SparkSession


def list_accounts(spark: SparkSession) -> DataFrame:
    return (
        spark.table("prod.workspaces")
        .filter(F.col("accountId").isNotNull())
        .select(
            "accountId",
            "canonicalCustomerName",
        )
        .distinct()
        .alias("accounts")
    )


def list_workspaces(spark: SparkSession) -> DataFrame:
    return (
        spark.table("prod.workspaces")
        .select(
            "workspaceId",
            "canonicalCustomerName",
            "workspaceName",
            "workspaceStatus",
        )
        .alias("workspaces")
    )
