# Roadmap for Python

```mermaid
gantt
    dateFormat  YYYY-MM-DD
    title       Python SDK migration
    excludes    weekends

    section Python SDK
    Legacy Layer (v0.1):        legacy-layer, 2022-11-01, 2w
    SDK client (v0.2):          sdk-client, after sdk-switch, 2w
    AAD auth (v0.3):            aad-auth, after sdk-bump1, 2w
    Public Preview (v0.4):      sdk-public-preview, after aad-cli, 1w

    section Python CLI
    Use SDK (v0.19):            sdk-switch, after legacy-layer, 3d
    Update SDK (v0.20):         sdk-bump1, after sdk-client, 3d
    AAD on CLI (v0.21):         aad-cli, after aad-auth, 3d

    section MLflow
    Use SDK:                    mlflow-on-sdk, after sdk-public-preview, 2w
```

## Current State

```mermaid
graph TD
    subgraph Python CLI
        PAT -.-> ApiClient
        Basic -.-> ApiClient
        DbOauth -.-> ApiClient
        ApiClient --> Services
        Services --> CLI
    end

    ApiClient --> MLflow

    ApiClient --> DBX
    Services -.-> DBX

    ApiClient --> UnofficialSDK
    Services -.-> UnofficialSDK
```

## Python SDK v0.1, Databricks CLI v0.18.x

Essentially a copy of Python CLI as Legacy Layer.

If we remove hackathon-stability `DbOauth` from Python CLI for couple of months, we could simplify the effort.

```mermaid
graph TD
    subgraph Python SDK
        subgraph LegacyLayer
            PAT -.-> ApiClient
            Basic -.-> ApiClient
            DbOauth -.-> ApiClient
            ApiClient
        end
    end

    ApiClient --> MLflow

    subgraph Python CLI
        ApiClient --> Services
        Services --> CLI
    end
    
    ApiClient --> DBX
    Services -.-> DBX

    ApiClient --> UnofficialSDK
    Services -.-> UnofficialSDK
```

## Python SDK v0.2, Databricks CLI v0.19.x

```mermaid
graph TD
    subgraph Python SDK
        PAT -.-> UnifiedAuth
        Basic -.-> UnifiedAuth
        DbOauth -.-> UnifiedAuth

        UnifiedAuth --> SdkClient
        SdkClient --> ApiClient

        subgraph LegacyLayer
            ApiClient
        end
    end


    ApiClient --> MLflow

    subgraph Python CLI
        ApiClient --> Services
        Services --> CLI
    end
    
    ApiClient --> DBX
    Services -.-> DBX

    ApiClient --> UnofficialSDK
    Services -.-> UnofficialSDK
```

## End Goal

```mermaid
graph TD
    subgraph Python SDK
        PAT -.-> UnifiedAuth
        Basic -.-> UnifiedAuth
        AAD -.-> UnifiedAuth
        Google -.-> UnifiedAuth
        DbOauth -.-> UnifiedAuth
        UnifiedAuth --> SdkClient

        SdkClient --> ApiClient

        subgraph LegacyLayer
            ApiClient
        end
    end

    SdkClient --> MLflow

    subgraph Deprecated
        subgraph Python CLI
            ApiClient --> Services
            Services --> CLI
        end
        
        ApiClient --> DBX
        Services -.-> DBX

        ApiClient --> UnofficialSDK
        Services -.-> UnofficialSDK
    end
```
