# Databricks notebook source
# DBTITLE 1,Make bundle root available for Python imports.

import sys
sys.path.append(spark.conf.get("bundle.filePath"))

# COMMAND ----------

import dlt

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
