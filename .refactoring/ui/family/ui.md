# 👸 الأميرة المدللة — UI (Screens & Widgets)

**الملفات الرئيسية:**
- `lib/screens/mobile/home_screen.dart`
- `lib/screens/mobile/locked_notes_screen.dart`
- `lib/screens/auth/vault_unlock_screen.dart`
- `lib/screens/auth/locked_notes_intro_screen.dart`
- `lib/screens/shared/main_layout_screen.dart`

---

## home_screen.dart

### ValueNotifiers (11 في شاشة واحدة)
| الاسم | النوع | الغرض |
|-------|-------|-------|
| `_filteredNotesNotifier` | `ValueNotifier<List<Note>>` | الملاحظات المفلترة |
| `_totalCountNotifier` | `ValueNotifier<int>` | العدد الكلي |
| `_visibleCountNotifier` | `ValueNotifier<int>` | العدد المرئي |
| `_viewTypeNotifier` | `ValueNotifier<String>` | نوع العرض |
| `_selectedNoteIdsNotifier` | `ValueNotifier<Set<int>>` | الملاحظات المحددة |
| `_activeFilterNotifier` | `ValueNotifier<String?>` | الفلتر النشط |
| `_isPullingNotifier` | `ValueNotifier<bool>` | حالة السحب |
| `_pullDistanceNotifier` | `ValueNotifier<double>` | مسافة السحب |
| `_isRefreshingNotifier` | `ValueNotifier<bool>` | حالة التحديث |

**ملاحظة:** `_viewType` و `_viewTypeNotifier` يحملان نفس القيمة — ازدواجية.

### المشاكل
| الكود | المشكلة |
|-------|---------|
| `_onSearchChanged()` جسم فارغ | دالة بلا محتوى — كود ميت |
| `_navigateToEditor` ينشئ `Note` كامل | منطق أعمال في UI |
| `_loadViewType()` async في initState | يمكن دمجها مع `initState` |

---

## locked_notes_screen.dart

### المشاكل
| # | المشكلة | الخطورة |
|---|---------|---------|
| UI1 | `_ImportSheet` (300+ سطر) داخل نفس الملف | 🟠 |
| UI2 | البحث في `_ImportSheet` يستخدم `toLowerCase()` | 🟠 |
| UI3 | `_displayInfo()` تفك تشفير JSON يدوياً | 🟡 |
| UI4 | `final bool _isAuthenticating = false` — لا يتغير أبداً | 🟡 |
| UI5 | `onToggleSearch` يستخدم `' '` كـ toggle (تم إصلاحه في responsive) | 🔴 |

```dart
// UI5 — لا يزال في locked_notes_screen.dart (mobile):
onToggleSearch: () => setState(() {
  if (searchController.text.isNotEmpty) {
    searchController.clear();
  } else {
    searchController.text = ' '; // ← hack قديم
  }
}),
```

---

## vault_unlock_screen.dart

### 3 modes في widget واحد
```
VaultUnlockScreen
├── _buildPasswordMode()    ← الوضع الافتراضي
├── _buildRecoveryMode()    ← عند نسيان كلمة المرور
└── _buildNewPasswordMode() ← بعد الاسترداد
```
**الأثر:** 4 controllers + 5 bool flags في state واحد.

### المشاكل
| # | المشكلة | الخطورة |
|---|---------|---------|
| UI6 | `didChangeDependencies()` فارغة تماماً | 🟢 |
| UI7 | `FutureBuilder` لـ biometric داخل `_buildPasswordMode` — يُعاد بناؤه مع كل setState | 🟠 |
| UI8 | `_validatePassword` دالة top-level خارج الـ class | 🟡 |
| UI9 | `_passwordFormatter` RegExp يُنشأ مرة واحدة — جيد، لكن top-level | 🟡 |

---

## locked_notes_intro_screen.dart

### المشاكل
| # | المشكلة | الخطورة |
|---|---------|---------|
| UI10 | `_totalPages = 4` hardcoded لكن `pageCount` يتغير حسب biometrics | 🟡 |
| UI11 | `_buildBottomButton` منطق معقد inline | 🟡 |

---

## main_layout_screen.dart

### المشاكل
| # | المشكلة | الخطورة |
|---|---------|---------|
| UI12 | `_cachedScreens` يُنشأ في `initState` لكن يحتوي على `_showAddMenu` — لا يتحدث عند تغييره | 🔴 |
| UI13 | `onCategoriesRefreshNeeded` يُسجَّل في `addPostFrameCallback` — متأخر | 🟡 |

```dart
// UI12 — المشكلة:
_cachedScreens = [
  HomeScreenResponsive(
    showAddMenu: _showAddMenu, // ← قيمة ثابتة عند الإنشاء!
    onToggleMenu: _toggleMenu,
    ...
  ),
  ...
];
// عند _toggleMenu → setState → لكن _cachedScreens لا يُعاد بناؤه
// الحل الحالي: HomeScreenResponsive يستقبل callback ويدير حالته
// → يعمل لكن التصميم مربك
```

---

## التقييم الإجمالي

| الشاشة | الدرجة |
|--------|--------|
| `home_screen` | 6/10 |
| `locked_notes_screen` | 5/10 |
| `vault_unlock_screen` | 6/10 |
| `locked_notes_intro_screen` | 7/10 |
| `main_layout_screen` | 7/10 |
| **المتوسط** | **6.2/10** |
