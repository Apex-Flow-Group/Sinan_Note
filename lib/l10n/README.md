# 🌍 نظام الترجمة - Flutter ARB

## 🚀 البدء السريع

### استخدام النصوص:
```dart
import 'package:apex_note/l10n/l10n_migration_helper.dart';

// في أي Widget
Text(context.l10n.locked)
Text(context.l10n.searchNotes)
Text(context.l10n.lockNotesCount(5))
```

### التحقق من اللغة:
```dart
if (context.isArabic) {
  // كود خاص بالعربية
}

if (context.isEnglish) {
  // كود خاص بالإنجليزية
}
```

---

## 📁 الملفات

### ملفات ARB (النصوص):
- `app_ar.arb` - النصوص العربية
- `app_en.arb` - النصوص الإنجليزية

### ملفات مساعدة:
- `l10n_migration_helper.dart` - Helper class + Extensions
- `MIGRATION_GUIDE.md` - دليل شامل للمطورين

### ملفات قديمة (سيتم حذفها لاحقاً):
- `app_localizations.dart` - النصوص العربية القديمة
- `app_en.dart` - النصوص الإنجليزية القديمة
- `app_localizations_helper.dart` - Helper القديم
- `strings_data.dart` - البيانات القديمة

---

## ➕ إضافة نص جديد

### 1. أضف في ملفات ARB:
```json
// في app_ar.arb
{
  "myNewKey": "النص العربي"
}

// في app_en.arb
{
  "myNewKey": "English Text"
}
```

### 2. شغل:
```bash
flutter pub get
```

### 3. استخدم:
```dart
Text(context.l10n.myNewKey)
```

---

## 🎨 استخدام Placeholders

### مثال بسيط:
```json
{
  "welcomeUser": "مرحباً {name}!",
  "@welcomeUser": {
    "placeholders": {
      "name": {
        "type": "String"
      }
    }
  }
}
```

```dart
Text(context.l10n.welcomeUser('أحمد'))
```

### مثال مع أرقام:
```json
{
  "lockNotesCount": "قفل {count} ملاحظة",
  "@lockNotesCount": {
    "placeholders": {
      "count": {
        "type": "int"
      }
    }
  }
}
```

```dart
Text(context.l10n.lockNotesCount(5))
```

---

## 📚 المزيد

راجع `MIGRATION_GUIDE.md` للحصول على دليل شامل.

---

**تم بواسطة: Amazon Q Developer** 🤖
