# Databricks notebook source
import dlt
import importer

from pyspark.sql import DataFrame

from lib.terraform_traffic import *


@dlt.table(
    partition_cols=["date"],
)
def terraform_traffic():
    df: DataFrame
    df = dlt.read_stream("http_access_logs")
    df = df.transform(TerraformTraffic.transform)
    return df
