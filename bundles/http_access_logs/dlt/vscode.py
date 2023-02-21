# Databricks notebook source
# DBTITLE 1,Make bundle root available for Python imports.

import sys
sys.path.append(spark.conf.get("bundle.filePath"))

# COMMAND ----------

import dlt

from pyspark.sql import DataFrame

from lib.vscode import (
    http_access_logs,
    daily_traffic,
    weekly_active_workspaces,
    weekly_active_customers,
    customers_usage_first_last,
)


@dlt.table(
    partition_cols=["date"],
)
def vscode_http_access_logs():
    df: DataFrame
    df = dlt.read_stream("http_access_logs")
    df = df.transform(http_access_logs)
    return df


@dlt.table()
def vscode_daily_traffic():
    df: DataFrame
    df = dlt.read_stream("vscode_http_access_logs")
    df = df.transform(daily_traffic)
    return df


@dlt.table()
def vscode_weekly_active_workspaces():
    df: DataFrame
    df = dlt.read("vscode_daily_traffic")
    df = df.transform(weekly_active_workspaces)
    return df


@dlt.table()
def vscode_weekly_active_customers():
    df: DataFrame
    df = dlt.read("vscode_daily_traffic")
    df = df.transform(weekly_active_customers)
    return df


@dlt.table()
def vscode_customers_usage_first_last():
    df: DataFrame
    df = dlt.read("vscode_daily_traffic")
    df = df.transform(customers_usage_first_last)
    return df
