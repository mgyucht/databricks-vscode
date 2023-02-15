import pyspark.sql.functions as F
from pyspark.sql import DataFrame

from .unified_user_agent import with_unified_user_agent


def filter_on_user_agent(df: DataFrame) -> DataFrame:
    df = df.filter(df["userAgent.agentClass"] == F.lit("Other"))

    # This list was manually compiled by doing a count by prefixes (split on '/' or space)
    # on data for a single day and listing the top N that look not relevant.
    patterns = [
        r"(AHC/.*)",
        r"(Amazon Simple Notification Service Agent)",
        r"(Amazon-Route53-Health-Check-Service .*)",
        r"(APN/.*)",
        r"(AtlanCatalog)",
        r"(Azure Traffic Manager Endpoint Monitor)",
        r"(azure-logic-apps/.*)",
        r"(AzureDataFactory DataFlow)",
        r"(AzureDataFactory-DeltaLake)",
        r"(AzureDataFactory)",
        r"(azureml-mlflow/.*)",
        r"(CData Data Provider Engine .*)",
        r"(Commerce Cloud Digital Script HTTP Client .*)",
        r"(Compute-Gateway \(client\))",
        r"(Consul Health Check)",
        r"(Databricks Periodic Health Check)",
        r"(DatabricksDatabricksJDBCDriver/.*)",
        r"(Datadog/.*)",
        r"(Dataiku/DSS)",
        r"(Deepiq)",
        r"(Edge Health Probe)",
        r"(ELB-HealthChecker/.*)",
        r"(emergency-use-case)",
        r"(Faraday v.*)",
        r"(feast_spark)",
        r"(feroxbuster/.*)",
        r"(fivetran.*)",
        r"(Fuzz Faster U Fool .*)",
        r"(Getsafe NXT InsuranceService .*)",
        r"(GGG)",
        r"(Immuta)",
        r"(Informatica(\s.*)?)",
        r"(infoworks\.io)",
        r"(infrastructure_monitor)",
        r"(Java/.*)",
        r"(Jetty/.*)",
        r"(KNIME/.*)",
        r"(Ktor client)",
        r"(Manticore .*)",
        r"(Microsoft\.Data\.Mashup .*)",
        r"(MicrosoftSparkODBCDriver/.*)",
        r"(MicroStrategySparkODBCDriver/.*)",
        r"(mlflow-java-client/.*)",
        r"(mlflow-python-client/.*)",
        r"(MonteCarlo\+ObservabilityPlatform/.*)",
        r"(Mozilla/.*)",
        r"(NGINX-Prometheus-Exporter/.*)",
        r"(Nuclei .*)",
        r"(Privacera-PolicySync/.*)",
        r"(Prometheus/.*)",
        r"(Python/.*)",
        r"(QlikSparkODBCDriver/.*)",
        r"(RewardStyle/.*)",
        r"(SAS_InDB/.*)",
        r"(Scalyr-monitor; .*)",
        r"(sentry/.*)",
        r"(SimbaSparkJDBCDriver/.*)",
        r"(SimbaSparkODBCDriver/.*)",
        r"(Site24x7)",
        r"(Snaplogic eXtreme)",
        r"(soha-health-check)",
        r"(streamsets)",
        r"(Thrift/.*)",
        r"(Trifacta)",
        r"(WANdiscoLiveDataMigrator/.*)",
        r"(YourBugBountyFriend)",
        r"(zmon-worker/.*)",
        # Internal agents.
        r"(kube-probe/.*)",
        r"(wsfs/.*)",
        r"(wsfsbackend/.*)",
        r"(wsfslibrary/.*)",
        r"(armeria/.*)",
    ]

    # Compile patterns into single regexp.
    regexp = r"^" + "|".join(patterns) + r"$"

    # Filters out the rows we don't care about (the vast majority).
    return df.filter(~df["userAgent.redactedUserAgent"].rlike(regexp))


def include_account_id(df: DataFrame) -> DataFrame:
    # The account ID is part of the unredacted path.
    # We only keep the canonical path around so we extract the account ID here.
    accountId = F.regexp_extract(
        df["path"], r"^/api/\d+.\d+/accounts/(\w+-\w+-\w+-\w+-\w+)/", 1
    )
    return df.withColumn("accountId", F.when(F.length(accountId) > 0, accountId))


def filter_http_access_logs(df: DataFrame) -> DataFrame:
    # Select columns we care about.
    # See https://docs.google.com/document/d/1LbPJjDCTnGWPqqI7BKwR3TtWcD7_OiwnpD7TL0Aay8E/edit#
    df = df.select(
        "timestamp",
        # Primary dimensions we care about.
        "workspaceId",
        "accountId",
        "method",
        "canonicalPath",
        "status",
        "unifiedUserAgent",
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


def transform_http_access_logs(df: DataFrame) -> DataFrame:
    df = df.transform(filter_on_user_agent)
    df = df.transform(include_account_id)
    df = df.transform(with_unified_user_agent(df["userAgent.redactedUserAgent"]))
    df = df.transform(filter_http_access_logs)
    return df
