# تحليل: lib/models/note.dart

**الحالة:** 🔄 قيد العمل
**تاريخ البدء:** 2026-05-15
**التبعيات:** `exceptions.dart` فقط (depth: 0)

---

## الدوال (6)

| # | الدالة | النوع | الأسطر | الحالة | القرار |
|---|--------|-------|--------|--------|--------|
| 1 | `normalize` | static method | 14 | ✅ مراجعة | لا تغيير |
| 2 | `isEncrypted` | getter | 5 | ✅ مراجعة | يحتاج تقييم ↓ |
| 3 | `copyWith` | method | 30 | ⬜ | — |
| 4 | `toMap` | method | 22 | ⬜ | — |
| 5 | `fromMap` | factory | 35 | ⬜ | — |
| 6 | `_parseColorIndex` | static private | 5 | ⬜ | — |

---

## 1. normalize (static)

**التوقيع:** `static String normalize(String text)`
**الأسطر:** 54 → 67 (14 سطر)

### التحليل
- دالة نقية (pure function) — لا آثار جانبية
- تُستدعى من: constructor, copyWith, SearchMixin, NotesProvider
- مهمة واحدة واضحة: تطبيع النص العربي للبحث

### القرار: ✅ لا تغيير مطلوب
- الدالة قصيرة ومحددة المهمة
- التسمية واضحة
- لا تعقيد زائد

---

## 2. isEncrypted (getter)

**التوقيع:** `bool get isEncrypted`
**الأسطر:** 70 → 74 (5 سطر)

### التحليل
- getter نقي — لا آثار جانبية
- المنطق: يتحقق من نمط `iv:ciphertext` (جزأين مفصولين بـ `:` والأول ≥ 16 حرف)

### ⚠️ اكتشاف: ازدواجية مع VaultService

| الموقع | الاستخدام |
|--------|-----------|
| `Note.isEncrypted` | يُستخدم في **الاختبارات فقط** |
| `VaultService.isEncrypted(text)` | يُستخدم في **كود الإنتاج** (storage_service, notes_provider, json_import_handler) |

**المنطق متطابق** في كلا المكانين. هذه ازدواجية واضحة.

### الخيارات المطروحة
1. **حذف `Note.isEncrypted`** وتوحيد الاستخدام على `VaultService.isEncrypted(note.content)`
2. **إبقاء `Note.isEncrypted`** كـ convenience getter يستدعي `VaultService.isEncrypted(content)` داخلياً
3. **لا تغيير** — الازدواجية بسيطة ولا تسبب مشاكل عملية

### القرار: ⏳ ينتظر قرارك

---
