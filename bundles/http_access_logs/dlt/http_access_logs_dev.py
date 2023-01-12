# Databricks notebook source
import dlt
import importer

import pyspark.sql.functions as F
from pyspark.sql import DataFrame


@dlt.view()
def http_access_logs_raw():
    df: DataFrame
    df = spark.readStream.table("prod.http_access_logs")

    # Limit processing to a single day of logs produced 7 days ago.
    return df.filter(df["date"] == F.date_sub(F.current_date(), 7))
