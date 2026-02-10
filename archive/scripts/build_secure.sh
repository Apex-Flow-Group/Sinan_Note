#!/bin/bash

# 🔒 بناء آمن لـ Google Play
# Secure Build for Google Play

set -e

echo "🔒 بدء البناء الآمن لـ Google Play..."
echo "========================================"
echo ""

# 1. فحص الملفات السرية
echo "🔍 فحص الملفات السرية..."
SECRETS_FOUND=0

if git ls-files | grep -q "client_secret"; then
    echo "❌ خطأ: ملفات client_secret موجودة في Git!"
    SECRETS_FOUND=1
fi

if git ls-files | grep -q "upload_certificate.pem"; then
    echo "❌ خطأ: upload_certificate.pem موجود في Git!"
    SECRETS_FOUND=1
fi

if git ls-files | grep -q "key.properties"; then
    echo "❌ خطأ: key.properties موجود في Git!"
    SECRETS_FOUND=1
fi

if git ls-files | grep -q "\.jks$"; then
    echo "❌ خطأ: ملفات .jks موجودة في Git!"
    SECRETS_FOUND=1
fi

if [ $SECRETS_FOUND -eq 1 ]; then
    echo ""
    echo "⚠️  يجب إزالة الملفات السرية من Git أولاً!"
    echo "   راجع SECURITY_AUDIT_REPORT.md"
    exit 1
fi

echo "✅ لا توجد ملفات سرية في Git"
echo ""

# 2. فحص key.properties
echo "🔑 فحص key.properties..."
if [ ! -f "android/key.properties" ]; then
    echo "❌ خطأ: android/key.properties غير موجود!"
    echo "   انسخ من android/key.properties.template وعدّل القيم"
    exit 1
fi

if [ ! -f "android/app/sinan_key.jks" ]; then
    echo "❌ خطأ: android/app/sinan_key.jks غير موجود!"
    exit 1
fi

echo "✅ ملفات التوقيع موجودة"
echo ""

# 3. تنظيف المشروع
echo "🧹 تنظيف المشروع..."
flutter clean
rm -rf build/
echo "✅ تم التنظيف"
echo ""

# 4. تحديث المكتبات
echo "📦 تحديث المكتبات..."
flutter pub get
echo "✅ تم تحديث المكتبات"
echo ""

# 5. فحص الكود
echo "🔍 فحص الكود..."
flutter analyze
if [ $? -ne 0 ]; then
    echo "⚠️  تحذير: توجد مشاكل في الكود"
    read -p "هل تريد المتابعة؟ (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi
echo ""

# 6. البناء
echo "🏗️  بناء AAB..."
flutter build appbundle --release

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ نجح البناء!"
    echo "========================================"
    echo ""
    echo "📦 الملف الناتج:"
    AAB_PATH="build/app/outputs/bundle/release/app-release.aab"
    ls -lh "$AAB_PATH"
    echo ""
    
    # حساب الحجم
    SIZE=$(du -h "$AAB_PATH" | cut -f1)
    echo "📊 حجم AAB: $SIZE"
    echo ""
    
    # فحص التوقيع
    echo "🔐 فحص التوقيع..."
    jarsigner -verify -verbose "$AAB_PATH" | grep "jar verified"
    
    if [ $? -eq 0 ]; then
        echo "✅ التوقيع صحيح"
    else
        echo "⚠️  تحذير: مشكلة في التوقيع"
    fi
    
    echo ""
    echo "📋 الخطوات التالية:"
    echo "1. افتح Google Play Console"
    echo "2. ارفع: $AAB_PATH"
    echo "3. املأ معلومات الإصدار"
    echo "4. اختبر Internal Testing"
    echo "5. انشر تدريجياً"
    echo ""
else
    echo ""
    echo "❌ فشل البناء!"
    exit 1
fi
