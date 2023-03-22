# Databricks notebook source
# DBTITLE 1,Make bundle root available for Python imports.

import sys
sys.path.append(spark.conf.get("bundle.filePath"))

# COMMAND ----------

import dlt

import pyspark.sql.functions as F
from pyspark.sql import DataFrame


@dlt.view()
def http_access_logs_raw():
    df: DataFrame
    df = spark.readStream.option("ignoreChanges", "true").table("prod.http_access_logs")

    # Limit processing to a single day of logs produced 7 days ago.
    return df.filter(df["date"] == F.date_sub(F.current_date(), 7))
