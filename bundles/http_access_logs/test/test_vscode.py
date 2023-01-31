import datetime
import pytest

from pyspark.sql import DataFrame, SparkSession

from lib.http_access_logs import transform_http_access_logs
from lib.vscode import (
    http_access_logs,
    daily_traffic,
    weekly_active_workspaces,
    weekly_active_customers,
    customers_usage_first_last,
)

from fixtures import load_fixture


def test_vscode_http_access_logs(spark: SparkSession):
    df = load_fixture(spark, "vscode_http_access_logs.json")
    df = df.transform(transform_http_access_logs)
    df = df.transform(http_access_logs)

    rows = df.collect()
    assert len(rows) == 5

    # Verify that unused column was dropped.
    row = rows[0].asDict(recursive=True)
    assert "virtualCluster" not in row


def test_vscode_daily_traffic(spark: SparkSession):
    df = load_fixture(spark, "vscode_http_access_logs.json")

    df = df.transform(transform_http_access_logs)
    df = df.transform(http_access_logs)
    df = df.transform(daily_traffic)

    rows = df.collect()
    assert len(rows) == 1

    row = rows[0].asDict(recursive=True)
    assert row == {
        "date": "2023-01-03",
        "workspaceId": "309687753508875",
        "canonicalPath": "/api/2.0/clusters/get",
        "method": "GET",
        "requests": 5,
        "canonicalCustomerName": "Databricks",
        "isRealCustomer": True,
        "productVersion": "0.0.8",
    }


@pytest.fixture
def daily_traffic_df(spark: SparkSession) -> DataFrame:
    df = load_fixture(spark, "vscode_http_access_logs.json")
    df = df.transform(transform_http_access_logs)
    df = df.transform(http_access_logs)
    df = df.transform(daily_traffic)
    return df


def test_vscode_weekly_active_workspaces(spark: SparkSession, daily_traffic_df):
    df = daily_traffic_df.transform(weekly_active_workspaces)
    rows = df.collect()
    assert len(rows) == 1

    row = rows[0].asDict(recursive=True)
    assert row == {
        "week": datetime.date(2023, 1, 2),
        "activeWorkspaces": 1,
    }


def test_vscode_weekly_active_customers(spark: SparkSession, daily_traffic_df):
    df = daily_traffic_df.transform(weekly_active_customers)
    rows = df.collect()
    assert len(rows) == 1

    row = rows[0].asDict(recursive=True)
    assert row == {
        "week": datetime.date(2023, 1, 2),
        "activeCustomers": 1,
    }


def test_vscode_customers_usage_first_last(spark: SparkSession, daily_traffic_df):
    df = daily_traffic_df.transform(customers_usage_first_last)
    rows = df.collect()
    assert len(rows) == 1

    row = rows[0].asDict(recursive=True)
    assert row["canonicalCustomerName"] == "Databricks"
    assert row["firstUse"] == "2023-01-03"
    assert row["lastUse"] == "2023-01-03"
    assert row["totalRequests"] == 5
    assert row["runFileRequests"] == 0
    assert row["runFileAsJobRequests"] == 0
    assert row["usageDays"] == 1
    assert row["idleDays"] >= 7
    assert row["maxProductVersion"] == "0.0.8"
