from pyspark.sql import SparkSession

from lib.upstream import list_accounts, list_workspaces


def test_workspaces(spark: SparkSession):
    df = list_workspaces(spark)
    assert df.count() == 4


def test_accounts(spark: SparkSession):
    df = list_accounts(spark)
    assert df.count() == 1
