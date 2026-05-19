# Contributing Guide

We welcome all contributions — bug fixes, new features, documentation improvements, or suggestions.

---

## Development Setup

### Requirements

| Requirement | Version |
|-------------|---------|
| Flutter SDK | 3.0.0+ |
| Dart SDK | 3.0.0+ |
| Android Studio / VS Code | Latest |
| Git | Any |

### Setup Steps

```bash
# 1. Fork the project on GitHub then clone
git clone https://github.com/YOUR_USERNAME/Sinan_Note.git
cd Sinan_Note

# 2. Add upstream remote
git remote add upstream https://github.com/Apex-Flow-Group/Sinan_Note.git

# 3. Install dependencies
flutter pub get

# 4. Verify no errors
flutter analyze
flutter test
```

---

## Code Standards

### Dart Style

- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart)
- Use `Theme.of(context).colorScheme` instead of hardcoded colors
- Use `EdgeInsetsDirectional` for RTL support
- Every `try/catch` must handle the error or rethrow it — no silent swallowing
- New files should not exceed 400 lines — split if needed

### Error Handling

```dart
// ✅ Correct
try {
  await riskyOperation();
} catch (e, stack) {
  AppLogger.error('RiskyOp', e, stack);
  rethrow;
}

// ❌ Wrong — silent swallow
try {
  await riskyOperation();
} catch (_) {}
```

### RTL Support

```dart
// ✅ Correct
Padding(padding: EdgeInsetsDirectional.only(start: 16))

// ❌ Wrong — won't work with RTL
Padding(padding: EdgeInsets.only(left: 16))
```

### Commit Messages

```
feat: add new feature
fix: fix a bug
refactor: restructure code
docs: update documentation
style: formatting (no logic change)
test: add tests
chore: maintenance tasks
```

---

## Pull Request Process

```bash
# 1. Create a new branch
git checkout -b feat/amazing-feature

# 2. Write code + tests

# 3. Verify
flutter analyze
flutter test

# 4. Commit
git commit -m "feat: Add amazing feature"

# 5. Push
git push origin feat/amazing-feature
```

Then open a Pull Request on GitHub with a clear description of the changes.

---

## Reporting Bugs

Open an Issue with:
- Steps to reproduce
- Expected vs actual behavior
- Device and Android version
- Screenshot if possible

---

## Contact

- **Email:** contact.apex.flow@gmail.com
