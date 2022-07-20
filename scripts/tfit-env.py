''' Turn all secrets in the current GitHub Actions Environment to uppercased environment variables

USAGE: 
    
    python3 scripts/tfit-env.py ${{ inputs.environment }} '${{ toJson(secrets) }}' >> $GITHUB_ENV

Docs: https://docs.github.com/en/actions/using-workflows/workflow-commands-for-github-actions#setting-an-environment-variable
'''
import base64
import json, sys

env = sys.argv[1]
secrets = sys.argv[2]

print(f'CLOUD_ENV={env.split("-")[0]}')
for k,v in json.loads(secrets).items():
    if k == 'github_token':
        # this is an internal token for github actions.
        # skipping it to avoid potential confusion.
        # perhaps it might be useful in some cases.
        continue
    if k == 'GOOGLE_CREDENTIALS':
        # ops/environments/gcp-prod/gcp-accounts-prod.tf sets it in base64,
        # otherwise github actions may fail with JSON serialisation issues.
        # See https://github.com/databricks/eng-dev-ecosystem/runs/7435656698
        v = base64.b64decode(v)
    print(f'{k.upper()}={v}')