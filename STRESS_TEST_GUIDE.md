# 🧪 دليل اختبار الضغط والاستقرار - Sinan Note

## 🎯 الطرق الاحترافية المتاحة

---

## 1️⃣ **Integration Tests (الأفضل)**

### التشغيل:
```bash
flutter test integration_test/stress_test.dart
```

### الاختبارات المتوفرة:
- ✅ إنشاء 50 ملاحظة بسرعة
- ✅ اختبار التمرير السريع (30 دورة)
- ✅ اختبار تسريب الذاكرة (إنشاء/حذف 20 مرة)

---

## 2️⃣ **Flutter DevTools (مراقبة مباشرة)**

### التشغيل:
```bash
# 1. شغل التطبيق
flutter run --profile

# 2. افتح DevTools
flutter pub global activate devtools
flutter pub global run devtools

# 3. راقب:
# - Memory: تسريبات الذاكرة
# - Performance: الأداء
# - Network: الشبكة
```

### ما تراقبه:
- 📊 استهلاك الذاكرة (يجب أن يستقر بعد فترة)
- 🔥 CPU Usage (يجب ألا يتجاوز 30% في الخمول)
- ⚡ Frame Rate (يجب أن يبقى 60 FPS)

---

## 3️⃣ **Monkey Testing (اختبار عشوائي)**

### Android:
```bash
# تثبيت التطبيق
flutter build apk --release
adb install build/app/outputs/flutter-apk/app-release.apk

# تشغيل Monkey Test (10000 حدث عشوائي)
adb shell monkey -p com.apexflow.sinan_note -v 10000

# مراقبة الأخطاء
adb logcat | grep -i "crash\|error\|exception"
```

---

## 4️⃣ **Unit Tests (اختبار الوحدات)**

### التشغيل:
```bash
flutter test test/unit/memory_leak_test.dart
```

---

## 5️⃣ **Performance Profiling**

### التشغيل:
```bash
# Profile Mode
flutter run --profile

# في DevTools:
# 1. اذهب إلى Performance
# 2. اضغط Record
# 3. استخدم التطبيق بكثافة
# 4. اضغط Stop
# 5. راجع Timeline
```

---

## 6️⃣ **Memory Leak Detection**

### الطريقة اليدوية:
```bash
# 1. شغل التطبيق
flutter run --profile

# 2. في DevTools > Memory:
# - اضغط GC (Garbage Collection)
# - استخدم التطبيق
# - اضغط GC مرة أخرى
# - إذا زادت الذاكرة بشكل مستمر = تسريب
```

---

## 7️⃣ **Automated Stress Test Script**

### إنشاء سكريبت:
```bash
#!/bin/bash
# stress_test.sh

echo "🧪 Starting Stress Test..."

# 1. Build
flutter build apk --release

# 2. Install
adb install -r build/app/outputs/flutter-apk/app-release.apk

# 3. Launch
adb shell am start -n com.apexflow.sinan_note/.MainActivity

# 4. Monkey Test
adb shell monkey -p com.apexflow.sinan_note \
  --throttle 100 \
  --pct-touch 40 \
  --pct-motion 30 \
  --pct-nav 20 \
  --pct-syskeys 10 \
  -v -v -v 5000 > monkey_log.txt

# 5. Check for crashes
if grep -q "CRASH" monkey_log.txt; then
  echo "❌ CRASH DETECTED!"
  exit 1
else
  echo "✅ Test Passed!"
fi
```

### التشغيل:
```bash
chmod +x stress_test.sh
./stress_test.sh
```

---

## 8️⃣ **Firebase Test Lab (السحابة)**

### الإعداد:
```bash
# 1. رفع APK
gcloud firebase test android run \
  --type instrumentation \
  --app build/app/outputs/flutter-apk/app-release.apk \
  --test build/app/outputs/flutter-apk/app-release-androidTest.apk \
  --device model=Pixel2,version=28,locale=ar,orientation=portrait

# 2. النتائج في Firebase Console
```

---

## 9️⃣ **Maestro (أداة حديثة)**

### التثبيت:
```bash
curl -Ls "https://get.maestro.mobile.dev" | bash
```

### إنشاء flow:
```yaml
# stress_flow.yaml
appId: com.apexflow.sinan_note
---
- launchApp
- repeat:
    times: 50
    commands:
      - tapOn: "Add Note"
      - inputText: "Stress Test"
      - tapOn: "Save"
      - back
```

### التشغيل:
```bash
maestro test stress_flow.yaml
```

---

## 🔟 **Sentry/Crashlytics (الإنتاج)**

### الإعداد في pubspec.yaml:
```yaml
dependencies:
  sentry_flutter: ^7.0.0
```

### في main.dart:
```dart
import 'package:sentry_flutter/sentry_flutter.dart';

Future<void> main() async {
  await SentryFlutter.init(
    (options) {
      options.dsn = 'YOUR_DSN';
      options.tracesSampleRate = 1.0;
    },
    appRunner: () => runApp(MyApp()),
  );
}
```

---

## 📊 **مؤشرات النجاح**

### ✅ التطبيق مستقر إذا:
- الذاكرة تستقر بعد 5 دقائق استخدام
- لا توجد crashes في 10000 حدث عشوائي
- Frame rate يبقى 60 FPS
- CPU لا يتجاوز 30% في الخمول
- لا توجد ANR (Application Not Responding)

### ❌ علامات المشاكل:
- الذاكرة تزيد باستمرار
- Crashes متكررة
- Frame drops (أقل من 60 FPS)
- CPU عالي في الخمول
- Slow database queries

---

## 🎯 **التوصيات**

### للتطوير:
1. استخدم `flutter run --profile` دائماً
2. راقب DevTools أثناء التطوير
3. شغل Integration Tests قبل كل commit

### قبل الإطلاق:
1. Monkey Test (10000 حدث)
2. Memory Profiling (30 دقيقة)
3. Performance Profiling
4. Firebase Test Lab (أجهزة متعددة)

### بعد الإطلاق:
1. Sentry/Crashlytics للمراقبة
2. راجع التقارير يومياً
3. أصلح الأخطاء الحرجة فوراً

---

## 🚀 **الأوامر السريعة**

```bash
# اختبار سريع
flutter test

# اختبار الضغط
flutter test integration_test/stress_test.dart

# مراقبة الأداء
flutter run --profile

# Monkey Test
adb shell monkey -p com.apexflow.sinan_note -v 5000

# تنظيف
flutter clean && flutter pub get
```

---

**END OF GUIDE**
