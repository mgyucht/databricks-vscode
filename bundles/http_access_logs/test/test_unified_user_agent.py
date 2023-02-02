from pyspark.sql import SparkSession

from lib.unified_user_agent import UnifiedUserAgent


def test_nominal(spark: SparkSession):
    ua = (
        "terraform-provider-databricks/1.5.2 databricks-sdk-go/0.1.3 go/1.18.3 os/darwin "
        "resource/metastore_assignment terraform/1.2.5 pulumi/3.7.2"
    )

    df = spark.createDataFrame(data=[{"userAgent": ua}])
    out = df.withColumn("ua", UnifiedUserAgent(df["userAgent"]).to_column()).collect()

    expected = {
        "product": "terraform-provider-databricks",
        "productVersion": "1.5.2",
        "sdk": "databricks-sdk-go",
        "sdkVersion": "0.1.3",
        "language": "go",
        "languageVersion": "1.18.3",
        "os": "os",
        "osVersion": "darwin",
        "otherInfo": {
            "pulumi": "3.7.2",
            "resource": "metastore_assignment",
            "terraform": "1.2.5",
        },
        "valid": True,
        "original": ua,
    }

    assert out[0]["ua"].asDict() == expected


def test_no_other_info(spark: SparkSession):
    ua = "terraform-provider-databricks/1.5.2 databricks-sdk-go/0.1.3 go/1.18.3 os/darwin"
    df = spark.createDataFrame(data=[{"userAgent": ua}])
    out = df.withColumn("ua", UnifiedUserAgent(df["userAgent"]).to_column()).collect()

    expected = {
        "product": "terraform-provider-databricks",
        "productVersion": "1.5.2",
        "sdk": "databricks-sdk-go",
        "sdkVersion": "0.1.3",
        "language": "go",
        "languageVersion": "1.18.3",
        "os": "os",
        "osVersion": "darwin",
        "otherInfo": None,
        "valid": True,
        "original": ua,
    }

    assert out[0]["ua"].asDict() == expected


def test_old_school_terraform(spark: SparkSession):
    ua = "databricks-tf-provider/0.3.0 (+dbfs_file) terraform/0.14.6"
    df = spark.createDataFrame(data=[{"userAgent": ua}])
    out = df.withColumn("ua", UnifiedUserAgent(df["userAgent"]).to_column()).collect()

    expected = {
        "product": "databricks-tf-provider",
        "productVersion": "0.3.0",
        "sdk": "(+dbfs_file)",
        "sdkVersion": None,
        "language": "terraform",
        "languageVersion": "0.14.6",
        "os": None,
        "osVersion": None,
        "otherInfo": None,
        "valid": False,
        "original": ua,
    }

    assert out[0]["ua"].asDict() == expected

def test_semver(spark: SparkSession):
    ua = "bricks/0.0.21-dev+65020f3 databricks-sdk-go/0.2.0 go/1.19.4 os/darwin cmd/sync auth/pat"
    df = spark.createDataFrame(data=[{"userAgent": ua}])
    out = df.withColumn("ua", UnifiedUserAgent(df["userAgent"]).to_column()).collect()

    expected = {
        "product": "bricks",
        "productVersion": "0.0.21-dev+65020f3",
        "sdk": "databricks-sdk-go",
        "sdkVersion": "0.2.0",
        "language": "go",
        "languageVersion": "1.19.4",
        "os": "os",
        "osVersion": "darwin",
        "otherInfo": {
            "cmd": "sync",
            "auth": "pat",
        },
        "valid": True,
        "original": ua,
    }

    assert out[0]["ua"].asDict() == expected
