''' Turn all secrets in the current GitHub Actions Environment to uppercased environment variables

USAGE: 
    
    python3 scripts/tfit-env.py ${{ inputs.environment }} '${{ toJson(secrets) }}' >> $GITHUB_ENV

Docs: https://docs.github.com/en/actions/using-workflows/workflow-commands-for-github-actions#setting-an-environment-variable
'''
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
    print(f'{k.upper()}={v}')