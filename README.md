<div align="left">

[🇸🇦 العربية](README.ar.md)

</div>

<div align="center">

<img src="assets/images/app_icon.png" width="100" alt="Sinan Note Icon"/>

# Sinan Note

**A fast, secure note-taking app — built with Flutter**

[![Version](https://img.shields.io/badge/version-3.2.0-blue.svg)](https://github.com/Apex-Flow-Group/Sinan_Note/releases)
[![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B.svg?logo=flutter)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/platform-Android%20%7C%20Linux%20%7C%20Windows-lightgrey.svg)](#)
[![License](https://img.shields.io/badge/license-Proprietary-red.svg)](#license)
[![SinanAi](https://img.shields.io/badge/SinanAi.net-Innovative%20Apps-orange.svg)](https://sinanai.net/en)
[![Apex Flow](https://img.shields.io/badge/Apex%20Flow%20Group-Official-blueviolet.svg)](https://apexflow.now/en)

[Google Play](https://play.google.com/apps/internaltest/4701054794307352165) · [Features](#features) · [Project Structure](#project-structure) · [Getting Started](#getting-started)

</div>

---

## Features

| Feature | Details |
|---------|---------|
| 🔐 Smart Vault | AES-256 encryption + biometric auth + PBKDF2 (100,000 iterations) |
| 💻 Code Editor | 26 programming languages with automatic syntax highlighting |
| 👁️ Code Preview | SVG as real image, formatted JSON, preview for all languages |
| 📥 Code Download | Save directly to Downloads with the correct file extension |
| 📝 Note Types | Plain text / Code / Checklist / Reminder / Rich text |
| 🌍 Bilingual | Arabic and English with automatic RTL/LTR detection |
| 🎨 Material You | Dynamic colors + dark/light mode |
| 🔄 Google Drive | Auto-sync with smart merge and conflict resolution |
| 🗂️ Catalogs | Organize notes into groups with a smart Drawer |
| 🖥️ Desktop | Master-Details layout for large screens |
| 📱 Home Widget | Display reminders on the home screen |
| 🕐 Version History | Track edits for every note (up to 5 versions) |

---

## Project Structure

```
lib/
├── controllers/          # State management (Provider)
│   ├── categories/       # CategoriesProvider
│   ├── editor/           # EditorStateManager
│   ├── notes/            # NotesProvider
│   └── settings/         # SettingsProvider
├── core/                 # Constants, themes, shared utilities
│   ├── constants/
│   ├── shortcuts/        # Keyboard shortcuts
│   ├── theme/
│   └── utils/            # NoteContentUtils, VaultNavigator, ...
├── models/               # Data models (SQLite)
├── screens/
│   ├── auth/             # Vault: entry, reset, biometric
│   ├── desktop/          # Responsive layouts for large screens
│   ├── mobile/           # Main mobile screens
│   ├── onboarding/       # Splash, Tour, What's New
│   ├── shared/
│   │   ├── note_editor/  # Note editor (split into 9 sub-folders)
│   │   ├── settings/     # Settings (split)
│   │   └── tabs/         # Code Tab, Reminder Dashboard
│   └── sync/             # Google Drive
├── services/             # Business logic
│   ├── cloud/            # Google Drive Auth + Merge
│   ├── security/         # Encryption + Biometric + Rate Limiter
│   ├── storage/          # SQLite + Backup + DB Inspector
│   ├── sync/             # Cloud Sync Gateway
│   └── note_services/    # CRUD + Security + Side Effects
└── widgets/              # UI components
    ├── editor/           # Toolbar, CodeEditor, ChecklistEditor
    ├── home/             # NoteCard, Grid, Drawer, SmartHeader
    └── common/           # Shared components
```

---

## Database

The app uses **SQLite** (sqflite) as the primary database:

```
SQLite (sinan_notes.db)
├── notes              — Main notes
├── categories         — Catalogs
├── note_versions      — Version history
└── deleted_notes      — Deletion log for smart sync
```

> The schema is ready for migration to React Native.

---

## Getting Started

```bash
git clone https://github.com/Apex-Flow-Group/Sinan_Note.git
cd Sinan_Note
flutter pub get
flutter run
```

### Build Requirements

| Requirement | Version |
|-------------|---------|
| Flutter SDK | 3.0+ |
| Dart SDK | 3.0+ |
| Android SDK | compileSdk 36 / targetSdk 35 |

### Running Tests

```bash
flutter test
flutter analyze
```

> **469 tests** — 100% passing ✅

---

## Security

Vault encryption architecture:

```
Layer 1 — Password
    PBKDF2-SHA256 (100,000 iterations) → derived key (32 bytes)

Layer 2 — Master Key
    AES-256-CBC → stored in FlutterSecureStorage (Android Keystore)

Layer 3 — Note Content
    AES-256-CBC + random IV → "iv_base64:ciphertext_base64"
```

- Progressive rate limiter: 5 attempts → 15 min lockout → 60 min
- Vault notes are never uploaded to Google Drive
- Clipboard Guard prevents copying encrypted content

---

## Stats

| Metric | Value |
|--------|-------|
| Dart files | 244 files |
| Lines of code | ~53,144 lines |
| Widgets | 187 (97 Stateful + 90 Stateless) |
| Tests | 469 tests |
| Translation keys | ~695 keys (AR + EN) |
| Dependencies | 33 packages |
| Commits | 162+ commits |

---

## License

```
Copyright © 2025–2026 Apex Flow Group. All rights reserved.
```

This project is proprietary. All rights reserved by Apex Flow Group.

---

<div align="center">

**[SinanAi.net](https://sinanai.net/en) — Innovative Apps &nbsp;·&nbsp; [Apex Flow Group](https://apexflow.now/en) — Official**

</div>
