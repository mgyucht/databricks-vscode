import pyspark.sql.functions as F
from pyspark.sql import DataFrame

from .unified_user_agent import with_unified_user_agent


def filter_irrelevant_user_agents(df: DataFrame) -> DataFrame:
    prefix = F.split(df["userAgent.redactedUserAgent"], "/", 2)[0]

    # This list was manually compiled by doing a count by `prefix`
    # on data for a single day and listing the top N that look not relevant.
    ignore = [
        "AzureDataFactory",
        "Jetty",
        "SimbaSparkODBCDriver",
        "Databricks Periodic Health Check",
        "DatabricksDatabricksJDBCDriver",
        "SimbaSparkJDBCDriver",
        "MicrosoftSparkODBCDriver",
        "PyDatabricksSqlConnector",
        "Java",
        "Thrift",
        "Mozilla",
        "Compute-Gateway (client)",
        "Python",
        # Internal agents.
        "kube-probe",
        "wsfs",
        "wsfsbackend",
        "armeria",
    ]

    # Filters out the rows we don't care about (the vast majority).
    return df.filter(~prefix.isin(ignore))


def filter_http_access_logs(df: DataFrame) -> DataFrame:
    df = df.filter(df["userAgent.agentClass"] == F.lit("Other"))

    # Remove columns we don't care about.
    df = df.drop(
        "shardName",
        "appName",
        "streamGUID",
        "streamOffset",
        "referrer",
        "requestId",
        "traceparent",
        "instanceId",
        "replicaId",
    )

    return df


def transform_http_access_logs(df: DataFrame) -> DataFrame:
    df = df.transform(filter_irrelevant_user_agents)
    df = df.transform(filter_http_access_logs)
    df = df.transform(with_unified_user_agent(df["userAgent.redactedUserAgent"]))
    return df
