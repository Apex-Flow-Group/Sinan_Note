# دليل الانتقال إلى نظام Flutter ARB

## 🎯 الهدف
الانتقال من النظام القديم (`strings['key']`) إلى نظام Flutter ARB الاحترافي (`AppLocalizations.of(context)!.key`)

---

## ✅ ما تم إنجازه

### 1. إنشاء ملفات ARB
- ✅ `lib/l10n/app_ar.arb` - النصوص العربية
- ✅ `lib/l10n/app_en.arb` - النصوص الإنجليزية

### 2. تكوين المشروع
- ✅ تحديث `pubspec.yaml` (إضافة `generate: true`)
- ✅ إنشاء `l10n.yaml`
- ✅ توليد الكود تلقائياً في `.dart_tool/flutter_gen/gen_l10n/`

### 3. تحديث main.dart
- ✅ إضافة `AppLocalizations.delegate`

---

## 📝 كيفية الاستخدام

### الطريقة القديمة ❌
```dart
final strings = L10n.getStrings(currentLang);
Text(strings['locked'] ?? 'المقفلة')
```

### الطريقة الجديدة ✅

#### الطريقة الأولى (الرسمية):
```dart
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

Text(AppLocalizations.of(context)!.locked)
```

#### الطريقة الثانية (مع Helper):
```dart
import 'package:apex_note/l10n/l10n_migration_helper.dart';

// استخدام Extension
Text(context.l10n.locked)

// أو استخدام Helper
Text(L10nHelper.of(context).locked)
```

---

## 🔄 خطوات الانتقال التدريجي

### المرحلة 1: الملفات ذات الأولوية العالية
1. `locked_notes_screen.dart` ⭐️ (الملف الحالي)
2. `home_screen.dart`
3. `settings_screen.dart`
4. `note_editor_immersive.dart`

### المرحلة 2: الملفات المتوسطة
5. `archive_screen.dart`
6. `trash_screen.dart`
7. `note_view_screen.dart`

### المرحلة 3: الويدجتات
8. `home_drawer_widget.dart`
9. `note_card_widget.dart`
10. باقي الويدجتات

---

## 🎁 المزايا الجديدة

### 1. Type Safety
```dart
// القديم: يمكن أن تخطئ في الكتابة
strings['lockedd'] // ❌ لن يظهر خطأ حتى وقت التشغيل

// الجديد: خطأ فوري
context.l10n.lockedd // ✅ خطأ في وقت الكتابة
```

### 2. Auto-complete
عند كتابة `context.l10n.` سيظهر لك جميع النصوص المتاحة تلقائياً!

### 3. دعم Placeholders
```dart
// في app_ar.arb:
"lockNotesCount": "قفل {count} ملاحظة"

// في الكود:
context.l10n.lockNotesCount(5) // "قفل 5 ملاحظة"
```

### 4. دعم الجمع والمثنى (Plurals)
```dart
// في app_ar.arb:
"notesCount": "{count, plural, =0{لا توجد ملاحظات} =1{ملاحظة واحدة} =2{ملاحظتان} other{{count} ملاحظات}}"
```

---

## 🚀 البدء الآن

### خطوة 1: استيراد المكتبة
```dart
import 'package:apex_note/l10n/l10n_migration_helper.dart';
```

### خطوة 2: استبدال الكود القديم
```dart
// قبل:
final settings = Provider.of<SettingsProvider>(context, listen: false);
final systemLocale = View.of(context).platformDispatcher.locale.languageCode;
final currentLang = settings.languageCode == 'system' ? systemLocale : settings.languageCode;
final strings = L10n.getStrings(currentLang);
Text(strings['locked']!)

// بعد:
Text(context.l10n.locked)
```

### خطوة 3: حذف الكود غير الضروري
- ❌ حذف `final strings = L10n.getStrings(currentLang);`
- ❌ حذف `final currentLang = ...`
- ✅ استخدام `context.l10n` مباشرة

---

## 📊 التقدم

- [ ] locked_notes_screen.dart (0%)
- [ ] home_screen.dart (0%)
- [ ] settings_screen.dart (0%)
- [ ] باقي الملفات...

---

## 💡 نصائح

1. **لا تحذف الملفات القديمة بعد**: احتفظ بها حتى تنتهي من جميع الملفات
2. **اختبر بعد كل ملف**: تأكد أن كل شيء يعمل
3. **استخدم Find & Replace بحذر**: بعض الحالات تحتاج تعديل يدوي
4. **راجع النصوص**: تأكد أن جميع النصوص موجودة في ملفات ARB

---

## 🔧 إضافة نصوص جديدة

### 1. أضف النص في ملفات ARB
```json
// في app_ar.arb
"newKey": "النص العربي"

// في app_en.arb
"newKey": "English Text"
```

### 2. شغل flutter pub get
```bash
flutter pub get
```

### 3. استخدم النص
```dart
Text(context.l10n.newKey)
```

---

## ❓ الأسئلة الشائعة

### س: هل يجب تحديث جميع الملفات دفعة واحدة؟
ج: لا، يمكنك التحديث تدريجياً. النظامان يعملان معاً.

### س: ماذا لو نسيت نص في ملفات ARB؟
ج: سيظهر خطأ في وقت الكتابة، وليس وقت التشغيل.

### س: كيف أتعامل مع النصوص الديناميكية؟
ج: استخدم placeholders في ملفات ARB.

---

**تم بواسطة: Amazon Q Developer** 🤖
**التاريخ: 7 ديسمبر 2025**
