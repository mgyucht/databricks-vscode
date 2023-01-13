import json
import os

from pyspark.sql import SparkSession, DataFrame


def load_fixture(spark: SparkSession, relativePath: str) -> DataFrame:
    path = os.path.join(os.path.dirname(__file__), relativePath)
    with open(path) as f:
        return spark.createDataFrame(data=json.load(f))
