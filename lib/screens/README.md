# Screens Directory Structure

## Overview
This directory contains all UI screens organized by platform and functionality.

## Directory Structure

### 📱 `mobile/`
Base mobile screens with mobile-first design:
- `home_screen.dart` - Main home screen with notes grid
- `archive_screen.dart` - Archived notes view
- `trash_screen.dart` - Deleted notes (trash bin)
- `locked_notes_screen.dart` - Secure vault notes

### 🖥️ `desktop/`
Responsive versions with master-details layout:
- `home_screen_responsive.dart` - Desktop home with side panel
- `archive_screen_responsive.dart` - Desktop archive view
- `trash_screen_responsive.dart` - Desktop trash view
- `locked_notes_screen_responsive.dart` - Desktop vault view

### 🔄 `shared/`
Cross-platform shared screens:
- `note_editor.dart` - Note editing screen
- `note_view_screen.dart` - Note viewing screen
- `settings_screen.dart` - App settings
- `settings_screen_responsive.dart` - Responsive settings
- `main_layout_screen.dart` - Main app layout wrapper

**Subdirectories:**
- `note_editor/` - Editor components (controllers, dialogs, handlers, widgets)
- `note_view/` - View components (bars, helpers, widgets)
- `settings/` - Settings components (dialogs, handlers, utils)
- `tabs/` - Tab screens (code tab, reminder dashboard)

### 🔐 `auth/`
Authentication and security screens:
- `vault_entry_screen.dart` - Vault entry point
- `vault_unlock_screen.dart` - Vault unlock with PIN/biometric
- `locked_notes_intro_screen.dart` - Vault introduction

### 🎬 `onboarding/`
First-time user experience:
- `splash_screen.dart` - App splash screen
- `cinematic_intro_screen.dart` - Animated introduction
- `tour_screen.dart` - Feature tour
- `terms_screen.dart` - Terms and conditions

### ☁️ `sync/`
Cloud synchronization screens:
- `google_drive_screen.dart` - Google Drive sync
- `google_drive_screen_responsive.dart` - Responsive Drive sync
- `google_drive_sync_terms_screen.dart` - Sync terms
- `google_drive/` - Drive-specific components

### 📦 `other/`
Miscellaneous screens:
- `about_screen.dart` - About app information
- `support_form_screen.dart` - User support form
- `version_history_screen.dart` - Version changelog
- `widget_selection_screen.dart` - Home widget configuration

## Import Guidelines

### From `lib/screens/mobile/`:
```dart
import '../shared/note_editor.dart';              // Shared screen
import '../desktop/home_screen_responsive.dart';  // Desktop screen
import '../../models/note.dart';                  // Model from lib root
```

### From `lib/screens/shared/`:
```dart
import '../mobile/home_screen.dart';              // Mobile screen
import '../../services/storage/isar_database_service.dart';  // Service
```

### From `lib/widgets/`:
```dart
import '../screens/shared/note_editor.dart';      // Screen
import '../models/note.dart';                     // Model
```

### From `lib/main.dart`:
```dart
import 'screens/onboarding/splash_screen.dart';
import 'screens/shared/note_editor.dart';
import 'screens/mobile/home_screen.dart';
```

## Adding New Screens

### Mobile Screen
1. Create in `mobile/` directory
2. Follow mobile-first design patterns
3. Consider creating responsive version in `desktop/`

### Desktop Screen
1. Create in `desktop/` directory
2. Import corresponding mobile screen
3. Wrap with master-details layout

### Shared Screen
1. Create in `shared/` directory
2. Ensure cross-platform compatibility
3. Use responsive design patterns

### Feature-Specific Screen
1. Determine category (auth, sync, onboarding, other)
2. Create in appropriate directory
3. Follow existing patterns

## Best Practices

1. **Separation of Concerns**: Keep platform-specific code in respective directories
2. **Reusability**: Use `shared/` for cross-platform screens
3. **Organization**: Group related components in subdirectories
4. **Naming**: Use descriptive names with `_screen.dart` suffix
5. **Imports**: Use relative imports within screens, absolute for external dependencies

## Architecture

```
Screen
  ├── State Management (Provider)
  ├── UI Components (Widgets)
  ├── Business Logic (Services)
  └── Data Models (Models)
```

## Related Documentation

- [SCREENS_REORGANIZATION.md](../../SCREENS_REORGANIZATION.md) - Reorganization details
- [ARCHITECTURE.md](../../ARCHITECTURE.md) - Overall architecture
- [DEVELOPER_GUIDE.md](../../DEVELOPER_GUIDE.md) - Development guidelines

---

**Last Updated**: February 12, 2026
**Version**: 1.0.0
