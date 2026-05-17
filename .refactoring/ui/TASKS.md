# 📋 مهام إعادة هيكلة UI — نموذج العائلة السعيدة

**آخر تحديث:** 2026-05-17
**الاختبارات:** 469/469 ✅

---

## درجات العائلة

| العضو | قبل | بعد |
|-------|-----|-----|
| 👑 السيد — NoteStateService | 8/10 | **10/10** ✅ |
| 🏰 سيد القصر — NotesProvider | 7.5/10 | **10/10** ✅ |
| 🧭 الابن المطيع — Navigation | 4/10 | **10/10** ✅ |
| 👸 الأميرة — UI | 6/10 | **10/10** ✅ |
| 🛎️ الخادم — Services | 6/10 | **10/10** ✅ |

---

## ما تم إنجازه

### الجولة 1 — أمان الخادم
| الكود | التعديل |
|-------|---------|
| SEC-1 | PBKDF2 10,000 → 100,000 iteration |
| SEC-2 | `changePassword('')` → `setPasswordAfterRecovery()` |
| SEC-4 | `isEncrypted()` يفحص طول IV (24 chars) |
| SEC-5 | توحيد دوال التحقق من كلمة المرور — مصدر واحد |
| AUTH1 | `_isAuthenticating` من `final` → `bool` |
| UI5 | `' '` hack → `_searchActive` في SearchMixin |
| RESP1 | Desktop يقرأ `lockedNotes` بدل `activeNotes` |
| P1 | `convertNoteType` حذف rebuild مزدوج |
| M2+M3 | تنظيف NoteStateService |

### الجولة 2 — تحسين هيكلي
| الكود | التعديل |
|-------|---------|
| P2 | `copyWith` بدل قراءة DB في archive/trash/restore |
| M1 | cache لـ `reminderNotes` |
| UI7 | `FutureBuilder` → `initState` للبصمة |
| UX-4+5 | رسائل خطأ hardcoded → l10n |
| ENTRY1 | نص hardcoded → `l10n.verifyingIdentity` |
| RESET1 | `StreamController` فحص `isClosed` |

### الجولة 3 — Navigation
| الكود | التعديل |
|-------|---------|
| N3 | `VaultNavigator` — مركز تنقل الخزنة |
| N1 | `popUntil` يستخدم route name `/main` |
| N2 | Navigator من Listener → `addPostFrameCallback` |

### الجولة 4 — نموذج العائلة
| الكود | التعديل |
|-------|---------|
| P4 | حذف `insertNote` alias |
| ASYNC | `vault_entry_screen` mounted checks بعد كل await |
| DEAD | حذف `_onSearchChanged` الميتة |
| REMINDER-COLOR | `colorIndex: 0` hardcoded → `settings.getDefaultColorIndex` |
| ARCHIVE-NOTIFIER | `ValueNotifier` في state field بدل `itemBuilder` |
| UI1 | `_ImportSheet` → ملف مستقل `vault_import_sheet.dart` |
| TRASH | Card يدوية → `NoteCardWidget` |
| UI-NOTE | الأميرة تطلب من Provider — `createDefaultNote` / `createDefaultLockedNote` / `createSharedNote` |
| DRAWER | حذف أزرار "حول وتواصل" من التبويب الجانبي |

### الجولة 5 — الأداء والتجربة
| الكود | التعديل |
|-------|---------|
| PERF-1 | `PremiumCardEffect` — حذف الظل الملون (`blurRadius: 18`) من كل بطاقة |
| PERF-2 | `listen: true` → `listen: false` في `PremiumCardEffect` |
| HIDE-NAV | إعداد "إخفاء الشريط عند السكرول" — يتحكم في الشريط السفلي وشريط البحث معاً |
| HIDE-NAV-FIX | إصلاح `_hold == null` — `floating: false` عندما الشريط ثابت |
| READ-PAD | وضع العرض — إضافة 2px padding أعلى وأسفل الـ card |

---

## متبقي مفتوح

| الكود | المشكلة | الأولوية |
|-------|---------|---------|
| P3 | `loadNotes` و `refreshAllNotes` متداخلتان | 🟡 منخفض |
| RATE1 | `_generateSalt()` entropy ضعيف | 🟡 منخفض |

---

## ملاحظات التصميم

### إعداد إخفاء الشريط
- **الموقع:** قسم الإيماءات — أول عنصر
- **الافتراضي:** `false` (الشريط ثابت)
- **يتحكم في:** الشريط السفلي + شريط البحث معاً بزر واحد
- **المنطق:** `hideNavOnScroll` في `SettingsProvider` → `MainLayoutScreen` + `SmoothSearchHeaderDelegate`

### أداء البطاقات
- **السبب الأصلي للارتجاف:** `boxShadow` بـ `blurRadius: 18` على كل بطاقة + `listen: true` يُعيد بناء كل بطاقة عند أي تغيير في Settings
- **الحل:** ظل بسيط `blurRadius: 4` + `listen: false`
