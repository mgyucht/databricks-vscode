import pytest

import pyspark.sql.functions as F
from pyspark.sql import SparkSession
from pyspark.sql.types import StructType, StructField, StringType

from lib.http_access_logs import filter_on_user_agent, include_account_id


@pytest.fixture
def schema():
    return StructType(
        [
            StructField(
                "userAgent",
                StructType(
                    [
                        StructField("agentClass", StringType()),
                        StructField("redactedUserAgent", StringType()),
                    ]
                ),
            ),
            StructField(
                "path",
                StringType(),
            ),
        ]
    )


def test_http_access_logs_filter_on_user_agent(spark: SparkSession, schema):
    examples = [
        "mlflow-python-client/1.15.0",
        "AHC/2.1",
        "Informatica V1.0.0",
        "AzureDataFactory DataFlow",
        "databricks-cli-0.10.0-",
        "sentry/9.1.2 (https://sentry.io)",
        "Edge Health Probe",
        "Privacera-PolicySync/2.0",
        "airflow-1.10.12",
        "databricks-cli-0.8.6-",
        "databricks-tf-provider/0.5.7 (+permissions) terraform/1.3.4",
        "AzureDataFactory-DeltaLake",
        "AzureDataFactory",
    ]

    df = spark.createDataFrame(
        data=[
            {
                "userAgent": {
                    "agentClass": "Other",
                    "redactedUserAgent": ua,
                },
            }
            for ua in examples
        ],
        schema=schema,
    )

    df = filter_on_user_agent(df)
    out = df.select(F.col("userAgent.redactedUserAgent").alias("ua")).collect()
    out = list(map(lambda x: x["ua"], out))
    assert out == [
        "databricks-cli-0.10.0-",
        "airflow-1.10.12",
        "databricks-cli-0.8.6-",
        "databricks-tf-provider/0.5.7 (+permissions) terraform/1.3.4",
    ]


def test_http_access_logs_include_account_id(spark: SparkSession, schema):
    df = spark.createDataFrame(
        data=[
            {
                "path": "/api/2.0/accounts/da8666d0-7fd9-4bae-b651-3a9ec8f06b5e/foo",
            },
            {
                "path": "/api/2.0/something/else",
            },
            {
                "path": None,
            },
        ],
        schema=schema,
    )

    out = include_account_id(df).collect()
    assert out[0].asDict().get("accountId") == "da8666d0-7fd9-4bae-b651-3a9ec8f06b5e"
    assert out[1].asDict().get("accountId") == None
    assert out[2].asDict().get("accountId") == None
