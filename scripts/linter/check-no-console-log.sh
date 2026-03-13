#!/bin/bash
# =============================================================
# check-no-console-log.sh
#
# Checks for `console.log` statements in the `src` directory.
# Ignores lines that are commented out.
# =============================================================

SRC_DIR="src"

if [ ! -d "$SRC_DIR" ]; then
  echo "  ⚠️  Directory $SRC_DIR not found, skipping."
  exit 0
fi

# We use grep to find all lines containing console.log, then we pipe this
# to another grep to filter out the lines that are commented out.
# `grep -r "console.log" $SRC_DIR` gives us `filename:line:content`
# `grep -v -E "^[[:space:]]*//"` filters out lines starting with `//`
# `cut -d: -f1` extracts the filename
# `sort -u` gets the unique filenames
VIOLATIONS=$(grep -r "console.log" $SRC_DIR | grep -v -E "^[^:]+:[0-9]+:[[:space:]]*//" | cut -d: -f1 | sort -u)


if [ -z "$VIOLATIONS" ]; then
  echo "  ✅ No console.log statements found in production code."
  exit 0
else
  echo "  ❌ Found console.log statements in the following files:"
  # This will print each filename on a new line
  echo "$VIOLATIONS" | while read -r file; do
    echo "     - $file"
  done
  echo ""
  echo "  ❗ Please remove them or comment them out."
  exit 1
fi
