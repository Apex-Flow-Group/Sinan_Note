# 🧭 مشاكل التنقل — Navigation Issues

> آخر تحديث: 2026-05-17

---

## NAV-HERO — Hero يطير فوق BottomNavBar وشريط الإشعارات

### الوصف
عند تفعيل Hero Animation وفتح نوتة، الـ Hero يطير فوق **كل شيء** — BottomNavBar وشريط الإشعارات (SearchBar/SmartHeader).

### السبب الجذري
الـ Hero يطير في `Navigator.overlay` — وهو فوق كل الـ widgets في الـ widget tree بما فيها:
- `BottomNavBar` (Positioned في Stack)
- `SmartHeader` / شريط البحث
- أي widget خارج الـ route المفتوح

### ما جُرِّب ولم ينجح

| المحاولة | النتيجة |
|---------|---------|
| `opaque: true` في `EditorPageRoute` | لا يُقيّد الـ Hero |
| `Material` wrapper في `transitionsBuilder` | لا يُقيّد الـ Hero |
| `MediaQuery.removePadding` في `pageBuilder` | لا يُقيّد الـ Hero |
| `bottomNavHiddenNotifier = true` قبل الانتقال | hack — يُخفي BottomNavBar لكن لا يحل المشكلة |
| نقل BottomNavBar إلى `Scaffold.bottomNavigationBar` | لا يُقيّد الـ Hero (overlay فوق Scaffold) |
| **Nested Navigator** في `body` | **كسر**: زر الإضافة العائم ارتفع، التبويب الجانبي تأثر، padding مكسور |

### الحل الصحيح (لم يُنفَّذ)
**go_router ShellRoute** أو **Navigator 2.0** — يُنشئ بنية routing حيث الـ Hero يطير داخل الـ shell فقط:

```
MaterialApp.router (go_router)
└── ShellRoute
    ├── BottomNavBar  ← داخل الـ shell، خارج الـ Hero overlay
    └── child: الشاشة الحالية
        └── Hero يطير هنا فقط ✅
```

### الحالة الحالية
🔴 **غير محلولة** — Hero Animation مُعطَّل بالقوة في الكود:

```dart
// settings_provider.dart — _loadSettings():
_heroAnimationEnabled = prefs.getBool('heroAnimationEnabled') ?? false;
// Hero Animation معطّل حتى يُحل NAV-HERO (Shell Route)
_heroAnimationEnabled = false;
```

الإعداد **يُحفظ** في `SharedPreferences` لكن **لا يُطبَّق** حتى يُحل NAV-HERO.

### شرط الحل
يحتاج إعادة هيكلة الـ routing الرئيسي باستخدام go_router أو Navigator 2.0 — تغيير كبير يؤثر على كل الـ app.

### الأولوية
🔴 يجب حله قبل إطلاق Hero Animation للمستخدمين

---

## NAV-DRAWER — "حول" و"تواصل" من الخزنة

### الوصف
عند فتح الخزنة ثم الضغط على "حول" أو "تواصل" من الـ Drawer، الـ dialog لا يفتح بشكل صحيح.

### السبب الجذري
نفس المشكلة الجذرية — لا يوجد مركز تنقل يعرف حالة الـ stack الكاملة.

### الحالة الحالية
🟠 **جزئياً محلولة** — الكود الحالي يُغلق الـ Drawer ثم يفتح الـ dialog، لكن السلوك يعتمد على timing.

---

## الخلاصة

```
المشكلة الجذرية:
  Navigator.overlay فوق كل شيء في الـ widget tree
  → Hero يطير فوق BottomNavBar وشريط الإشعارات

الحلول المُجرَّبة: 6 محاولات — كلها فشلت أو أحدثت مشاكل جديدة

الحل الوحيد الصحيح:
  go_router ShellRoute أو Navigator 2.0
  → تغيير هيكلي كبير للـ routing

الوضع الحالي:
  Hero Animation مُعطَّل بالقوة
  الإعداد يُحفظ لكن لا يُطبَّق
  ينتظر الريفاكتور القادم
```
