#!/bin/bash

FLUTTER_PATH="/home/jawal/flutter/bin/flutter"

if [ ! -f "$FLUTTER_PATH" ]; then
    FLUTTER_PATH=$(which flutter 2>/dev/null)
fi

if [ -z "$FLUTTER_PATH" ]; then
    echo "❌ Flutter غير مثبت!"
    exit 1
fi

echo "🚀 بناء تطبيق Apex Note للينكس..."

if [ -d "build/linux" ]; then
    echo "🗑️ حذف البناء القديم..."
    rm -rf build/linux
fi

if [ ! -d "linux" ]; then
    echo "⚙️ إضافة دعم Linux..."
    $FLUTTER_PATH create --platforms=linux .
fi

$FLUTTER_PATH pub get
$FLUTTER_PATH build linux --release

echo "✅ تم البناء بنجاح!"
echo "📦 الملف الناتج: build/linux/x64/release/bundle/"
