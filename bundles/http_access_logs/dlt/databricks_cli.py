# Databricks notebook source
import dlt
import importer

from pyspark.sql import DataFrame

from lib.databricks_cli import (
    http_access_logs,
)


@dlt.table(
    partition_cols=["date"],
)
def databricks_cli_http_access_logs():
    df: DataFrame
    df = dlt.read_stream("http_access_logs")
    df = df.transform(http_access_logs)
    return df
