#!/bin/env python3

import os, sys
from ghapi.all import GhApi

pull_request_number = sys.argv[1]
repo = sys.argv[2] if len(sys.argv) == 3 else "terraform-provider-databricks"
print(f'INFO: Looking for PR#{pull_request_number} in repo {repo}')

OWNER = 'databricks'

try:
    gh = GhApi(owner=OWNER, repo=repo)
    pr = gh.pulls.get(pull_request_number)
    
    ref = pr['head']['ref']
    clone_url = pr['head']['repo']['clone_url']

    command = f'git clone {clone_url} --branch {ref} ext/terraform-provider-databricks'
    print(f'INFO: Checking out PR for the build: {command}')
    print(os.system(command))
except Exception as e:
    sys.stderr.write(f'::error:{e}')
    sys.exit(1)