# 🚀 دليل المطور السريع | Quick Developer Guide

## النسخة 2.2.0 - الميزات الجديدة

### 📦 التثبيت السريع

```bash
# طريقة واحدة - كل شيء تلقائي
./install_features.sh

# أو يدوياً
flutter pub get
flutter gen-l10n
flutter clean && flutter pub get
flutter build apk --release
```

---

## 🎯 الميزات الثلاث الجديدة

### 1️⃣ Make a Copy (عمل نسخة)

**الملفات المعدلة:**
- `lib/controllers/notes/notes_provider.dart` → `duplicateNote()`
- `lib/screens/note_view_screen.dart` → `_makeCopy()`
- `lib/l10n/app_*.arb` → translations

**الكود:**
```dart
// في NotesProvider
Future<int> duplicateNote(int id) async {
  final note = await _dbService.getNoteById(id);
  if (note == null) return -1;
  
  final copy = note.copyWith(
    id: null,
    title: '${note.title} - Copy',
    createdAt: DateTime.now(),
    isPinned: false,
    reminderDateTime: null,
  );
  
  return await addNote(copy);
}
```

---

### 2️⃣ Save As (حفظ باسم)

**الملفات المعدلة:**
- `lib/screens/note_view_screen.dart` → `_saveAs()`
- `lib/l10n/app_*.arb` → translations

**الكود:**
```dart
Future<void> _saveAs(BuildContext context, AppLocalizations l10n) async {
  final controller = TextEditingController(text: _currentNote.title);
  final newTitle = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.saveAs),
      content: TextField(controller: controller),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        TextButton(onPressed: () => Navigator.pop(context, controller.text), child: Text(l10n.save)),
      ],
    ),
  );
  
  if (newTitle != null && newTitle.isNotEmpty) {
    final copy = _currentNote.copyWith(id: null, title: newTitle, createdAt: DateTime.now());
    await provider.addNote(copy);
  }
}
```

---

### 3️⃣ Open Programming Files (فتح الملفات البرمجية)

**الملفات المعدلة:**
- `lib/main.dart` → `_handleSharedFiles()`, `_createNoteFromSharedContent()`
- `android/app/src/main/AndroidManifest.xml` → OPEN_DOCUMENT intent
- `pubspec.yaml` → `receive_sharing_intent: ^1.8.0`

**الكود:**
```dart
// في main.dart
void _handleSharedFiles() {
  ReceiveSharingIntent.getInitialText().then((String? sharedText) {
    if (sharedText != null) _createNoteFromSharedContent(sharedText);
  });
  
  ReceiveSharingIntent.getTextStream().listen((String sharedText) {
    _createNoteFromSharedContent(sharedText);
  });
}

void _createNoteFromSharedContent(String content) async {
  await Future.delayed(const Duration(milliseconds: 500));
  final note = Note(
    title: 'Imported File',
    content: content,
    noteType: _detectLanguage(content),
    createdAt: DateTime.now(),
  );
  await provider.addNote(note);
}

String _detectLanguage(String content) {
  if (content.contains('def ') || content.contains('import ')) return 'python';
  if (content.contains('function ') || content.contains('const ')) return 'javascript';
  if (content.contains('class ') && content.contains('public')) return 'java';
  return 'code';
}
```

**AndroidManifest:**
```xml
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <action android:name="android.intent.action.EDIT" />
    <action android:name="android.intent.action.OPEN_DOCUMENT" />
    <category android:name="android.intent.category.DEFAULT" />
    <data android:scheme="file" />
    <data android:scheme="content" />
    <data android:mimeType="text/*" />
</intent-filter>
```

---

## 🗂️ هيكل الملفات

