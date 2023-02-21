# http access logs

ETL for HTTP access logs relevant to the Developer Ecosystem team.

## How to test?

```sh
pip3 install -r ./requirements.txt
python3 -m pytest ./test
```

## How to deploy a development copy?

1. Ensure you have an auth profile called `logfood-master`, or modify the profile in `bundle.yml`.
2. Modify `target: "deco_development"` in `pipeline.yml` to `deco_development_<YOURNAME>`.
3. Run `bricks bundle deploy`.
4. Run `bricks bundle run deco_access_logs`.
5. Profit!

## How to deploy to THE production copy?

Send Pieter a DM on Slack. Sorry. We don't have an SP to manage this yet.
