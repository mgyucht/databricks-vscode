from pyspark.sql import SparkSession

from lib.upstream import (
    account_id_to_customer_info,
    workspace_id_to_customer_info,
    join_canonical_customer_name_on_workspace_id,
)


def test_workspaces(spark: SparkSession):
    df = workspace_id_to_customer_info(spark)
    assert df.count() == 5


def test_accounts(spark: SparkSession):
    rows = account_id_to_customer_info(spark).collect()
    assert len(rows) == 1

    # We have multiple accounts in the fixture.
    # This must always resolve to the customer name associated
    # with the most recently launched workspace for the account.
    assert rows[0]["canonicalCustomerName"] == "Databricks D"


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
