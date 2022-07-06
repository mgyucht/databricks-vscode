#!/bin/env python3
# %pip install ghapi --user

from ghapi.all import GhApi
import urllib, json

OWNER = 'databricks'
REPO = 'terraform-provider-databricks'

gh = GhApi(owner=OWNER, repo=REPO)
last_release = gh.list_tags()[-1]['ref']
compare_url = gh.repos.get().compare_url.format(base=last_release, head='master')
compare_response = urllib.request.urlopen(compare_url)
compare_json = json.load(compare_response)

import re
messages = sorted([c['commit']['message'].split("\n")[0] for c in compare_json['commits']])
for m in messages:
    m = re.sub(r"#(\d+)", '[#\\1](https://github.com/'+OWNER+'/'+REPO+'/pull/\\1)', m)
    print(f'* {m}.')