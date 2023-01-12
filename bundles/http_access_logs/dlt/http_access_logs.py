# Databricks notebook source
import dlt
import importer

from pyspark.sql import DataFrame

from lib.http_access_logs import transform_http_access_logs


@dlt.table(
    partition_cols=["date"],
)
def http_access_logs():
    df: DataFrame
    df = dlt.read_stream("http_access_logs_raw")
    df = df.transform(transform_http_access_logs)
    return df
