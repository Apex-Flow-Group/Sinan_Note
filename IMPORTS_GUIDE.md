# 📚 دليل ترتيب الاستيرادات (Imports) - Sinan Note

## 🎯 المعيار الاحترافي

### 1️⃣ الترتيب القياسي (3 مجموعات)

```dart
// ✅ الطريقة الصحيحة

// 1. مكتبات Dart الأساسية
import 'dart:async';
import 'dart:convert';
import 'dart:io';

// 2. الحزم الخارجية (Packages)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:isar/isar.dart';

// 3. الملفات المحلية (Relative Imports)
import '../models/note.dart';
import '../services/storage/isar_database_service.dart';
import 'note_editor_screen.dart';
```

### ❌ الطريقة الخاطئة

```dart
// ❌ بدون ترتيب وبدون فواصل
import 'note_editor_screen.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import '../models/note.dart';
```

---

## ⚙️ الأتمتة الكاملة

### 1. إعداد analysis_options.yaml

```yaml
include: package:flutter_lints/flutter.yaml

analyzer:
  errors:
    directives_ordering: error

linter:
  rules:
    directives_ordering: true
```

### 2. اختصارات لوحة المفاتيح

#### VS Code
- **Windows/Linux:** `Shift + Alt + O`
- **macOS:** `Shift + Option + O`

#### Android Studio / IntelliJ
- **جميع الأنظمة:** `Ctrl + Alt + O`

---

## 📦 ملفات التجميع (Barrel Files)

### قبل التجميع ❌
```dart
// في كل شاشة تحتاج 5 أسطر
import '../models/note.dart';
import '../models/note_type.dart';
import '../models/reminder.dart';
import '../models/checklist_item.dart';
import '../models/note_history.dart';
```

### بعد التجميع ✅

**ملف models/models.dart:**
```dart
export 'note.dart';
export 'note_type.dart';
export 'reminder.dart';
export 'checklist_item.dart';
export 'note_history.dart';
```

**في الشاشات:**
```dart
// سطر واحد فقط!
import '../models/models.dart';
```

---

## 🚀 تطبيق على Sinan Note

### الخطوة 1: تحديث analysis_options.yaml
### الخطوة 2: إنشاء Barrel Files
### الخطوة 3: تشغيل سكريبت الإصلاح

---

**الحالة:** 🚧 جاهز للتطبيق
