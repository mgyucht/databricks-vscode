#!/usr/bin/env python3
#
# Transform TF output of this module to CSV so we can share it.
#
# Usage:
#
#   terraform output -json | python3 ./transform_output_to_csv.py
#

import csv
import json
import sys

obj = json.load(sys.stdin)

out = []
for key, value in obj["details"]["value"].items():
    out.append({
        "email": key,
        **value,
    })

sorted(out, key=lambda x: x['email'])

keys = out[0].keys()
write = csv.DictWriter(sys.stdout, keys)
write.writeheader()
write.writerows(out)
