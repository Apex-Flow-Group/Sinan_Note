# 📋 سجل الترحيل — Isar → SQLite
> تاريخ التنفيذ: مايو 2026 | الإصدار: 3.1.0+3368

---

## السبب

Google Play رفع الإصدار 3368 بسبب:
```
Error: Your app does not support 16 KB memory page sizes.
```
Isar 3.x يستخدم native `.so` مبنية بـ 4 KB alignment — لا يمكن تحديثها لأن المطور أوقف تطوير Isar 3.x.
الحل الدائم: الانتقال الكامل إلى SQLite (sqflite) التي كانت موجودة أصلاً في المشروع.

---

## الملفات المُنشأة

| الملف | الوصف |
|-------|-------|
| `lib/services/storage/sqlite_database_service.dart` | الخدمة الجديدة — تستبدل `IsarDatabaseService` بنفس الـ API كاملاً |

---

## الملفات المُعدَّلة

### النماذج (Models)
| الملف | التغيير |
|-------|---------|
| `lib/models/note.dart` | حذف `import isar`, `part note.g.dart`, `@collection`, `@Index`, `Id` → `int?` |
| `lib/models/note_version.dart` | إعادة كتابة كاملة بدون Isar — `id` أصبح `int` عادي |
| `lib/models/category.dart` | إعادة كتابة كاملة بدون Isar |

### الخدمات
| الملف | التغيير |
|-------|---------|
| `lib/services/note_services/note_db_interface.dart` | توسيع الـ interface ليشمل كل العمليات (كان 3 methods → أصبح 27) |
| `lib/services/storage/isar_database_service.dart` | استبدال بـ `export` يوجّه لـ `sqlite_database_service.dart` |
| `lib/services/storage/backup_service.dart` | استبدال `_getIsarFilePath` بـ `_getDbFilePath`، إضافة `sqflite` import |
| `lib/services/storage/native_db_migration_service.dart` | **حُذف** — لم يعد مطلوباً |
| `lib/services/cloud/google_drive_service.dart` | استبدال `writeTxn` + `isar.notes.clear()` بـ SQLite API |
| `lib/services/cloud/google_drive_merge.dart` | إزالة `writeTxn` واستبدالها بـ `insertNote/updateNote` |
| `lib/services/version_history_service.dart` | استبدال `isar.notes.get()` + `writeTxn` بـ `getNoteById` + `updateNote` |

### Controllers
| الملف | التغيير |
|-------|---------|
| `lib/controllers/categories/categories_provider.dart` | إعادة كتابة كاملة — إزالة كل Isar API مباشر |

### Screens
| الملف | التغيير |
|-------|---------|
| `lib/screens/onboarding/splash_screen.dart` | حذف `NativeDbMigrationService` import واستدعاء |
| `lib/screens/shared/settings/json_import_handler.dart` | استبدال `writeTxn` بـ `deleteNote/insertNote` |

### الاختبارات
| الملف | التغيير |
|-------|---------|
| `test/unit/services/isar_database_service_test.dart` | استبدال `IsarDatabaseService` بـ `SqliteDatabaseService` |
| `test/unit/services/note_security_service_test.dart` | إضافة كل الـ stubs المطلوبة لـ `_MockDb` |

---

## الملفات المحذوفة

| الملف | السبب |
|-------|-------|
| `lib/models/note.g.dart` | مولّد من Isar — لم يعد مطلوباً |
| `lib/models/note_version.g.dart` | مولّد من Isar — لم يعد مطلوباً |
| `lib/models/category.g.dart` | مولّد من Isar — لم يعد مطلوباً |
| `lib/services/storage/native_db_migration_service.dart` | لا حاجة للانتقال لـ React Native |

---

## تغييرات `pubspec.yaml`

### حُذف
```yaml
isar: ^3.1.0+1
isar_flutter_libs: ^3.1.0+1
isar_generator: ^3.1.0+1
```

### تعليق في المكان
```yaml
# Database — migrated to SQLite (16KB page size support)
```

---

## الاستبدال التلقائي (25 ملف)

نُفِّذ بـ Python script على كل ملفات `lib/`:
```
IsarDatabaseService  →  SqliteDatabaseService
isar_database_service.dart  →  sqlite_database_service.dart
```

---

## `android/app/build.gradle`

أُضيف:
```gradle
packaging {
    jniLibs {
        useLegacyPackaging = false
    }
}
```

---

## ما لم يتغير

- `Note.toMap()` و `Note.fromMap()` — كانا موجودَين مسبقاً وهما أساس SQLite
- `sqflite` — كان موجوداً في `pubspec.yaml` مسبقاً
- كل منطق التطبيق (providers, screens, widgets) — لم يتغير
- schema قاعدة البيانات — نفس الـ schema الموجود في `native_db_migration_service`
- ملف `sinan_notes.db` — نفس الاسم والمسار

---

## ملاحظات

- بيانات المستخدمين الحاليين **لن تُفقد** — `sinan_notes.db` كانت تُبنى تلقائياً عند كل تشغيل من Isar
- `isar_database_service.dart` أُبقي كـ `export` للتوافق مع أي مرجع قديم
- `build_runner` أُبقي في dev_dependencies لاستخدامات أخرى محتملة

---

*Copyright © 2025–2026 Apex Flow Group. All rights reserved.*
