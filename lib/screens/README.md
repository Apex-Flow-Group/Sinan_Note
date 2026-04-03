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
| `note_view_screen.dart` | عرض الملاحظة (قراءة فقط) مع دعم السلة |
| `settings_screen.dart` | الإعدادات (موبايل) |
| `settings_screen_responsive.dart` | الإعدادات (سطح مكتب) |

### note_editor/ — المحرر (مقسّم)
```
note_editor/
├── core/
│   ├── editor_coordinator.dart      # يجمع كل controllers في مكان واحد
│   └── editor_build_methods.dart    # build methods منفصلة
├── controllers/
│   ├── editor_smart_controller.dart     # حسابات + اكتشاف لغة + تصدير
│   ├── editor_formatting_controller.dart   # تنسيق النص (bold, italic...)
│   └── editor_storage_controller.dart   # حفظ + تشفير
├── handlers/
│   ├── editor_dialog_handlers.dart  # كل الـ dialogs
│   └── editor_lifecycle_manager.dart
├── state/
│   ├── editor_save_manager.dart     # منطق الحفظ + تحديد noteType
│   ├── editor_state.dart
│   └── editor_lifecycle.dart
├── dialogs/
│   └── editor_dialogs.dart
├── utils/
│   └── note_editor_utils.dart
└── widgets/                         # مكونات المحرر الداخلية
    ├── checklist_editor_widget.dart
    ├── code_editor_widget.dart
    └── editor_header_widget.dart
```

### mobile/ — الموبايل
| الملف | الشاشة |
|-------|---------|
| `home_screen.dart` | الرئيسية مع pagination (100 نوت/صفحة) |
| `home_screen_widgets.dart` | PopScope + DateBarHeader |
| `home_scrollbar.dart` | شريط تمرير مخصص مع animation |
| `archive_screen.dart` | الأرشيف مع وضع التحديد |
| `trash_screen.dart` | السلة مع استعادة/حذف نهائي |
| `locked_notes_screen.dart` | الخزنة المشفرة |

### desktop/ — سطح المكتب
تخطيط Master-Details: قائمة الملاحظات يساراً + المحرر يميناً.

| الملف | الشاشة |
|-------|---------|
| `home_screen_responsive.dart` | الرئيسية |
| `code_tab_responsive.dart` | تبويب الكود |
| `locked_notes_screen_responsive.dart` | الخزنة |
| `archive_screen_responsive.dart` | الأرشيف |
| `trash_screen_responsive.dart` | السلة |
| `reminder_dashboard_responsive.dart` | التذكيرات |

### auth/ — المصادقة
| الملف | الوظيفة |
|-------|---------|
| `vault_entry_screen.dart` | إنشاء كلمة مرور الخزنة |
| `vault_unlock_screen.dart` | فتح الخزنة (بيومتري أو كلمة مرور) |
| `locked_notes_intro_screen.dart` | شاشة تعريف الخزنة |
| `vault_intro_pages.dart` | صفحات تعريفية للخزنة |

### onboarding/ — الإعداد الأولي
| الملف | الوظيفة |
|-------|---------|
| `splash_screen.dart` | شاشة البداية |
| `cinematic_intro_screen.dart` | مقدمة سينمائية |
| `tour_screen.dart` | جولة تعريفية |
| `terms_screen.dart` | الشروط والأحكام |
| `whats_new_dialog.dart` | ما الجديد في هذا الإصدار |

### other/ — ثانوية
| الملف | الوظيفة |
|-------|---------|
| `about_screen.dart` | حول التطبيق + التراخيص |
| `support_form_screen.dart` | نموذج الدعم |
| `version_history_screen.dart` | تاريخ إصدارات الملاحظة |
| `widget_selection_screen.dart` | اختيار نوت للـ Home Widget |

### sync/ — المزامنة
```
sync/
├── google_drive/           # مكونات Drive
├── google_drive_sync/      # صفحة المزامنة التفصيلية
├── google_drive_screen.dart
├── google_drive_screen_responsive.dart
└── google_drive_sync_terms_screen.dart
```

---

## تدفق التنقل

```
SplashScreen
    → CinematicIntroScreen (أول تشغيل)
    → TermsScreen
    → TourScreen
    → MainLayoutScreen
        ├── HomeScreen / CodeTab / ReminderDashboard
        │       → NoteViewScreen → NoteEditorImmersive
        ├── LockedNotesScreen (الخزنة)
        │       → VaultUnlockScreen
        ├── ArchiveScreen
        ├── TrashScreen
        └── SettingsScreen
                → AboutScreen
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
| `rich` | TextField + شريط تنسيق Quill |
