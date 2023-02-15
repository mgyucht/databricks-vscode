import pyspark.sql.functions as F
from pyspark.sql.types import IntegerType
from pyspark.sql import DataFrame


def filter_original_user_agent(df: DataFrame) -> DataFrame:
    return df.filter(df["unifiedUserAgent.original"].like("databricks-cli-%"))


def include_user_agent_info(df: DataFrame) -> DataFrame:
    # The user agent in https://github.com/databricks/databricks-cli is not
    # a valid per the spec, so the `original` column is always populated.
    split = F.split(df["unifiedUserAgent.original"], "-", 4)
    version = split[2]
    versionParts = F.split(version, r"\.", 3)
    versionMajor = versionParts[0].cast(IntegerType())
    versionMinor = versionParts[1].cast(IntegerType())
    suffix = split[3]

    df = df.withColumn("productVersion", version)
    df = df.withColumn("productVersionMajor", versionMajor)
    df = df.withColumn("productVersionMinor", versionMinor)

    # See https://github.com/databricks/databricks-cli/pull/132
    # This was released as part of 0.8.0.
    hasCommandInUserAgent = (versionMajor == 0) & (versionMinor >= 8)
    uuidRegexp = r"[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}"

    # If this was a CLI call, we'll have a list of command chunks.
    # Given databricks-cli-0.17.3-runs-get-b43b2376-8a6b-11ed-a062-0a7d5859c938, this becomes `runs-get`.
    df = df.withColumn(
        "command",
        F.when(
            hasCommandInUserAgent,
            F.regexp_extract(suffix, r"^(\w+(-\w+)+)-" + uuidRegexp + r"$", 1),
        ),
    )

    # Turn empty string into null.
    df = df.withColumn(
        "command",
        F.when(F.length(df["command"]) > 0, df["command"]).otherwise(F.lit(None)),
    )

    # Emit if we assume this is an SDK call
    df = df.withColumn("sdk", df["command"].isNull())

    # Select columns we care about.
    df = df.select(
        "timestamp",
        # Primary dimensions we care about.
        "productVersion",
        "productVersionMajor",
        "productVersionMinor",
        "command",
        "sdk",
        "workspaceId",
        "accountId",
        "method",
        "canonicalPath",
        "status",
        # Everything else.
        "hostname",
        "remoteAddrAnon",
        "internalReq",
        "requestProtocol",
        "requestBodyLength",
        "respBodyLength",
        # Partition by date.
        "date",
    )

    return df


def http_access_logs(df: DataFrame) -> DataFrame:
    return df.transform(filter_original_user_agent).transform(include_user_agent_info)
