# Databricks notebook source
# DBTITLE 1,Delete historical data from telemetry_raw table

catalog = dbutils.widgets.get("catalog")
schema = dbutils.widgets.get("schema")
spark.sql(
    f"""DELETE FROM {catalog}.{schema}.telemetry_raw WHERE TimeGenerated <= date_sub(now(), 3 * 365)"""
)
