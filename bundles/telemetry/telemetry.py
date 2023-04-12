# Databricks notebook source

import dlt
import pyspark.sql.functions as F

TELEMETRY_PATH = "abfss://am-appevents@decotelemetryexport.dfs.core.windows.net/"


@dlt.table(table_properties={"quality": "bronze"})
def telemetry_raw():
    # Note: "recursiveFileLookup" option is needed. The file name written out by Log Analytics
    # data export uses hive-partitioning to segment different files, but the key used for the
    # month and minute partition is identical ("m"). See
    # https://spark.apache.org/docs/latest/sql-data-sources-generic-options.html#recursive-file-lookup
    # for information about this option.
    return (
        spark.readStream.format("cloudFiles")
        .option("cloudFiles.format", "json")
        .option("recursiveFileLookup", "true")
        .load(TELEMETRY_PATH)
    )


@dlt.table(table_properties={"quality": "bronze"})
def telemetry_parsed():
    return (
        dlt.read("telemetry_raw")
        .withColumn("Measurements", F.from_json("Measurements", "MAP<string, double>"))
        .withColumn("Properties", F.from_json("Properties", "MAP<string, string>"))
        .withColumn(
            "TimeGenerated",
            F.to_timestamp("TimeGenerated", "yyyy-MM-dd'T'HH:mm:ss.SSSSSSSX"),
        )
    )
