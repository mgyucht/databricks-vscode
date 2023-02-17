import pyspark.sql.functions as F
import pyspark.sql.window as W
from pyspark.sql import DataFrame, SparkSession


def account_id_to_customer_info(spark: SparkSession) -> DataFrame:
    window = W.Window.partitionBy("accountId").orderBy(F.desc("creationTime"))

    # Resolve a single customer name for every account ID.
    #
    # This is necessary because some accounts have multiple workspaces
    # with different account names associated with them.
    #
    # We achieve this by using the customer name associated with the
    # most recently created workspace for an account.
    #
    return (
        spark.table("prod.workspaces")
        .filter(F.col("accountId").isNotNull())
        .withColumn("row", F.row_number().over(window))
        .filter(F.col("row") == 1)
        .select(
            "accountId",
            "canonicalCustomerName",
            "isRealCustomer",
        )
    )


def workspace_id_to_customer_info(spark: SparkSession) -> DataFrame:
    return spark.table("prod.workspaces").select(
        "workspaceId",
        "canonicalCustomerName",
        "workspaceName",
        "workspaceStatus",
        "isRealCustomer",
    )


def join_canonical_customer_name_on_workspace_id(df: DataFrame) -> DataFrame:
    workspaces = workspace_id_to_customer_info(df.sparkSession).alias("workspaces")
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
