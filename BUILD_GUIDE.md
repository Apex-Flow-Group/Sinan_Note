# Build Guide - Sinan Note

## Quick Build

### Linux/macOS
```bash
./build_android.sh
```

### Windows
```cmd
build_android.bat
```

## Interactive Menu

Both scripts provide an interactive menu:

```
📱 SELECT BUILD FLAVOR:

  1) Google Play (No P2P Transfer)
  2) F-Droid (Full Features)
  3) Both (Sequential)

Enter choice (1-3):
```

## Command Line Arguments

### Build Google Play Only
```bash
./build_android.sh 1
# or
build_android.bat 1
```

### Build F-Droid Only
```bash
./build_android.sh 2
# or
build_android.bat 2
```

### Build Both Sequentially
```bash
./build_android.sh 3
# or
build_android.bat 3
```

## Manual Build Commands

### Google Play
```bash
flutter build apk --flavor googlePlay --release -t lib/main.dart
flutter build appbundle --flavor googlePlay --release -t lib/main.dart
```

### F-Droid
```bash
flutter build apk --flavor fDroid --release -t lib/main.dart
flutter build appbundle --flavor fDroid --release -t lib/main.dart
```

## Output Locations

After successful build:

```
build/app/outputs/flutter-apk/
├── app-googlePlay-release.apk
└── app-fDroid-release.apk

build/app/outputs/bundle/
├── googlePlayRelease/
│   └── app-googlePlay-release.aab
└── fDroidRelease/
    └── app-fDroid-release.aab
```

## Build Time Estimates

- **Single Flavor**: ~3-5 minutes
- **Both Flavors**: ~6-10 minutes (sequential)

## Troubleshooting

### Flutter not found
Ensure Flutter is in your PATH:
```bash
export PATH="$PATH:$HOME/flutter/bin"
```

### Build fails
Try cleaning and rebuilding:
```bash
flutter clean
flutter pub get
flutter build apk --flavor googlePlay --release
```

### Permission denied (Linux/macOS)
```bash
chmod +x build_android.sh
```

## Flavor Differences

| Feature | Google Play | F-Droid |
|---------|-------------|---------|
| App Name | Sinan Note | Sinan Note (F-Droid) |
| App ID | com.apexflow.sinan | com.apexflow.sinan.fdroid |
| P2P Transfer | ❌ | ✅ |
| WiFi Permissions | ❌ | ✅ |
| Camera Permission | ❌ | ✅ |
| Size | Smaller | Larger |

## Verification

### Check APK Permissions
```bash
aapt dump permissions build/app/outputs/flutter-apk/app-googlePlay-release.apk
aapt dump permissions build/app/outputs/flutter-apk/app-fDroid-release.apk
```

### Check APK Info
```bash
aapt dump badging build/app/outputs/flutter-apk/app-googlePlay-release.apk
```
