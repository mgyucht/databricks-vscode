from pyspark.sql import SparkSession

from lib.upstream import (
    list_accounts,
    list_workspaces,
    join_canonical_customer_name_on_workspace_id,
)


def test_workspaces(spark: SparkSession):
    df = list_workspaces(spark)
    assert df.count() == 5


def test_accounts(spark: SparkSession):
    df = list_accounts(spark)
    assert df.count() == 1


def test_join_canonical_customer_name_on_workspace_id(spark: SparkSession):
    df = spark.createDataFrame(
        data=[
            {"workspaceId": "3390442228201038"},
            {"workspaceId": "1234"},
        ]
    )

    df = df.transform(join_canonical_customer_name_on_workspace_id)
    rows = df.collect()
    assert len(rows) == 2
    assert rows[0]["canonicalCustomerName"] == "Databricks"
    assert rows[1]["canonicalCustomerName"] is None
