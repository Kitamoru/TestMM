#!/bin/bash
# =============================================================
# check-api-contract.sh
# Проверяет что все API routes возвращают { success: bool, data/error }
# =============================================================

ERRORS=0

# Определяем где искать
API_DIRS=()
[ -d "src/pages/api" ] && API_DIRS+=("src/pages/api")

if [ ${#API_DIRS[@]} -eq 0 ]; then
  echo "  ⚠️  Папка src/pages/api не найдена, пропускаем"
  exit 0
fi

check_file() {
  local file=$1
  local violations=()

  # 1. NextResponse.json без success поля
  while IFS= read -r line; do
    local lineno=$(echo "$line" | cut -d: -f1)
    local content=$(echo "$line" | cut -d: -f2-)
    # Пропускаем комментарии и строки с success:
    echo "$content" | grep -q "success:" && continue
    echo "$content" | grep -q "^[[:space:]]*//" && continue
    violations+=("  Строка $lineno: $content")
  done < <(grep -n "NextResponse.json({" "$file" | grep -v "success:")

  # 2. Прямой return {} без NextResponse (устаревший паттерн Next.js 13)
  while IFS= read -r line; do
    local lineno=$(echo "$line" | cut -d: -f1)
    local content=$(echo "$line" | cut -d: -f2-)
    violations+=("  Строка $lineno [прямой return]: $content")
  done < <(grep -n "^[[:space:]]*return {" "$file" 2>/dev/null | grep -v "//")

  if [ ${#violations[@]} -gt 0 ]; then
    echo "  ❌ $file"
    for v in "${violations[@]}"; do
      echo "     $v"
    done
    ERRORS=$((ERRORS + ${#violations[@]}))
  fi
}

echo "  Проверяемые директории: ${API_DIRS[*]}"
echo ""

for dir in "${API_DIRS[@]}"; do
  while IFS= read -r file; do
    # Пропускаем файлы без NextResponse (например middleware)
    grep -q "NextResponse" "$file" 2>/dev/null || continue
    check_file "$file"
  done < <(find "$dir" -name "*.ts")
done

if [ $ERRORS -eq 0 ]; then
  echo "  ✅ Все API routes соответствуют контракту { success, data/error }"
  exit 0
else
  echo ""
  echo "  ❗ Ожидаемый формат:"
  echo '''     return NextResponse.json({ success: true, data: result })'''
  echo '''     return NextResponse.json({ success: false, error: "msg" }, { status: 500 })'''
  exit 1
fi
