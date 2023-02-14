import functools
from typing import Callable

import pyspark.sql.functions as F
from pyspark.sql.types import IntegerType
from pyspark.sql import Column, DataFrame


class UnifiedUserAgent:
    @staticmethod
    def extract_semver_struct(col: Column) -> Column:
        # Regular expression copied from https://semver.org/.
        semver = (
            r"^"
            r"(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)"
            r"(?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?"
            r"(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?"
            r"$"
        )

        major = F.regexp_extract(col, semver, 1).cast(IntegerType())
        minor = F.regexp_extract(col, semver, 2).cast(IntegerType())
        patch = F.regexp_extract(col, semver, 3).cast(IntegerType())
        prerelease = F.regexp_extract(col, semver, 4)
        buildmetadata = F.regexp_extract(col, semver, 5)

        valid = (
            major.isNotNull()
            & minor.isNotNull()
            & patch.isNotNull()
            & prerelease.isNotNull()
            & buildmetadata.isNotNull()
        )

        core = F.when(valid, F.format_string("%d.%d.%d", major, minor, patch))

        return F.struct(
            core.alias("core"),
            major.alias("major"),
            minor.alias("minor"),
            patch.alias("patch"),
            # As optional columns, these are converted to nulls if empty.
            F.when(F.length(prerelease) > 0, prerelease).alias("prerelease"),
            F.when(F.length(buildmetadata) > 0, buildmetadata).alias("buildmetadata"),
            # Capture if the version is valid semver.
            valid.alias("valid"),
            # If the version isn't valid semver, include the original.
            F.when(~valid, col).alias("original"),
        )

    """
    This class turns a string column with a raw user agent into
    a structured column with the user agent broken down
    into its respective components as individual columns.

    For more information, refer to http://go/unified-user-agent.
    """

    def __init__(self, col: Column) -> None:
        self.col = col
        self.chunks = F.split(self.col, r"\s+")

        self.productInfo = F.split(self.chunks[0], "/", 2)
        self.productIdent = self.productInfo[0]
        self.productVersion = self.__class__.extract_semver_struct(self.productInfo[1])

        self.sdkInfo = F.split(self.chunks[1], "/", 2)
        self.sdkIdent = self.sdkInfo[0]
        self.sdkVersion = self.__class__.extract_semver_struct(self.sdkInfo[1])

        self.languageInfo = F.split(self.chunks[2], "/", 2)
        self.languageIdent = self.languageInfo[0]
        self.languageVersion = self.__class__.extract_semver_struct(
            self.languageInfo[1]
        )

        self.osInfo = F.split(self.chunks[3], "/", 2)
        self.osIdent = self.osInfo[0]
        self.osVersion = self.osInfo[1]

        self.otherInfo = F.when(
            F.size(self.chunks) > 4, F.slice(self.chunks, 5, F.size(self.chunks) - 4)
        )
        self.otherInfoWithSplit = F.transform(
            self.otherInfo,
            lambda x: F.struct(
                F.split(x, "/", 2).getItem(0), F.split(x, "/", 2).getItem(1)
            ),
        )
        self.otherInfoMap = F.map_from_entries(self.otherInfoWithSplit)

    def is_valid(self) -> Column:
        alphanum = r"[a-z0-9-_]+"
        language = f"(go|python|js|java|scala|{alphanum})"
        os = f"(darwin|linux|windows|{alphanum})"

        conditions = [
            F.size(self.chunks) >= 4,
            self.productIdent.rlike(f"^{alphanum}$"),
            self.productVersion.valid,
            self.sdkIdent.rlike(f"^databricks-sdk-{language}$"),
            self.sdkVersion.valid,
            self.languageIdent.rlike(f"^{language}$"),
            self.languageVersion.valid,
            self.osIdent == F.lit("os"),
            self.osVersion.rlike(f"^{os}$"),
        ]

        # The unified user agent spec is valid IFF all the patterns
        # specified in http://go/unified-user-agent are matched.
        return functools.reduce(Column.__and__, conditions, F.lit(True))

    def to_column(self) -> Column:
        valid = self.is_valid()

        return F.struct(
            self.productIdent.alias("product"),
            self.productVersion.alias("productVersion"),
            self.sdkIdent.alias("sdk"),
            self.sdkVersion.alias("sdkVersion"),
            self.languageIdent.alias("language"),
            self.languageVersion.alias("languageVersion"),
            # Note: for well formed unified user agent specs this is equal to "os".
            # We still include the column in case this invariant is violated.
            self.osIdent.alias("os"),
            self.osVersion.alias("osVersion"),
            # A map type with key -> value for xyz/1.2.3.
            self.otherInfoMap.alias("otherInfo"),
            # Capture if the user agent is valid per the spec.
            valid.alias("valid"),
            # If the user agent isn't valid per the spec, include the original.
            F.when(~valid, self.col).alias("original"),
        )


def with_unified_user_agent(col: Column) -> Callable[[DataFrame], DataFrame]:
    uua = UnifiedUserAgent(col).to_column()

    def transformation(df: DataFrame) -> DataFrame:
        # We could overwrite the existing column with the unified version
        # but this breaks compatibility with the original table.
        return df.withColumn("unifiedUserAgent", uua)

    return transformation
