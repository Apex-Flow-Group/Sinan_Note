# إعادة تنظيم مجلد Screens

## نظرة عامة
تم إعادة تنظيم مجلد `lib/screens` لتحسين البنية وسهولة الصيانة.

## البنية الجديدة

```
lib/screens/
├── mobile/              # شاشات الموبايل الأساسية
│   ├── home_screen.dart
│   ├── archive_screen.dart
│   ├── trash_screen.dart
│   └── locked_notes_screen.dart
│
├── desktop/             # نسخ responsive للديسكتوب
│   ├── home_screen_responsive.dart
│   ├── archive_screen_responsive.dart
│   ├── trash_screen_responsive.dart
│   └── locked_notes_screen_responsive.dart
│
├── shared/              # شاشات مشتركة بين المنصات
│   ├── note_editor.dart
│   ├── note_view_screen.dart
│   ├── settings_screen.dart
│   ├── settings_screen_responsive.dart
│   ├── main_layout_screen.dart
│   ├── note_editor/     # مكونات المحرر
│   ├── note_view/       # مكونات العرض
│   ├── settings/        # مكونات الإعدادات
│   └── tabs/            # تبويبات (code, reminder)
│
├── auth/                # شاشات المصادقة والأمان
│   ├── vault_entry_screen.dart
│   ├── vault_unlock_screen.dart
│   └── locked_notes_intro_screen.dart
│
├── onboarding/          # شاشات التعريف بالتطبيق
│   ├── splash_screen.dart
│   ├── cinematic_intro_screen.dart
│   ├── tour_screen.dart
│   └── terms_screen.dart
│
├── sync/                # شاشات المزامنة السحابية
│   ├── google_drive_screen.dart
│   ├── google_drive_screen_responsive.dart
│   ├── google_drive_sync_terms_screen.dart
│   └── google_drive/    # مكونات Google Drive
│
└── other/               # شاشات متنوعة
    ├── about_screen.dart
    ├── support_form_screen.dart
    ├── version_history_screen.dart
    └── widget_selection_screen.dart
```

## التغييرات الرئيسية

### 1. فصل شاشات Mobile و Desktop
- شاشات Mobile الأساسية في `mobile/`
- نسخ Responsive في `desktop/`
- يسهل الصيانة والتطوير المستقل

### 2. تجميع الشاشات المشتركة
- المحرر والعرض والإعدادات في `shared/`
- مكونات فرعية منظمة في مجلدات خاصة
- سهولة إعادة الاستخدام عبر المنصات

### 3. تنظيم حسب الوظيفة
- شاشات المصادقة في `auth/`
- شاشات التعريف في `onboarding/`
- شاشات المزامنة في `sync/`
- شاشات متنوعة في `other/`

## تحديث Imports

تم تحديث جميع imports تلقائياً باستخدام السكريبت `scripts/fix_imports.py`:

### أمثلة على التغييرات:

```dart
// قبل
import 'screens/home_screen.dart';
import 'screens/note_editor.dart';
import 'screens/vault_entry_screen.dart';

// بعد
import 'screens/mobile/home_screen.dart';
import 'screens/shared/note_editor.dart';
import 'screens/auth/vault_entry_screen.dart';
```

## الملفات المعدلة

تم تعديل 15 ملف تلقائياً:
- `lib/main.dart`
- ملفات في `lib/widgets/`
- ملفات في `lib/screens/`
- ملفات في `lib/services/`
- ملفات في `test/`

## التحقق من النجاح

```bash
# تشغيل التحليل
flutter analyze --no-pub

# النتيجة: لا توجد أخطاء ✅
```

## الفوائد

1. **وضوح أفضل**: سهولة معرفة مكان كل شاشة
2. **صيانة أسهل**: تجميع الملفات المرتبطة معاً
3. **قابلية التوسع**: سهولة إضافة شاشات جديدة
4. **فصل المسؤوليات**: كل مجلد له غرض واضح
5. **تطوير أسرع**: سهولة العثور على الملفات

## ملاحظات للمطورين

### عند إضافة شاشة جديدة:

1. **شاشة موبايل أساسية** → `mobile/`
2. **نسخة responsive** → `desktop/`
3. **شاشة مشتركة** → `shared/`
4. **شاشة مصادقة** → `auth/`
5. **شاشة تعريف** → `onboarding/`
6. **شاشة مزامنة** → `sync/`
7. **شاشة أخرى** → `other/`

### قواعد Imports:

```dart
// من lib/screens/mobile/
import '../shared/note_editor.dart';        // شاشة مشتركة
import '../desktop/home_screen_responsive.dart';  // شاشة desktop
import '../../models/note.dart';            // model من lib root

// من lib/screens/shared/
import '../mobile/home_screen.dart';        // شاشة mobile
import '../../services/storage/isar_database_service.dart';  // service

// من lib/widgets/
import '../screens/shared/note_editor.dart';  // شاشة
import '../models/note.dart';                 // model
```

## السكريبتات المساعدة

### `scripts/fix_imports.py`
يصلح جميع imports تلقائياً بعد إعادة التنظيم:

```bash
python3 scripts/fix_imports.py
```

### `scripts/fix_relative_imports.py`
يصلح المسارات النسبية في ملفات screens:

```bash
python3 scripts/fix_relative_imports.py
```

## التاريخ

- **التاريخ**: 12 فبراير 2026
- **الإصدار**: 1.0.0
- **الملفات المعدلة**: 15 ملف
- **الملفات المنقولة**: 30+ ملف
- **الحالة**: مكتمل ✅

---

**ملاحظة**: هذا التنظيم يتبع أفضل الممارسات في Flutter لتنظيم المشاريع الكبيرة.
