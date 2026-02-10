# 🎨 Design Guide | دليل التصميم

## Material Design 3

### Colors | الألوان
```dart
// Use theme colors
Theme.of(context).colorScheme.primary
Theme.of(context).colorScheme.surface
```

### Typography | الخطوط
```dart
Theme.of(context).textTheme.headlineMedium
Theme.of(context).textTheme.bodyLarge
```

## RTL Support | دعم العربية

### Directional Padding
```dart
// ✅ Correct
EdgeInsetsDirectional.only(start: 16)

// ❌ Wrong
EdgeInsets.only(left: 16)
```

### Text Direction
```dart
Directionality(
  textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
  child: child,
)
```

## Responsive Design | التصميم المتجاوب

```dart
final isTablet = MediaQuery.of(context).size.width > 600;
final columns = isTablet ? 3 : 2;
```

## Components | المكونات

- Cards: Elevated with rounded corners
- Buttons: Filled, outlined, text
- Dialogs: Material 3 style
- Bottom sheets: Rounded top corners

---

See [ARCHITECTURE.md](../../ARCHITECTURE.md) for details.
