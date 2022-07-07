#!/bin/bash

set -e

DOC_PUBLIC_JSON=~/universe/bazel-bin/api/doc_public.json
DATABRICKS_VSCODE_REPOSITORY=~/dev/databricks-vscode

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
        --template templates/databricks-sdk-js \
        --output ${DATABRICKS_VSCODE_REPOSITORY}/packages/databricks-sdk-js/src/apis
      cd ${DATABRICKS_VSCODE_REPOSITORY}
      node_modules/.bin/prettier -w packages/databricks-sdk-js/src/apis/*.ts
  ) || true
  if ! watchman-wait . ; then
    break
  fi
done
