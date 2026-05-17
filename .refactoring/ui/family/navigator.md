# 🧭 الابن المطيع — Navigation

**الملفات المعنية:** كل شاشة تتنقل بنفسها
**الدور:** الانتقال بين الشاشات — حالياً بلا مركز

---

## الخريطة الحالية

```
SplashScreen
    │
    ▼
MainLayoutScreen (IndexedStack)
    ├── [0] HomeScreenResponsive
    ├── [1] ReminderDashboardResponsive
    └── [2] CodeTabResponsive
         │
         ▼ (Navigator.push من أي شاشة)
    NoteEditorImmersive
         │
         ▼ (من HomeScreen أو LockedNotesScreen)
    VaultEntryScreen
         │
         ├── LockedNotesIntroScreen → LockedNotesScreen
         └── VaultUnlockScreen → LockedNotesScreen
```

---

## نقاط التنقل الحالية

| من | إلى | الطريقة |
|----|-----|---------|
| `HomeScreen` | `NoteEditorImmersive` | `Navigator.push` مباشر |
| `LockedNotesScreen` | `NoteEditorImmersive` | `Navigator.push` مباشر |
| `VaultUnlockScreen` | `LockedNotesScreen` | `Navigator.pushReplacement` |
| `LockedNotesIntroScreen` | `LockedNotesScreen` | `Navigator.pushReplacement` |
| `LockedNotesScreen` | `MainLayoutScreen` | `Navigator.popUntil(isFirst)` |
| `MainLayoutScreen` | `SplashScreen` | `Navigator.pushReplacement` (عند القفل) |
| `SecurityController` | `SplashScreen` | `Navigator.pushReplacement` (من listener) |

---

## المشاكل المكتشفة

### 🔴 N1 — `popUntil(isFirst)` هش
```dart
// في LockedNotesScreen.onPopInvoked:
Navigator.of(context).popUntil((route) => route.isFirst);

// في didChangeAppLifecycleState:
Navigator.of(context).popUntil((route) => route.isFirst);
```
**الأثر:** يفترض أن `MainLayoutScreen` دائماً أول route — إذا تغير الـ stack ينكسر.
**الحل:** Named routes أو RouteSettings.name للتحقق.

### 🔴 N2 — التنقل من داخل Listener
```dart
// في MainLayoutScreen:
void _onSecurityChanged() {
  if (_securityController.isLocked && mounted) {
    Navigator.of(context).pushReplacement(...SplashScreen...);
  }
}
```
**الأثر:** Navigator يُستدعى من listener — قد يحدث بعد dispose.
**الحل:** `WidgetsBinding.instance.addPostFrameCallback` أو `mounted` check أقوى.

### 🟠 N3 — لا يوجد مركز تنقل
كل شاشة تعرف عنوان الشاشة التالية مباشرة:
```dart
// VaultUnlockScreen تعرف LockedNotesScreen
Navigator.pushReplacement(context,
  MaterialPageRoute(builder: (_) => const LockedNotesScreen()));

// LockedNotesIntroScreen تعرف LockedNotesScreen
Navigator.pushReplacement(context,
  MaterialPageRoute(builder: (_) => const LockedNotesScreen()));
```
**الأثر:** تغيير اسم شاشة = تعديل في 5+ أماكن.
**الحل المقترح:** `AppRouter` مركزي أو على الأقل constants للـ routes.

### 🟡 N4 — `HomeScreen` يُنشئ `NoteEditorImmersive` مع Note كامل
```dart
// HomeScreen._navigateToEditor:
MaterialPageRoute(builder: (_) => NoteEditorImmersive(
  mode: mode,
  note: Note(title: '', content: '', ...),
))
```
**الأثر:** منطق إنشاء الملاحظة الافتراضية في الـ UI — يجب أن يكون في Provider.

---

## التقييم

| المعيار | الدرجة |
|---------|--------|
| مركزية التنقل | 3/10 |
| أمان الـ stack | 5/10 |
| سهولة التعديل | 4/10 |
| **الإجمالي** | **4/10** |

**الحكم:** أكبر مشكلة هيكلية — لكن تأثيرها على المستخدم محدود حالياً.
