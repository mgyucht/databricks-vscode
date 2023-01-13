import pyspark.sql.functions as F
from pyspark.sql import DataFrame, SparkSession


def list_accounts(spark: SparkSession) -> DataFrame:
    return (
        spark.table("prod.workspaces")
        .filter(F.col("accountId").isNotNull())
        .select(
            "accountId",
            "canonicalCustomerName",
            "isRealCustomer",
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
            "isRealCustomer",
        )
        .alias("workspaces")
    )


def join_canonical_customer_name_on_workspace_id(df: DataFrame) -> DataFrame:
    workspaces = list_workspaces(df.sparkSession).alias("workspaces")
    df = df.alias("input")
    df = df.join(
        workspaces,
        on=df["workspaceId"] == workspaces["workspaceId"],
        how="left",
    )
    df = df.select(
        "input.*",
        "workspaces.canonicalCustomerName",
        "workspaces.isRealCustomer",
    )
    return df


def filter_real_customers_only(df: DataFrame) -> DataFrame:
    return df.filter(df["isRealCustomer"])
