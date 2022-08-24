# eng-dev-ecosystem

See roadmpa for [Python](PYTHON_ROADMAP.md).

# infrastructure

```mermaid
graph TD
    ops -->|cloud roots| environments
    ops -->|per cloud and env| workspaces
    ops -->|shared blocks| modules

    modules --> defaults
    modules --> azure-spn
    modules --> github-secrets

    github-secrets --> |read exposed secrets| key-vaults

    environments --> meta
    environments --> azure
    environments --> gcp
    azure --> workspaces
    gcp --> workspaces

    key-vaults --> meta

    meta -->|power up| github-envs

    github-envs --> .github/workflows

    .github/workflows --> terraform-nightly
    .github/workflows --> terraform-pr

    ext --> terraform-provider
    ext --> docs

    go --> coverage-report
    terraform-provider --> coverage-report
    docs --> coverage-report


    terraform-pr --> coverage-report
    terraform-nightly --> coverage-report
```

Please install https://marketplace.visualstudio.com/items?itemName=bierner.markdown-mermaid and read https://mermaid-js.github.io/mermaid/#/gantt
