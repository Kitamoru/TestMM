#!/bin/bash
# =============================================================
# check-typescript-strict.sh
#
# Checks that TypeScript's `strict` mode is enabled in `tsconfig.json`.
# =============================================================

TSCONFIG="tsconfig.json"

if [ ! -f "$TSCONFIG" ]; then
  echo "  ⚠️  $TSCONFIG not found, skipping."
  exit 0
fi

# We will use grep to check for the strict flag.
# We are looking for a line that contains "strict" followed by true.
# We will remove spaces to make the check more robust.
# The `tr -d '[:space:]'` command removes all whitespace.
# The `grep -q` command searches quietly.
if grep -q '"strict":true' <(tr -d '[:space:]' < "$TSCONFIG"); then
  echo "  ✅ TypeScript strict mode is enabled."
  exit 0
else
  echo "  ❌ TypeScript strict mode is not enabled in $TSCONFIG."
  echo "     Please add or set '"strict": true' in your compilerOptions."
  exit 1
fi
