# Databricks notebook source
import dlt
import importer

from pyspark.sql import DataFrame
import pyspark.sql.functions as F

from lib.unified_user_agent import with_unified_user_agent


@dlt.table(
    partition_cols=["date"],
)
def workload_insights():
    df: DataFrame
    df = dlt.read("workload_insights_raw")
    df = df.transform(with_unified_user_agent(df["workloadTags"]["userAgentRaw"]))
    df = df.filter(df["unifiedUserAgent.valid"] == F.lit(True))
    return df
