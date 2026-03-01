# lib/screens/ — الشاشات

---

## الهيكل

```
screens/
├── auth/           # دخول الخزنة
├── desktop/        # تخطيطات سطح المكتب (Master-Details)
├── mobile/         # شاشات الموبايل
├── onboarding/     # الإعداد الأولي
├── other/          # شاشات ثانوية
├── shared/         # شاشات مشتركة (موبايل + سطح مكتب)
└── sync/           # Google Drive
```

---

## الشاشات الرئيسية

### shared/ — المشتركة
| الملف | الوظيفة |
|-------|---------|
| `main_layout_screen.dart` | الشاشة الجذر — تحدد موبايل أم سطح مكتب |
| `note_editor.dart` | محرر الملاحظات الرئيسي |
| `note_view_screen.dart` | عرض الملاحظة (قراءة فقط) |
| `settings_screen.dart` | الإعدادات |

### note_editor/ — المحرر (مقسّم)
```
note_editor/
├── core/
│   ├── editor_coordinator.dart     # يجمع كل controllers في مكان واحد
│   └── editor_build_methods.dart   # build methods منفصلة
├── controllers/
│   ├── editor_smart_controller.dart    # حسابات + اكتشاف لغة + تصدير
│   ├── editor_formatting_controller.dart  # تنسيق النص (bold, italic...)
│   └── editor_storage_controller.dart  # حفظ + تشفير
├── handlers/
│   ├── editor_dialog_handlers.dart  # كل الـ dialogs
│   └── editor_lifecycle_manager.dart
├── state/
│   ├── editor_save_manager.dart    # منطق الحفظ + تحديد noteType
│   └── editor_state.dart
└── widgets/                        # مكونات المحرر الداخلية
```

### desktop/ — سطح المكتب
تخطيط Master-Details: قائمة الملاحظات يساراً + المحرر يميناً.

| الملف | الشاشة |
|-------|---------|
| `home_screen_responsive.dart` | الرئيسية |
| `code_tab_responsive.dart` | تبويب الكود |
| `locked_notes_screen_responsive.dart` | الخزنة |
| `archive_screen_responsive.dart` | الأرشيف |

### auth/ — المصادقة
| الملف | الوظيفة |
|-------|---------|
| `vault_entry_screen.dart` | إنشاء كلمة مرور الخزنة |
| `vault_unlock_screen.dart` | فتح الخزنة (بيومتري أو كلمة مرور) |
| `locked_notes_intro_screen.dart` | شاشة تعريف الخزنة |

---

## تدفق التنقل

```
SplashScreen
    → OnboardingScreen (أول تشغيل)
    → MainLayoutScreen
        → HomeScreen / CodeTab / ChecklistTab / ReminderTab
            → NoteViewScreen → NoteEditorImmersive
        → SettingsScreen
        → GoogleDriveScreen
```

---

## قاعدة مهمة

`NoteEditorImmersive` يستقبل `NoteMode` — هذا يحدد نوع المحرر:

| NoteMode | المحرر |
|----------|---------|
| `simple` | TextField عادي |
| `code` | CodeField مع syntax highlighting |
| `checklist` | ChecklistEditor مع JSON |
| `reminder` | TextField + ReminderPicker |
| `rich` | TextField + شريط تنسيق |
