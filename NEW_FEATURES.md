# الميزات الجديدة | New Features

## النسخة 2.2.0

### 1. عمل نسخة (Make a Copy)
- **الموقع**: قائمة الخيارات في شاشة عرض الملاحظة
- **الوظيفة**: إنشاء نسخة كاملة من الملاحظة الحالية
- **الاستخدام**: اضغط على ⋮ ← "عمل نسخة"

### 2. حفظ باسم (Save As)
- **الموقع**: قائمة الخيارات في شاشة عرض الملاحظة
- **الوظيفة**: إنشاء نسخة من الملاحظة بعنوان جديد
- **الاستخدام**: اضغط على ⋮ ← "حفظ باسم" ← أدخل العنوان الجديد

### 3. فتح الملفات البرمجية (Open Programming Files)
- **الوظيفة**: فتح ملفات الكود مباشرة في التطبيق
- **الملفات المدعومة**:
  - Python (.py)
  - JavaScript (.js)
  - Java (.java)
  - Dart (.dart)
  - HTML (.html)
  - CSS (.css)
  - SQL (.sql)
  - JSON (.json)
  - XML (.xml)
  - Markdown (.md)
  - C/C++ (.c, .cpp, .h)
  - Shell (.sh)
  - YAML (.yml, .yaml)
  - وغيرها...

- **الاستخدام**: 
  1. افتح أي ملف برمجي من مدير الملفات
  2. اختر "Sinan Note" من قائمة التطبيقات
  3. سيتم استيراد الملف تلقائياً كملاحظة كود

---

## Version 2.2.0

### 1. Make a Copy
- **Location**: Options menu in note view screen
- **Function**: Create a complete copy of the current note
- **Usage**: Tap ⋮ → "Make a Copy"

### 2. Save As
- **Location**: Options menu in note view screen
- **Function**: Create a copy of the note with a new title
- **Usage**: Tap ⋮ → "Save As" → Enter new title

### 3. Open Programming Files
- **Function**: Open code files directly in the app
- **Supported Files**:
  - Python (.py)
  - JavaScript (.js)
  - Java (.java)
  - Dart (.dart)
  - HTML (.html)
  - CSS (.css)
  - SQL (.sql)
  - JSON (.json)
  - XML (.xml)
  - Markdown (.md)
  - C/C++ (.c, .cpp, .h)
  - Shell (.sh)
  - YAML (.yml, .yaml)
  - And more...

- **Usage**:
  1. Open any programming file from file manager
  2. Choose "Sinan Note" from app list
  3. File will be automatically imported as a code note

---

## التغييرات التقنية | Technical Changes

### Files Modified:
1. `lib/l10n/app_ar.arb` - Added Arabic translations
2. `lib/l10n/app_en.arb` - Added English translations
3. `lib/controllers/notes/notes_provider.dart` - Added `duplicateNote()` method
4. `lib/screens/note_view_screen.dart` - Added menu with copy/save as options
5. `lib/main.dart` - Added file sharing intent handling
6. `android/app/src/main/AndroidManifest.xml` - Enhanced file opening support
7. `pubspec.yaml` - Added `receive_sharing_intent` package

### New Dependencies:
- `receive_sharing_intent: ^1.8.0` - For handling file opening intents

---

## الخطوات التالية | Next Steps

1. قم بتشغيل: `flutter pub get`
2. قم بإعادة بناء التطبيق: `flutter build apk --release`
3. اختبر الميزات الجديدة

---

**Made with ❤️ by Apex Flow Group**
