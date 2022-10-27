#!/usr/bin/env bash

set -ex

if test -d .bin; then
  echo "Directory .bin found; assuming deco already downloaded"
  exit 0
fi

# Find last successful deco build on main
last_successful_run_id=$(
  gh run list -b main -w deco --json 'databaseId,conclusion' |
      jq 'limit(1; .[] | select(.conclusion == "success")) | .databaseId'
)
if [ -z "$last_successful_run_id" ]; then
  echo "Unable to find last successful build"
  exit 1
fi

gh run download $last_successful_run_id -n deco -D .bin
