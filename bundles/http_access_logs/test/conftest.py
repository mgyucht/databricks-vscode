import json
import os
import pytest
import warnings

from pyspark.sql import SparkSession, DataFrame


def load_fixture(spark: SparkSession, relativePath: str) -> DataFrame:
    path = os.path.join(os.path.dirname(__file__), relativePath)
    with open(path) as f:
        return spark.createDataFrame(data=json.load(f))


@pytest.fixture
def spark(monkeypatch):
    # Ignore warnings caused by PySpark to keep the output clean.
    warnings.filterwarnings("ignore", category=ResourceWarning)
    warnings.filterwarnings("ignore", category=DeprecationWarning)

    spark = SparkSession.builder.getOrCreate()

    def mock_table(name=""):
        if name == "prod.workspaces":
            return load_fixture(spark, "./fixtures/workspaces.json")
        raise RuntimeError(f"no fixture for {name}")

    monkeypatch.setattr(spark, "table", mock_table)
    return spark
