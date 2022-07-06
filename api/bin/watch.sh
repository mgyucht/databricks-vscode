#!/bin/bash

set -e

DOC_PUBLIC_JSON=~/universe/bazel-bin/api/doc_public.json
DATABRICKS_CLI_REPOSITORY=~/dev/databricks-cli

# Build doc_public.json if it doesn't exist yet.
if [ ! -f $DOC_PUBLIC_JSON ]; then
  (
    cd ~/universe
    bazel build //api:doc_and_sdk
  )
fi

# Generate code and wait for changes in this directory.
while true; do
  (
      echo "Generating code..."
      python3 ./generate.py generate \
        --doc-file $DOC_PUBLIC_JSON \
        --template templates/databricks_cli_python/service.py.jinja2 \
        > ${DATABRICKS_CLI_REPOSITORY}/databricks_cli/sdk/service.py
      cd ${DATABRICKS_CLI_REPOSITORY}/databricks_cli/sdk
      black -S --line-length 100 service.py
  )
  if ! watchman-wait . ; then
    break
  fi
done
