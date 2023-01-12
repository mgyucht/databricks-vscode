# Databricks notebook source
import dlt
import importer

from pyspark.sql import DataFrame


@dlt.view()
def workload_insights_raw():
    df: DataFrame

    # Note: prod.workload_insights is a permanent view, which is not supported
    # by streaming reading API such as `DataStreamReader.table` yet.
    df = spark.table("prod.workload_insights")
    df = df.filter(df["date"] >= "2022-11-01")
    return df
