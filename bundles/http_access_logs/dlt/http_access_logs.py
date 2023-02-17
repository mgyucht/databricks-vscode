# Databricks notebook source
import dlt
import importer

from pyspark.sql import DataFrame

from lib.http_access_logs import transform_http_access_logs, join_with_canonical_customer_name


@dlt.table(
    partition_cols=["date"],
    table_properties={
        "pipelines.autoOptimize.zOrderCols": "workspaceId",
    },
)
def http_access_logs():
    df: DataFrame
    df = dlt.read_stream("http_access_logs_raw")
    df = df.transform(transform_http_access_logs)
    return df


@dlt.table(
    partition_cols=["date"],
    table_properties={
        "pipelines.autoOptimize.zOrderCols": "workspaceId",
    },
)
def http_access_logs_with_customer_name():
    df: DataFrame
    df = dlt.read_stream("http_access_logs")
    df = df.transform(join_with_canonical_customer_name)
    return df
