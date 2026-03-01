# lib/ — هيكل الكود

المعمارية: **Clean Architecture** مع **Provider** لإدارة الحالة.

---

## الهيكل

```
lib/
├── controllers/
│   ├── editor/
│   │   ├── editor_state_manager.dart   # حالة المحرر (dirty, undo, reminder...)
│   │   └── text_direction_controller.dart  # RTL/LTR تلقائي
│   ├── notes/
│   │   └── notes_provider.dart         # CRUD الملاحظات + الحالة العامة
│   └── settings/
│       └── settings_provider.dart      # إعدادات المستخدم
│
├── core/
│   ├── constants/                      # ثوابت التطبيق
│   ├── shortcuts/                      # اختصارات لوحة المفاتيح (سطح مكتب)
│   ├── theme/                          # الثيمات
│   └── utils/
│       ├── adaptive_color.dart         # لوحة الألوان التكيفية
│       ├── apex_smart_controller.dart  # TextEditingController مخصص
│       ├── checklist_formatter.dart    # تحويل JSON ↔ نص للقوائم
│       └── logger.dart                 # نظام logging (debug only)
│
├── models/
│   ├── note.dart / note.g.dart         # نموذج الملاحظة (Isar)
│   ├── note_version.dart               # نموذج تاريخ الإصدارات
│   ├── note_mode.dart                  # enum: simple/code/checklist/reminder/rich
│   └── exceptions.dart                 # استثناءات مخصصة
│
├── screens/          → راجع lib/screens/README.md
├── services/         → راجع lib/services/README.md
│
└── widgets/
    ├── common/       # مكونات مشتركة (ShareSheet, RenameDialog...)
    ├── desktop/      # قائمة سياق سطح المكتب
    ├── editor/       # أدوات المحرر (Toolbar, CodeEditor...)
    ├── effects/      # تأثيرات بصرية (PremiumCardEffect)
    ├── home/         # بطاقات الملاحظات والشبكة
    └── navigation/   # شريط التنقل السفلي والجانبي
```

---

## تدفق البيانات

```
UI (Screens/Widgets)
    ↕ Provider.of
Controllers (NotesProvider, SettingsProvider)
    ↕ await
Services (NoteStateService, SecurityService...)
    ↕ Isar
Database (note.g.dart)
```

---

## قواعد المعمارية

- **Screens** لا تتصل بـ Database مباشرة — تمر عبر Provider
- **Services** لا تعرف شيئاً عن الـ UI
- **Models** بيانات فقط، لا منطق
- كل logging عبر `AppLogger` فقط (يُعطَّل تلقائياً في release)
