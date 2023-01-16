import pyspark.sql.functions as F
from pyspark.sql import Column, DataFrame

from .upstream import (
    join_canonical_customer_name_on_workspace_id,
    filter_real_customers_only,
)


def filter_vscode_product(df: DataFrame) -> DataFrame:
    validProducts = [
        # Until version 0.0.9 the product name was "vscode-extension".
        "vscode-extension",
        # It was changed to "databricks-vscode" on Jan 9, 2023.
        # See https://github.com/databricks/databricks-vscode/pull/309.
        "databricks-vscode",
    ]

    return df.filter(df["unifiedUserAgent.product"].isin(validProducts))


def drop_unused_access_logs_columns(df: DataFrame) -> DataFrame:
    return df.drop(
        # We use only `canonicalPath` so can drop the literal `path`.
        "path",
        "virtualCluster",
        "upstreamServiceName",
        "upstreamRequestAttemptCount",
        "internalReq",
        "userAgent",
    )


def http_access_logs(df: DataFrame) -> DataFrame:
    return df.transform(filter_vscode_product).transform(
        drop_unused_access_logs_columns
    )


def daily_traffic(df: DataFrame) -> DataFrame:
    """
    This transform aggregates access logs into a summary per workspace per day.
    For metrics like WAC or WAW we only care about these aggregates.
    """

    # Count requests by day by workspace.
    df = df.groupBy(
        df["date"],
        df["workspaceId"],
        df["method"],
        df["canonicalPath"],
    ).agg(F.count(F.lit(1)).alias("requests"))

    # Include the customer name.
    df = df.transform(join_canonical_customer_name_on_workspace_id)
    return df


def _weekly_active_common(df: DataFrame, agg: Column) -> DataFrame:
    df = df.transform(filter_real_customers_only)
    df = df.withColumn("week", F.date_trunc("week", df["date"]))
    df = df.groupBy(df["week"]).agg(agg)

    # Turn datetime into string representation of the first day of the week.
    df = df.withColumn("week", F.date_format(df["week"], "yyyy-MM-dd"))
    return df


def weekly_active_workspaces(df: DataFrame) -> DataFrame:
    """
    Turn daily traffic into weekly active workspaces.
    """
    return _weekly_active_common(
        df, F.count_distinct(df["workspaceId"]).alias("activeWorkspaces")
    )


def weekly_active_customers(df: DataFrame) -> DataFrame:
    """
    Turn daily traffic into weekly active customers.
    """
    return _weekly_active_common(
        df, F.count_distinct(df["canonicalCustomerName"]).alias("activeCustomers")
    )


def customers_usage_first_last(df: DataFrame) -> DataFrame:
    """
    Turn daily traffic into customers and the first and last day they produced traffic.
    """

    isPost = df["method"] == "POST"

    # "Run File" is a POST to /commands/execute.
    isRunFile = isPost & (df["canonicalPath"] == "/api/1.2/commands/execute")
    df = df.withColumn("runFile", F.when(isRunFile, df["requests"]).otherwise(0))

    # "Run File as Workflow" is a POST to /jobs/runs/submit.
    isRunFileAsJob = isPost & (df["canonicalPath"] == "/api/2.1/jobs/runs/submit")
    df = df.withColumn("runFileAsJob", F.when(isRunFileAsJob, df["requests"]).otherwise(0))

    # Aggregate by customer name (real only).
    df = df.transform(filter_real_customers_only)
    df = df.groupBy(df["canonicalCustomerName"]).agg(
        F.min(df["date"]).alias("firstUse"),
        F.max(df["date"]).alias("lastUse"),
        F.sum(df["requests"]).alias("totalRequests"),
        F.sum(df["runFile"]).alias("runFileRequests"),
        F.sum(df["runFileAsJob"]).alias("runFileAsJobRequests"),
        F.countDistinct(df["date"]).alias("usageDays"),
    )
    # Include number of days between today and the last use for easy filtering.
    df = df.withColumn("idleDays", F.datediff(F.current_date(), df["lastUse"]))
    return df