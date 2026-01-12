# 📝 Sinan Note | سنان نوت

## Overview

**Sinan Note** is an intelligent note-taking application designed with the philosophy of **Speed, Security, and Simplicity**. Built with Flutter to provide a seamless experience across Android, Linux, and Windows platforms.

> **"Sinan"** means sharpness and precision - exactly what the perfect note-taking tool should be.

### 🎯 Vision

- **⚡ Speed**: Lightning-fast interface with instant auto-save
- **🔒 Security**: Smart vault with AES-256 encryption and temporary sessions
- **🎨 Simplicity**: Clean design supporting RTL/LTR with Material Design 3

---

## ✨ Key Features

### 🔐 Smart Vault
- **AES-256 Encryption**: Military-grade protection for sensitive notes
- **Temporary Session**: Vault unlocks for 5 minutes only, then auto-locks
- **Memory Wipe**: Instant RAM cleanup when exiting or backgrounding the app
- **Biometric Authentication**: Fingerprint/Face ID support (device-dependent)

### 📝 Note Types
1. **Simple Notes**: For quick daily journaling
2. **Professional Notes**: Advanced code editor with Syntax Highlighting for 20+ languages
3. **Checklists**: Interactive task lists with progress tracking
4. **Reminders**: Smart notification scheduling with recurrence (daily/weekly/monthly)

### 🚀 Performance & Experience
- **Auto-Save**: No need to press "Save" - everything saves instantly
- **Smart Search**: Filter by type, status, or text content
- **Flexible Views**: Grid or List (expanded/compact)
- **Slivers Performance**: Smooth scrolling even with thousands of notes
- **RTL/LTR Support**: Seamless switching between Arabic and English

### 🎨 Customization
- **Dynamic Colors**: Material You (Android 12+)
- **Dark Mode**: Automatic or manual toggle
- **Text Size**: Adjustable (0.8x - 1.5x)
- **Background Blur**: Privacy protection when switching apps

### 🔄 Backup & Sharing
- **Export/Import**: Local JSON backup
- **Google Drive**: Cloud sync (coming soon)
- **P2P Transfer**: Share notes between devices via WiFi Direct
- **Quick Share**: Export to any app

### 📱 Additional Features
- **Archive**: Hide old notes without deleting
- **Trash**: Restore deleted notes within 30 days
- **Pinning**: Keep important notes at the top
- **Widgets**: Display notes on home screen (Android)
- **File Reception**: Open text files directly from other apps

---

## 📸 Screenshots

> **Note**: Screenshots will be added soon

```
[Home Screen - Grid View]
[Professional Code Editor]
[Locked Vault]
[Reminders]
[Settings]
```

---

## 🛠️ Installation & Build

### Requirements
- Flutter SDK 3.0.0 or newer
- Dart SDK 3.0.0 or newer
- Android Studio / VS Code (for development)

### Building for Android

#### 1. Install Dependencies
```bash
flutter pub get
```

#### 2. Build APK
```bash
# Release build (signed)
flutter build apk --release

# Debug build (for testing)
flutter build apk --debug
```

#### 3. Build App Bundle (for Google Play)
```bash
flutter build appbundle --release
```

**Output Location:**
- APK: `build/app/outputs/flutter-apk/app-release.apk`
- Bundle: `build/app/outputs/bundle/release/app-release.aab`

### Building for Linux
```bash
flutter build linux --release
```

### Building for Windows
```bash
flutter build windows --release
```

### Quick Run (for development)
```bash
# Android
flutter run

# Linux
flutter run -d linux

# Windows
flutter run -d windows
```

---

## 🏗️ Technical Architecture

The project is built on **Clean Architecture** with clear separation of concerns:

```
lib/
├── models/          # Data models (Note, NoteMode, Exceptions)
├── services/        # Business logic (Providers, Database, Encryption)
├── screens/         # User interfaces (Home, Editor, Settings)
├── widgets/         # Reusable components
├── utils/           # Helper utilities
└── l10n/            # Translations (AR/EN)
```

**For more technical details, see:** [ARCHITECTURE.md](ARCHITECTURE.md)

---

## 📚 User Guide

For detailed explanation of all features, see: [USER_MANUAL.md](USER_MANUAL.md)

### Quick Start

1. **Create a New Note**
   - Tap the `+` button at the bottom
   - Choose note type (simple/professional/checklist)

2. **Using the Vault**
   - Open side menu → "Vault"
   - Enter fingerprint/PIN
   - Session expires automatically after 5 minutes

3. **Search & Filter**
   - Tap the search bar
   - Use filter icon to sort by type

4. **Backup**
   - Settings → Backup
   - Choose "Export" to save local copy

---

## 🔧 Configuration

### `pubspec.yaml` File
Contains all essential dependencies:
- `provider`: State management
- `sqflite`: Local database
- `encrypt`: AES-256 encryption
- `flutter_local_notifications`: Reminders
- `local_auth`: Biometric authentication
- `flutter_code_editor`: Code editor

### `android/key.properties` File
For app signing (not included in Git):
```properties
storePassword=<your_password>
keyPassword=<your_password>
keyAlias=sinan-release-key
storeFile=sinan-release-key.jks
```

---

## 🤝 Contributing

We welcome contributions! Please follow these steps:

1. Fork the project
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code Standards
- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart)
- Run `flutter analyze` before committing
- Add comments for complex code
- Write tests for new features

---

## 📄 License

```
Copyright © 2025 Apex Flow Group. All rights reserved.
```

This project is protected by copyright. Personal use is permitted, commercial use requires permission.

---

## 📞 Contact & Support

- **Email**: support@apexflow.dev
- **GitHub Issues**: [Report a Bug](https://github.com/apexflow/sinan-note/issues)
- **Documentation**: [Wiki](https://github.com/apexflow/sinan-note/wiki)

---

## 🙏 Acknowledgments

- **Flutter Team**: For the amazing framework
- **Material Design**: For the beautiful design system
- **Arab Community**: For support and suggestions

---

## 🗺️ Roadmap

### Next Release (v2.2.0)
- [ ] Full Google Drive sync
- [ ] Markdown support in simple editor
- [ ] PDF export
- [ ] Share notes via link

### Future
- [ ] iOS version
- [ ] Web version
- [ ] Multi-user collaboration
- [ ] Image and attachment support

---

<div align="center">

**Made with ❤️ in the Arab World**

[⬆ Back to Top](#-sinan-note--سنان-نوت)

</div>
