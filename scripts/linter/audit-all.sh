#!/bin/bash
# =============================================================
# audit-all.sh — Главный аудит архитектуры Moraleon + PixelDungeon
# Запуск: bash scripts/linter/audit-all.sh
# Запуск только warnings: bash scripts/linter/audit-all.sh --warn-only
# =============================================================

WARN_ONLY=false
[[ "$1" == "--warn-only" ]] && WARN_ONLY=true

FAILED=0
WARNINGS=0
TOTAL_CHECKS=0

# Цвета
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

print_header() {
  echo ""
  echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${CYAN}${BOLD}  $1${NC}"
  echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

run_check() {
  local script=$1
  local label=$2
  local is_warning=${3:-false}
  TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

  echo -e "\n${BOLD}▶ $label${NC}"
  bash "scripts/linter/$script"
  local exit_code=$?

  if [ $exit_code -ne 0 ]; then
    if [ "$is_warning" = true ]; then
      WARNINGS=$((WARNINGS + 1))
    else
      FAILED=$((FAILED + 1))
    fi
  fi
}

print_header "🏰 MORALEON ARCHITECTURE AUDIT"
echo "Проект: $(basename $(pwd))"
echo "Время:  $(date '+%Y-%m-%d %H:%M:%S')"

# ── КРИТИЧЕСКИЕ проверки (блокируют коммит) ──────────────────
print_header "🔴 КРИТИЧЕСКИЕ ПРОВЕРКИ"
run_check "check-api-contract.sh"     "API Response контракт"
run_check "check-telegram-auth.sh"    "Telegram Auth централизация"
run_check "check-prisma-patterns.sh"  "Prisma паттерны"
run_check "check-no-console-log.sh"   "Нет console.log в продакшн коде"

# ── ПРЕДУПРЕЖДЕНИЯ (не блокируются, но логируются) ─────────────
print_header "🟡 ПРЕДУПРЕЖДЕНИЯ"
run_check "check-typescript-strict.sh" "TypeScript строгость" true
run_check "check-naming-conventions.sh" "Нейминг конвенции" true
run_check "check-dead-code.sh"          "Потенциальный мёртвый код" true

# ── ИТОГ ─────────────────────────────────────────────────────
print_header "📊 ИТОГИ АУДИТА"
echo "Проверок выполнено: $TOTAL_CHECKS"
echo -e "Критических ошибок: ${RED}$FAILED${NC}"
echo -e "Предупреждений:     ${YELLOW}$WARNINGS${NC}"

if [ $FAILED -ne 0 ]; then
  echo ""
  echo -e "${RED}${BOLD}💥 АУДИТ НЕ ПРОЙДЕН — исправь ошибки выше${NC}"
  exit 1
else
  echo ""
  echo -e "${GREEN}${BOLD}✅ АУДИТ ПРОЙДЕН${NC}"
  [ $WARNINGS -gt 0 ] && echo -e "${YELLOW}   Есть предупреждения — рекомендуется устранить${NC}"
  exit 0
fi
