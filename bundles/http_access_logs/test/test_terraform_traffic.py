import pytest

from pyspark.sql import SparkSession
from pyspark.sql.types import StructType, StructField, StringType

from lib.terraform_traffic import TerraformTraffic


@pytest.fixture
def schema():
    return StructType(
        [
            StructField(
                "userAgent",
                StructType([StructField("redactedUserAgent", StringType())]),
            ),
            StructField("path", StringType()),
            StructField("hostname", StringType()),
        ]
    )


@pytest.mark.skip("TODO")
def test_derive_resource(spark: SparkSession, schema):
    df = spark.createDataFrame(
        data=[
            {
                "userAgent": {
                    "redactedUserAgent": "foo",
                },
                "path": "/path",
            },
            # (("foo",), "/path"),
        ],
        schema=schema,
    )

    out = df.withColumn("output", TerraformTraffic(df).derive_resource()).collect()
    assert "bla" == out[0]["output"]


def test_provider_version(spark: SparkSession, schema):
    examples = [
        ("databricks-tf-provider/dev", "0.2.0"),
        ("databricks-tf-provider/0.2.5", "0.2.5"),
        ("databricks-tf-provider/0.3.0 (+cluster) terraform/0.14.4", "0.3.0"),
        ("databricks-tf-provider/0.3.1 (+job) terraform/unknown", "0.3.1"),
        ("databricks-tf-provider/4965f93", "4965f93"),
    ]

    df = spark.createDataFrame(
        data=[
            {
                "userAgent": {
                    "redactedUserAgent": ua[0],
                },
            }
            for ua in examples
        ],
        schema=schema,
    )

    out = df.withColumn("output", TerraformTraffic(df).provider_version()).collect()
    for (row, example) in zip(out, examples):
        assert example[1] == row["output"]


def test_cloud_type(spark: SparkSession, schema):
    examples = [
        ("foo.cloud.databricks.com", "aws"),
        ("adb-123456789.0.azuredatabricks.net", "azure"),
        ("foo.gcp.databricks.com", "gcp"),
        ("invalid.host.com", "unknown"),
    ]

    df = spark.createDataFrame(
        data=[{"hostname": ex[0]} for ex in examples],
        schema=schema,
    )

    out = df.withColumn("output", TerraformTraffic(df).cloud_type()).collect()
    for (row, ex) in zip(out, examples):
        assert ex[1] == row["output"]
