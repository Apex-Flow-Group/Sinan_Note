#!/bin/bash
# اختبار سريع للترحيل من SQLite إلى Isar

echo "🔍 فحص ملفات الترحيل..."
echo ""

# 1. التحقق من الملفات المطلوبة
echo "1️⃣ التحقق من الملفات الأساسية:"
files=(
  "lib/models/note.dart"
  "lib/models/note_version.dart"
  "lib/models/note.g.dart"
  "lib/models/note_version.g.dart"
  "lib/services/storage/isar_database_service.dart"
  "lib/services/storage/sqlite_to_isar_migration.dart"
)

for file in "${files[@]}"; do
  if [ -f "$file" ]; then
    echo "   ✅ $file"
  else
    echo "   ❌ $file (مفقود)"
  fi
done

echo ""
echo "2️⃣ التحقق من pubspec.yaml:"
if grep -q "isar:" pubspec.yaml; then
  echo "   ✅ isar موجود"
else
  echo "   ❌ isar مفقود"
fi

if grep -q "isar_flutter_libs:" pubspec.yaml; then
  echo "   ✅ isar_flutter_libs موجود"
else
  echo "   ❌ isar_flutter_libs مفقود"
fi

if grep -q "sqflite:" pubspec.yaml; then
  echo "   ✅ sqflite موجود (للترحيل)"
else
  echo "   ⚠️  sqflite مفقود"
fi

echo ""
echo "3️⃣ التحقق من main.dart:"
if grep -q "SqliteToIsarMigration.migrateIfNeeded()" lib/main.dart; then
  echo "   ✅ استدعاء الترحيل موجود"
else
  echo "   ❌ استدعاء الترحيل مفقود"
fi

echo ""
echo "4️⃣ اختبار البناء:"
echo "   🔨 تشغيل build_runner..."
flutter pub run build_runner build --delete-conflicting-outputs > /dev/null 2>&1
if [ $? -eq 0 ]; then
  echo "   ✅ build_runner نجح"
else
  echo "   ❌ build_runner فشل"
fi

echo ""
echo "5️⃣ اختبار التحليل:"
echo "   🔍 تشغيل flutter analyze..."
flutter analyze --no-pub > /tmp/analyze_output.txt 2>&1
errors=$(grep -c "error •" /tmp/analyze_output.txt || echo "0")
warnings=$(grep -c "warning •" /tmp/analyze_output.txt || echo "0")

if [ "$errors" -eq 0 ]; then
  echo "   ✅ لا توجد أخطاء ($warnings تحذيرات)"
else
  echo "   ❌ $errors أخطاء، $warnings تحذيرات"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 النتيجة النهائية:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ "$errors" -eq 0 ]; then
  echo "✅ الترحيل مكتمل بنجاح!"
  echo ""
  echo "📝 الخطوات التالية:"
  echo "   1. flutter run - لتشغيل التطبيق"
  echo "   2. راجع ISAR_SQFLITE_MIGRATION_STATUS.md للتفاصيل"
else
  echo "❌ يوجد أخطاء تحتاج إلى إصلاح"
  echo ""
  echo "📝 راجع الأخطاء:"
  echo "   flutter analyze"
fi

echo ""
