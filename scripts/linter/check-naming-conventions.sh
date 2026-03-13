#!/bin/bash
# =============================================================
# check-naming-conventions.sh
# Ловит несогласованный нейминг — главный симптом "разных LLM"
# =============================================================

ISSUES=0

echo "  Проверка нейминг конвенций..."
echo ""

# ── Компоненты: должны быть PascalCase ───────────────────────
echo "  1. React компоненты (PascalCase)..."
COMP_DIRS=("src/components")

for dir in "${COMP_DIRS[@]}"; do
  [ -d "$dir" ] || continue
  while IFS= read -r file; do
    filename=$(basename "$file" .tsx)
    filename=$(basename "$filename" .jsx)
    # Проверяем что первая буква заглавная
    first_char="${filename:0:1}"
    if [[ "$first_char" =~ [a-z] ]]; then
      echo "  ⚠️  Компонент не в PascalCase: $file"
      ISSUES=$((ISSUES + 1))
    fi
  done < <(find "$dir" -name "*.tsx" -o -name "*.jsx" 2>/dev/null | grep -v "node_modules")
done

# ── Хуки: должны начинаться с use ────────────────────────────
echo ""
echo "  2. Хуки (префикс 'use')..."
HOOK_DIRS=("src/hooks")

for dir in "${HOOK_DIRS[@]}"; do
  [ -d "$dir" ] || continue
  while IFS= read -r file; do
    filename=$(basename "$file" .ts)
    filename=$(basename "$filename" .tsx)
    if [[ "$filename" != use* ]]; then
      echo "  ⚠️  Хук без префикса 'use': $file"
      ISSUES=$((ISSUES + 1))
    fi
  done < <(find "$dir" -name "*.ts" -o -name "*.tsx" 2>/dev/null | grep -v "node_modules")
done

# ── API endpoints: kebab-case в путях ────────────────────────
echo ""
echo "  3. API роуты (kebab-case пути и файлы)..."
API_DIR="src/pages/api"
if [ -d "$API_DIR" ]; then
  # Ищем папки с camelCase или snake_case именами
  while IFS= read -r folder; do
    foldername=$(basename "$folder")
    # Пропускаем служебные
    [[ "$foldername" == "api" ]] && continue
    # Проверяем наличие заглавных букв или подчёркиваний
    if [[ "$foldername" =~ [A-Z] ]] || [[ "$foldername" =~ _ ]]; then
      echo "  ⚠️  API путь не в kebab-case: $folder"
      ISSUES=$((ISSUES + 1))
    fi
  done < <(find "$API_DIR" -type d 2>/dev/null)

  # Ищем файлы с camelCase или snake_case именами
    while IFS= read -r file; do
        filename=$(basename "$file" .ts)
        if [[ "$filename" =~ [A-Z] ]] || [[ "$filename" =~ _ ]]; then
            echo "  ⚠️  API файл не в kebab-case: $file"
            ISSUES=$((ISSUES + 1))
        fi
    done < <(find "$API_DIR" -name "*.ts" 2>/dev/null)

fi


# ── Интерфейсы и типы: PascalCase ────────────────────────────
echo ""
echo "  4. Типы и интерфейсы (PascalCase)..."
TYPE_VIOLATIONS=$(grep -rn "^interface [a-z]\|^type [a-z].*=" \
  --include="*.ts" --include="*.tsx" . \
  2>/dev/null | grep -v "node_modules" | grep -v "\.next" \
  | grep -v "type [a-z].*Props\b")  # Исключаем локальные Props aliases

if [ -n "$TYPE_VIOLATIONS" ]; then
  echo "  ⚠️  Типы/интерфейсы не в PascalCase:"
  echo "$TYPE_VIOLATIONS" | while read -r line; do echo "     $line"; done
  ISSUES=$((ISSUES + 1))
else
  echo "     ✅ Типы и интерфейсы корректны"
fi

# ── Смешение snake_case и camelCase в одном файле ────────────
echo ""
echo "  5. Несогласованный нейминг переменных в API routes..."
if [ -d "$API_DIR" ]; then
  while IFS= read -r file; do
    CAMEL=$(grep -c "[a-z][A-Z][a-z]" "$file" 2>/dev/null || echo 0)
    SNAKE=$(grep -c "[a-z]_[a-z]" "$file" 2>/dev/null || echo 0)

    # Если оба стиля активно используются — флагируем
    if [ "$CAMEL" -gt 3 ] && [ "$SNAKE" -gt 3 ]; then
      echo "  ⚠️  Смешанный нейминг в $file (camelCase: $CAMEL, snake_case: $SNAKE)"
      echo "     Prisma поля допустимы в snake_case, JS переменные — camelCase"
    fi
  done < <(find "$API_DIR" -name "*.ts" 2>/dev/null)
fi

echo ""
if [ $ISSUES -eq 0 ]; then
  echo "  ✅ Нейминг конвенции соблюдены"
else
  echo "  ⚠️  Найдены нарушения нейминга"
fi

exit 0  # warning only
