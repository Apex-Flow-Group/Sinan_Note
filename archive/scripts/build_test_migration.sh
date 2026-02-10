#!/bin/bash
# بناء نسخة موقعة للاختبار

echo "🔨 بناء نسخة موقعة للاختبار..."
echo ""

# بناء نسخة debug موقعة
flutter build apk --debug

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ تم البناء بنجاح!"
    echo ""
    echo "📦 الملف:"
    ls -lh build/app/outputs/flutter-apk/app-debug.apk
    echo ""
    echo "📋 الخطوات التالية:"
    echo "   1. ثبّت APK القديم: adb install /home/dream/Downloads/3290.apk"
    echo "   2. أنشئ ملاحظات تجريبية"
    echo "   3. ثبّت النسخة الجديدة: adb install -r build/app/outputs/flutter-apk/app-debug.apk"
    echo "   4. افتح التطبيق وتحقق من الترحيل"
    echo ""
else
    echo "❌ فشل البناء"
fi