```
lib/
├── controllers/notes/
│   └── notes_provider.dart          ← duplicateNote()
├── screens/
│   └── note_view_screen.dart        ← قائمة الخيارات + _makeCopy() + _saveAs()
├── l10n/
│   ├── app_ar.arb                   ← ترجمات عربية
│   └── app_en.arb                   ← ترجمات إنجليزية
└── main.dart                        ← معالجة فتح الملفات

android/app/src/main/
└── AndroidManifest.xml              ← OPEN_DOCUMENT intent

pubspec.yaml                         ← receive_sharing_intent

docs/
├── NEW_FEATURES.md                  ← شرح الميزات
├── FEATURES_SUMMARY_AR.md           ← ملخص عربي
├── TEST_CHECKLIST.md                ← قائمة اختبار
├── IMPLEMENTATION_SUMMARY.md        ← ملخص التنفيذ
└── install_features.sh              ← سكريبت تثبيت
```

---

## 🧪 الاختبار

### اختبار Make a Copy:
```bash
# 1. افتح التطبيق
flutter run

# 2. افتح أي ملاحظة
# 3. اضغط ⋮ → "عمل نسخة"
# 4. تحقق من وجود نسخة جديدة
```

### اختبار Save As:
```bash
# 1. افتح ملاحظة
# 2. اضغط ⋮ → "حفظ باسم"
# 3. أدخل عنوان جديد
# 4. تحقق من النسخة الجديدة
```

### اختبار Open Files:
```bash
# 1. أنشئ ملف test.py على الجهاز
echo "print('Hello')" > /sdcard/test.py

# 2. افتح مدير الملفات
# 3. اضغط على test.py
# 4. اختر "Sinan Note"
# 5. تحقق من الاستيراد
```

---

## 🐛 حل المشاكل

### خطأ: "receive_sharing_intent not found"
```bash
flutter pub cache repair
flutter clean
flutter pub get
```

### خطأ: "Translations not found"
```bash
flutter gen-l10n
flutter clean
flutter pub get
```

### خطأ: "App not showing in Open With"
```bash
# أعد تثبيت التطبيق
flutter clean
flutter build apk --release
adb install -r build/app/outputs/flutter-apk/app-release.apk

# أعد تشغيل الجهاز
adb reboot
```

---

## 📊 الإحصائيات

| المقياس | القيمة |
|---------|--------|
| الملفات المعدلة | 7 |
| الملفات الجديدة | 5 |
| أسطر الكود المضافة | ~200 |
| الترجمات المضافة | 6 |
| المكتبات الجديدة | 1 |
| الوقت المستغرق | ~2 ساعة |

---

## 🔗 روابط مفيدة

- [NEW_FEATURES.md](NEW_FEATURES.md) - شرح الميزات
- [FEATURES_SUMMARY_AR.md](FEATURES_SUMMARY_AR.md) - ملخص عربي
- [TEST_CHECKLIST.md](TEST_CHECKLIST.md) - قائمة اختبار
- [IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md) - ملخص التنفيذ
- [CHANGELOG.md](CHANGELOG.md) - سجل التغييرات

---

## 📞 الدعم

- 📧 contact.apex.flow@gmail.com
- 🐛 [GitHub Issues](https://github.com/apexflow/sinan-note/issues)
- 💬 [GitHub Discussions](https://github.com/apexflow/sinan-note/discussions)

---

## ✅ Checklist للمطورين

- [ ] قرأت `NEW_FEATURES.md`
- [ ] قرأت `IMPLEMENTATION_SUMMARY.md`
- [ ] نفذت `./install_features.sh`
- [ ] اختبرت "عمل نسخة"
- [ ] اختبرت "حفظ باسم"
- [ ] اختبرت "فتح ملفات برمجية"
- [ ] راجعت `TEST_CHECKLIST.md`
- [ ] تحققت من الترجمات
- [ ] بنيت APK نهائي
- [ ] اختبرت على جهاز حقيقي

---

**صُنع بـ ❤️ في العالم العربي**

© 2025 Apex Flow Group

**النسخة**: 2.2.0  
**الحالة**: ✅ جاهز للإنتاج
