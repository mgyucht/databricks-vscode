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
        "productVersion": {
            "core": "1.5.2",
            "major": 1,
            "minor": 5,
            "patch": 2,
            "prerelease": None,
            "buildmetadata": None,
            "valid": True,
            "original": None,
        },
        "sdk": "databricks-sdk-go",
        "sdkVersion": {
            "core": "0.1.3",
            "major": 0,
            "minor": 1,
            "patch": 3,
            "prerelease": None,
            "buildmetadata": None,
            "valid": True,
            "original": None,
        },
        "language": "go",
        "languageVersion": {
            "core": "1.18.3",
            "major": 1,
            "minor": 18,
            "patch": 3,
            "prerelease": None,
            "buildmetadata": None,
            "valid": True,
            "original": None,
        },
        "os": "os",
        "osVersion": "darwin",
        "otherInfo": {
            "pulumi": "3.7.2",
            "resource": "metastore_assignment",
            "terraform": "1.2.5",
        },
        "valid": True,
        "original": None,
    }

    assert out[0]["ua"].asDict(recursive=True) == expected


def test_no_other_info(spark: SparkSession):
    ua = "terraform-provider-databricks/1.5.2 databricks-sdk-go/0.1.3 go/1.18.3 os/darwin"
    df = spark.createDataFrame(data=[{"userAgent": ua}])
    out = df.withColumn("ua", UnifiedUserAgent(df["userAgent"]).to_column()).collect()

    expected = {
        "product": "terraform-provider-databricks",
        "productVersion": {
            "core": "1.5.2",
            "major": 1,
            "minor": 5,
            "patch": 2,
            "prerelease": None,
            "buildmetadata": None,
            "valid": True,
            "original": None,
        },
        "sdk": "databricks-sdk-go",
        "sdkVersion": {
            "core": "0.1.3",
            "major": 0,
            "minor": 1,
            "patch": 3,
            "prerelease": None,
            "buildmetadata": None,
            "valid": True,
            "original": None,
        },
        "language": "go",
        "languageVersion": {
            "core": "1.18.3",
            "major": 1,
            "minor": 18,
            "patch": 3,
            "prerelease": None,
            "buildmetadata": None,
            "valid": True,
            "original": None,
        },
        "os": "os",
        "osVersion": "darwin",
        "otherInfo": None,
        "valid": True,
        "original": None,
    }

    assert out[0]["ua"].asDict(recursive=True) == expected


def test_old_school_terraform(spark: SparkSession):
    ua = "databricks-tf-provider/0.3.0 (+dbfs_file) terraform/0.14.6"
    df = spark.createDataFrame(data=[{"userAgent": ua}])
    out = df.withColumn("ua", UnifiedUserAgent(df["userAgent"]).to_column()).collect()

    expected = {
        "product": "databricks-tf-provider",
        "productVersion": {
            "core": "0.3.0",
            "major": 0,
            "minor": 3,
            "patch": 0,
            "prerelease": None,
            "buildmetadata": None,
            "valid": True,
            "original": None,
        },
        "sdk": "(+dbfs_file)",
        "sdkVersion": {
            "core": None,
            "major": None,
            "minor": None,
            "patch": None,
            "prerelease": None,
            "buildmetadata": None,
            "valid": False,
            "original": None,
        },
        "language": "terraform",
        "languageVersion": {
            "core": "0.14.6",
            "major": 0,
            "minor": 14,
            "patch": 6,
            "prerelease": None,
            "buildmetadata": None,
            "valid": True,
            "original": None,
        },
        "os": None,
        "osVersion": None,
        "otherInfo": None,
        "valid": False,
        "original": ua,
    }

    assert out[0]["ua"].asDict(recursive=True) == expected


def test_semver(spark: SparkSession):
    ua = "bricks/0.0.21-dev+65020f3 databricks-sdk-go/0.2.0 go/1.19.4 os/darwin cmd/sync auth/pat"
    df = spark.createDataFrame(data=[{"userAgent": ua}])
    out = df.withColumn("ua", UnifiedUserAgent(df["userAgent"]).to_column()).collect()

    expected = {
        "product": "bricks",
        "productVersion": {
            "core": "0.0.21",
            "major": 0,
            "minor": 0,
            "patch": 21,
            "prerelease": "dev",
            "buildmetadata": "65020f3",
            "valid": True,
            "original": None,
        },
        "sdk": "databricks-sdk-go",
        "sdkVersion": {
            "core": "0.2.0",
            "major": 0,
            "minor": 2,
            "patch": 0,
            "prerelease": None,
            "buildmetadata": None,
            "valid": True,
            "original": None,
        },
        "language": "go",
        "languageVersion": {
            "core": "1.19.4",
            "major": 1,
            "minor": 19,
            "patch": 4,
            "prerelease": None,
            "buildmetadata": None,
            "valid": True,
            "original": None,
        },
        "os": "os",
        "osVersion": "darwin",
        "otherInfo": {
            "cmd": "sync",
            "auth": "pat",
        },
        "valid": True,
        "original": None,
    }

    assert out[0]["ua"].asDict(recursive=True) == expected


def test_invalid_semver(spark: SparkSession):
    ua = "bad/0.1-foo+bar databricks-sdk-go/0.2.0 go/1.19.4 os/darwin"
    df = spark.createDataFrame(data=[{"userAgent": ua}])
    out = df.withColumn("ua", UnifiedUserAgent(df["userAgent"]).to_column()).collect()

    expected = {
        "product": "bad",
        "productVersion": {
            "core": None,
            "major": None,
            "minor": None,
            "patch": None,
            "prerelease": None,
            "buildmetadata": None,
            "valid": False,
            "original": "0.1-foo+bar",
        },
        "sdk": "databricks-sdk-go",
        "sdkVersion": {
            "core": "0.2.0",
            "major": 0,
            "minor": 2,
            "patch": 0,
            "prerelease": None,
            "buildmetadata": None,
            "valid": True,
            "original": None,
        },
        "language": "go",
        "languageVersion": {
            "core": "1.19.4",
            "major": 1,
            "minor": 19,
            "patch": 4,
            "prerelease": None,
            "buildmetadata": None,
            "valid": True,
            "original": None,
        },
        "os": "os",
        "osVersion": "darwin",
        "otherInfo": None,
        "valid": False,
        "original": ua,
    }

    assert out[0]["ua"].asDict(recursive=True) == expected
