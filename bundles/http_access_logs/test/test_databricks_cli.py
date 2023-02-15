from pyspark.sql import SparkSession

from lib import databricks_cli, http_access_logs

from fixtures import load_fixture


def test_databricks_cli_http_access_logs(spark: SparkSession):
    df = load_fixture(spark, "databricks_cli_http_access_logs.json")
    df = df.transform(http_access_logs.transform_http_access_logs)
    df = df.transform(databricks_cli.http_access_logs)

    rows = df.collect()
    assert len(rows) == 3

    row = rows[0].asDict(recursive=True)
    assert row["productVersion"] == "0.17.3"
    assert row["productVersionMajor"] == 0
    assert row["productVersionMinor"] == 17
    assert row["command"] == "runs-get"
    assert row["sdk"] == False

    row = rows[1].asDict(recursive=True)
    assert row["productVersion"] == "0.11.0"
    assert row["productVersionMajor"] == 0
    assert row["productVersionMinor"] == 11
    assert row["command"] == None
    assert row["sdk"] == True

    row = rows[2].asDict(recursive=True)
    assert row["productVersion"] == "0.17.4"
    assert row["productVersionMajor"] == 0
    assert row["productVersionMinor"] == 17
    assert row["command"] == "unity-catalog-external-locations-delete"
    assert row["sdk"] == False
