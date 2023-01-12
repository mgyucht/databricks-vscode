# Databricks notebook source
import dlt
import importer

import pyspark.sql.functions as F
from pyspark.sql import DataFrame


@dlt.view()
def workload_insights_raw():
    df: DataFrame

    # Note: prod.workload_insights is a permanent view, which is not supported
    # by streaming reading API such as `DataStreamReader.table` yet.
    df = spark.table("prod.workload_insights")

    # Limit processing to a single day of logs produced 7 days ago.
    return df.filter(df["date"] == F.date_sub(F.current_date(), 7))
