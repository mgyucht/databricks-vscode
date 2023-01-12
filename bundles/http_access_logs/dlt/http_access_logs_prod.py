# Databricks notebook source
import dlt
import importer

from pyspark.sql import DataFrame


@dlt.view()
def http_access_logs_raw():
    df: DataFrame
    df = spark.readStream.table("prod.http_access_logs")
    df = df.filter(df["date"] >= "2021-01-01")
    return df
