import pytest
import warnings

from pyspark.sql import SparkSession

from fixtures import load_fixture


@pytest.fixture
def spark(monkeypatch):
    # Ignore warnings caused by PySpark to keep the output clean.
    warnings.filterwarnings("ignore", category=ResourceWarning)
    warnings.filterwarnings("ignore", category=DeprecationWarning)

    spark = SparkSession.builder.getOrCreate()

    def mock_table(name=""):
        if name == "prod.workspaces":
            return load_fixture(spark, "workspaces.json")
        raise RuntimeError(f"no fixture for {name}")

    monkeypatch.setattr(spark, "table", mock_table)
    return spark
