#!/bin/env python3

import os, sys
from ghapi.all import GhApi

pull_request_number = sys.argv[1]
print(f'::notice:Looking for PR#{pull_request_number}')

OWNER = 'databricks'
REPO = 'terraform-provider-databricks'

try:
    gh = GhApi(owner=OWNER, repo=REPO)
    pr = gh.pulls.get(pull_request_number)
    
    ref = pr['head']['ref']
    clone_url = pr['head']['repo']['clone_url']

    command = f'git clone {clone_url} --branch {ref} ext/terraform-provider-databricks'
    print(f'::notice:Checking out PR for the build: {command}')
    print(os.system(command))
except Exception as e:
    sys.stderr.write(f'::error:{e}')
    sys.exit(1)