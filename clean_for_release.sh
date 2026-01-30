#!/bin/bash

# 🧹 سكريبت تنظيف المشروع قبل رفع Google Play
# Clean Project Before Google Play Upload

set -e

echo "🧹 بدء تنظيف المشروع..."
echo "================================"

# 1. حذف ملفات البناء
echo "📦 حذف ملفات البناء..."
rm -rf build/
rm -rf .dart_tool/
rm -rf android/.gradle/
rm -rf android/app/build/

# 2. حذف ملفات غير ضرورية
echo "🗑️  حذف ملفات غير ضرورية..."
rm -f سنان.tar.gz
rm -f GOOGLE_ICO.png
rm -f libisar.so

# 3. حذف ملفات التوثيق التطويرية
echo "📄 حذف ملفات توثيق التطوير..."
rm -f *_SUMMARY.md
rm -f *_REPORT.md *_REPORT.txt
rm -f *_GUIDE.md
rm -f *_COMPLETE.md
rm -f *_CHANGES.md
rm -f MIGRATION_*.* 
rm -f REFACTORING_*.*
rm -f IMPLEMENTATION_*.*
rm -f TESTING_*.*
rm -f DEBUG_*.*
rm -f LEGACY_*.*
rm -f PACKAGE_*.*
rm -f QUICK_*.*
rm -f SETUP_*.*
rm -f TODO_*.*
rm -f WIDGET_*.*
rm -f THEME_*.*
rm -f TITLE_*.*
rm -f SECURITY_*.*
rm -f PERFORMANCE_*.*
rm -f NOTIFICATION_*.*
rm -f CLIPBOARD_*.*
rm -f CHECKLIST_*.*
rm -f COMPLETE_*.*
rm -f FINAL_*.*
rm -f GOD_*.*
rm -f IMMERSIVE_*.*
rm -f ADAPTIVE_*.*
rm -f AUTO_*.*
rm -f SMART_*.*
rm -f STRESS_*.*
rm -f TEST_*.*

# 4. تنظيف assets
echo "🎨 تنظيف assets..."
cd assets
# احتفظ فقط بالملفات الضرورية
find . -type f ! -name "app_icon.png" ! -name "icon.png" ! -path "./legal/*" ! -path "./icon/*" ! -path "./images/app_icon.png" -delete
cd ..

# 5. حذف سكريبتات التطوير
echo "🔧 حذف سكريبتات التطوير..."
rm -f dont_be_stubbed.*
rm -f rebuild.sh
rm -f sync_l10n.sh
rm -f test_notifications.sh

# 6. التحقق من الملفات السرية
echo "🔐 التحقق من الملفات السرية..."
if git ls-files | grep -q "client_secret"; then
    echo "⚠️  تحذير: ملفات client_secret موجودة في Git!"
    echo "   قم بتشغيل: git rm --cached client_secret*.json"
fi

if git ls-files | grep -q "upload_certificate.pem"; then
    echo "⚠️  تحذير: upload_certificate.pem موجود في Git!"
    echo "   قم بتشغيل: git rm --cached upload_certificate.pem"
fi

# 7. تنظيف Flutter
echo "🔄 تنظيف Flutter..."
flutter clean
flutter pub get

echo ""
echo "✅ اكتمل التنظيف!"
echo "================================"
echo ""
echo "📋 الخطوات التالية:"
echo "1. راجع GOOGLE_PLAY_CHECKLIST.md"
echo "2. تأكد من إزالة الملفات السرية من Git"
echo "3. قم ببناء AAB: flutter build appbundle --release"
echo ""
