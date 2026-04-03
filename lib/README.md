# lib/ — هيكل الكود

المعمارية: **Clean Architecture** مع **Provider** لإدارة الحالة.

---

## الهيكل

```
lib/
├── controllers/
│   ├── categories/
│   │   └── categories_provider.dart    # إدارة الكتالوجات + الكتالوج الافتراضي (kProCategoryId)
│   ├── editor/
│   │   └── editor_state_manager.dart   # حالة المحرر (dirty, undo, reminder...)
│   ├── notes/
│   │   └── notes_provider.dart         # CRUD الملاحظات + الحالة العامة
│   └── settings/
│       └── settings_provider.dart      # إعدادات المستخدم
│
├── core/
│   ├── constants/                      # ثوابت التطبيق
│   ├── shortcuts/
│   │   └── app_shortcuts.dart          # اختصارات لوحة المفاتيح (سطح مكتب)
│   ├── theme/                          # الثيمات
│   └── utils/
│       ├── adaptive_color.dart         # لوحة الألوان التكيفية
│       ├── apex_smart_controller.dart  # TextEditingController مخصص
│       ├── checklist_formatter.dart    # تحويل JSON ↔ نص للقوائم
│       ├── logger.dart                 # نظام logging (debug only)
│       ├── note_content_utils.dart     # تحويل موحد لمحتوى النوت (Delta/Checklist/نص)
│       ├── platform_helper.dart        # كشف المنصة
│       ├── quill_migration.dart        # تحويل Delta JSON ↔ plain text
│       ├── search_mixin.dart           # Mixin مشترك لمنطق البحث
│       └── text_direction_utils.dart   # كشف RTL/LTR تلقائي
│
├── models/
│   ├── category.dart / category.g.dart # نموذج الكتالوج (Isar)
│   ├── note.dart / note.g.dart         # نموذج الملاحظة (Isar)
│   ├── note_version.dart               # نموذج تاريخ الإصدارات
│   ├── note_mode.dart                  # enum: simple/code/checklist/reminder/rich
│   ├── feature_info.dart               # معلومات الميزات الجديدة
│   └── exceptions.dart                 # استثناءات مخصصة
│
├── providers/
│   └── selected_note_provider.dart     # النوت المفتوحة حالياً (Master-Details)
│
├── screens/          → راجع lib/screens/README.md
├── services/         → راجع lib/services/README.md
│
└── widgets/
    ├── common/       # مكونات مشتركة (ShareSheet, GlowingSearchField...)
    ├── desktop/      # قائمة سياق سطح المكتب
    ├── editor/       # أدوات المحرر (Toolbar, CodeEditor, ChecklistEditor...)
    ├── effects/      # تأثيرات بصرية (PremiumCardEffect)
    ├── home/         # بطاقات الملاحظات، الشبكة، الشريط الجانبي
    └── navigation/   # شريط التنقل السفلي والجانبي
```

---

## تدفق البيانات

```
UI (Screens/Widgets)
    ↕ Provider.of / context.watch
Controllers (NotesProvider, CategoriesProvider, SettingsProvider)
    ↕ await
Services (NoteStateService, SecurityService...)
    ↕ Isar
Database (note.g.dart / category.g.dart)
```

---

## قواعد المعمارية

- **Screens** لا تتصل بـ Database مباشرة — تمر عبر Provider
- **Services** لا تعرف شيئاً عن الـ UI
- **Models** بيانات فقط، لا منطق
- كل تحويل لمحتوى النوت يمر عبر `NoteContentUtils.toDisplayText()`
- كل logging عبر `AppLogger` فقط (يُعطَّل تلقائياً في release)
