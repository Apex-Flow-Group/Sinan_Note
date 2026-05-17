# 📋 توثيق إعادة هيكلة UI — Sinan Note

## الفلسفة: العائلة الخمسة

```
الاستيتيوس  ──►  البروفايدر  ──►  النافيقيتور  ──►  اليو اي
   (السيد)      (سيد القصر)      (الابن المطيع)    (الأميرة)
                                                        │
                                               السيرفر (الخادم)
```

**القاعدة الذهبية:**
- السيد يأمر — لا يسأل
- البروفايدر يجهّز ويُبلّغ — لا يقرر
- النافيقيتور ينفّذ — لا يبادر
- اليو اي تطلب — لا تعمل
- السيرفر يخدم — لا يعرف من يخدم

---

## الهيكل

```
.refactoring/ui/
├── README.md                ← أنت هنا
├── family/
│   ├── state.md             ← NoteStateService (السيد)
│   ├── provider.md          ← NotesProvider (سيد القصر)
│   ├── navigator.md         ← Navigation patterns (الابن المطيع)
│   ├── ui.md                ← Screens & Widgets (الأميرة)
│   └── services.md          ← VaultService + Security (الخادم)
├── vault/
│   ├── analysis.md          ← تحليل شامل للخزنة (كل الملفات)
│   ├── flows.md             ← خرائط تدفق العمليات الكاملة
│   └── findings.md          ← المشاكل المكتشفة (محدّث)
└── findings/
    ├── navigation.md        ← مشاكل التنقل (NAV-HERO غير محلولة)
    ├── state_leaks.md       ← تسريبات الحالة
    └── ui_complexity.md     ← تعقيد الواجهة
```

---

## الحالة الحالية

| | |
|---|---|
| **البداية** | 2026-05-16 |
| **آخر تحديث** | 2026-05-17 |
| **الملفات المفحوصة** | 14/14 ✅ |
| **المشاكل المكتشفة** | 32 مشكلة |
| **المُنجز** | الجولة 1 ✅ + الجولة 2 ✅ + الجولة 3 ✅ (جزئياً) |
| **الاختبارات** | 469/469 ✅ |

---

## ملخص الإنجاز

### ✅ مكتمل

| المجال | الإنجاز |
|--------|---------|
| أمان الخزنة | SEC-1,2,4,5 — PBKDF2 + API + isEncrypted + توحيد التحقق |
| UX الخزنة | AUTH1, UI5, RESP1, ENTRY1, UX-4, UX-5 |
| Provider/State | P1, P2, M1, M2, M3 |
| Navigation الخزنة | VaultNavigator — مركز تنقل كامل لكل شاشات الخزنة |
| Navigation العام | popUntil يستخدم route name بدل isFirst |
| التنظيف | P4, UI10, SEC-3 توثيق |

### 🔴 غير محلول — يحتاج ريفاكتور قادم

| الكود | المشكلة | السبب |
|-------|---------|-------|
| **NAV-HERO** | Hero يطير فوق BottomNavBar وشريط الإشعارات | Navigator.overlay فوق كل شيء |
| | Hero Animation مُعطَّل بالقوة في الكود | ينتظر go_router ShellRoute |

**التوثيق الكامل:** `.refactoring/ui/findings/navigation.md`

### � متبقي منخفض الأولوية

| الكود | المشكلة |
|-------|---------|
| UI1 | `_ImportSheet` 300+ سطر في نفس الملف |
| P3 | `loadNotes` و `refreshAllNotes` متداخلتان |
| RATE1 | `_generateSalt()` entropy ضعيف |

---

## سجل التعديلات

### الجولة 1 — أمان الخادم

| التاريخ | الكود | التعديل | الاختبارات |
|---------|-------|---------|-----------|
| 2026-05-17 | SEC-1 | PBKDF2 10,000 → 100,000 | ✅ 469 |
| 2026-05-17 | SEC-2 | `changePassword('')` → `setPasswordAfterRecovery()` | ✅ 469 |
| 2026-05-17 | SEC-4 | `isEncrypted()` فحص طول IV | ✅ 469 |
| 2026-05-17 | SEC-5 | توحيد دوال التحقق من كلمة المرور | ✅ 469 |
| 2026-05-17 | AUTH1 | `_isAuthenticating` من `final` → `bool` | ✅ 469 |
| 2026-05-17 | UI5 | `' '` hack → `_searchActive` في SearchMixin | ✅ 469 |
| 2026-05-17 | RESP1 | Desktop يقرأ `lockedNotes` بدل `activeNotes` | ✅ 469 |
| 2026-05-17 | P1 | `convertNoteType` حذف rebuild مزدوج | ✅ 469 |
| 2026-05-17 | M2+M3 | تنظيف NoteStateService | ✅ 469 |

### الجولة 2 — تحسين هيكلي

| التاريخ | الكود | التعديل | الاختبارات |
|---------|-------|---------|-----------|
| 2026-05-17 | P2 | `copyWith` بدل قراءة DB | ✅ 469 |
| 2026-05-17 | M1 | cache لـ `reminderNotes` | ✅ 469 |
| 2026-05-17 | UI7 | `FutureBuilder` → `initState` للبصمة | ✅ 469 |
| 2026-05-17 | UX-4+5 | رسائل خطأ hardcoded → l10n | ✅ 469 |
| 2026-05-17 | ENTRY1 | نص hardcoded → `l10n.verifyingIdentity` | ✅ 469 |
| 2026-05-17 | RESET1 | `StreamController` فحص `isClosed` | ✅ 469 |

### الجولة 3 — Navigation

| التاريخ | الكود | التعديل | الاختبارات |
|---------|-------|---------|-----------|
| 2026-05-17 | N3 | `VaultNavigator` — مركز تنقل الخزنة | ✅ 469 |
| 2026-05-17 | N1 | `popUntil` يستخدم route name `/main` | ✅ 469 |
| 2026-05-17 | N2 | Navigator من Listener → `addPostFrameCallback` | ✅ 469 |
| 2026-05-17 | — | كل شاشات الخزنة ملتزمة بـ VaultNavigator | ✅ 469 |
| 2026-05-17 | — | `rootNavigator: true` لكل `popUntil` يعود للرئيسية | ✅ 469 |
| 2026-05-17 | **NAV-HERO** | **Hero يطير فوق كل شيء — غير محلول** | ❌ مُعطَّل |
