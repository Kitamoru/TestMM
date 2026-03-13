#!/bin/bash
# =============================================================
# check-telegram-auth.sh
#
# Ensures that API routes that seem to be using Telegram authentication
# are using the centralized `lib/telegramAuth.ts` module.
#
# Heuristic:
# - If a file in `src/pages/api` mentions "Telegram" or "initData",
# - It MUST import `validateTelegramInitData` or `extractTelegramUser`
#   from "@/lib/telegramAuth" or a relative path to it.
# =============================================================

ERRORS=0
API_DIR="src/pages/api"
AUTH_IMPORT_PATTERN="@/lib/telegramAuth"
# Also allow relative paths
AUTH_IMPORT_PATTERN_RELATIVE="../../lib/telegramAuth"


if [ ! -d "$API_DIR" ]; then
  echo "  ⚠️  Directory $API_DIR not found, skipping."
  exit 0
fi

# Find files that likely handle Telegram auth
# We are looking for files that have "Telegram" or "initData" in them.
# We are using `grep -l` to just get the filenames.
# The `|| [[ $? == 1 ]]` is to avoid exiting if grep finds no matches.
FILES_TO_CHECK=$(grep -l -E 'Telegram|initData' $(find $API_DIR -type f -name "*.ts") || [[ $? == 1 ]])


if [ -z "$FILES_TO_CHECK" ]; then
  echo "  ✅ No files found that seem to perform Telegram authentication."
  exit 0
fi

echo "  Checking files for centralized Telegram auth..."

for file in $FILES_TO_CHECK; do
  # Check if the file imports the centralized auth module.
  # We use `grep -q` for a quiet check.
  if grep -q "$AUTH_IMPORT_PATTERN" "$file" || grep -q "$AUTH_IMPORT_PATTERN_RELATIVE" "$file" ; then
    # The file imports the module, so it's compliant.
    :
  else
    # The file does not import the module, so it's a violation.
    echo "  ❌ $file"
    echo "     Violation: File appears to handle Telegram authentication but does not import from '$AUTH_IMPORT_PATTERN'."
    ERRORS=$((ERRORS + 1))
  fi
done

if [ $ERRORS -eq 0 ]; then
  echo "  ✅ All checked files use centralized Telegram authentication."
  exit 0
else
  echo ""
  echo "  ❗ To fix, import and use functions from 'src/lib/telegramAuth.ts' for Telegram authentication."
  exit 1
fi
