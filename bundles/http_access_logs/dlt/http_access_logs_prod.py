# Databricks notebook source
# DBTITLE 1,Make bundle root available for Python imports.

import sys
sys.path.append(spark.conf.get("bundle.filePath"))

# COMMAND ----------

import dlt

from pyspark.sql import DataFrame


@dlt.view()
def http_access_logs_raw():
    df: DataFrame
    df = spark.readStream.table("prod.http_access_logs")
    df = df.filter(df["date"] >= "2021-01-01")
    return df
