import functools
from typing import Callable

import pyspark.sql.functions as F
from pyspark.sql import Column, DataFrame


class UnifiedUserAgent:
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
        self.productVersion = self.productInfo[1]

        self.sdkInfo = F.split(self.chunks[1], "/", 2)
        self.sdkIdent = self.sdkInfo[0]
        self.sdkVersion = self.sdkInfo[1]

        self.languageInfo = F.split(self.chunks[2], "/", 2)
        self.languageIdent = self.languageInfo[0]
        self.languageVersion = self.languageInfo[1]

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

        # Regular expression copied from https://semver.org/.
        semver = (
            r"^"
            r"(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)"
            r"(?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?"
            r"(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?"
            r"$"
        )

        language = f"(go|python|js|java|scala|{alphanum})"
        os = f"(darwin|linux|windows|{alphanum})"

        conditions = [
            F.size(self.chunks) >= 4,
            self.productIdent.rlike(f"^{alphanum}$"),
            self.productVersion.rlike(semver),
            self.sdkIdent.rlike(f"^databricks-sdk-{language}$"),
            self.sdkVersion.rlike(semver),
            self.languageIdent.rlike(f"^{language}$"),
            self.languageVersion.rlike(semver),
            self.osIdent == F.lit("os"),
            self.osVersion.rlike(f"^{os}$"),
        ]

        # The unified user agent spec is valid IFF all the patterns
        # specified in http://go/unified-user-agent are matched.
        return functools.reduce(Column.__and__, conditions, F.lit(True))

    def to_column(self) -> Column:
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
            # A boolean that tells us if the spec is well formed or not.
            self.is_valid().alias("valid"),
            # Include the original full spec for debugging purposes.
            self.col.alias("original"),
        )


def with_unified_user_agent(col: Column) -> Callable[[DataFrame], DataFrame]:
    uua = UnifiedUserAgent(col).to_column()

    def transformation(df: DataFrame) -> DataFrame:
        # We could overwrite the existing column with the unified version
        # but this breaks compatibility with the original table.
        return df.withColumn("unifiedUserAgent", uua)

    return transformation
