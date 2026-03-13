#!/bin/bash
# =============================================================
# check-dead-code.sh
#
# Uses `ts-prune` to find unused exports in the project.
# =============================================================

# ts-prune is the best tool for this job. It's a dev dependency.
if ! command -v ts-prune &> /dev/null
then
    echo "  ⚠️ ts-prune could not be found. Please install it with \`npm install -D ts-prune\`."
    exit 1
fi


# We will run ts-prune and capture the output.
# The `-p tsconfig.json` tells it to use the main tsconfig file.
# We will ignore errors using `|| true` so that we can format the output ourselves.
OUTPUT=$(ts-prune -p tsconfig.json || true)


if [ -z "$OUTPUT" ]; then
  echo "  ✅ No dead code found."
  exit 0
else
  echo "  ❌ Found dead code:"
  echo "$OUTPUT"
  exit 1
fi
