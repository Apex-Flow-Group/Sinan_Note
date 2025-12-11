# Build Flavors - Google Play vs F-Droid

## Overview

Sinan Note now supports two build flavors to comply with different app store requirements:

- **Google Play**: No P2P/Wi-Fi transfer feature (complies with Play Store policies)
- **F-Droid**: Full P2P/Wi-Fi transfer feature enabled

## Building

### Google Play Flavor
```bash
flutter build apk --flavor googlePlay -t lib/main.dart
flutter build appbundle --flavor googlePlay -t lib/main.dart
```

### F-Droid Flavor
```bash
flutter build apk --flavor fDroid -t lib/main.dart
flutter build appbundle --flavor fDroid -t lib/main.dart
```

## Architecture

### Flavor Configuration
- **File**: `lib/config/flavor_config.dart`
- **Controls**: Feature availability at runtime
- **Flag**: `FlavorConfig.hasTransferFeature`

### Manifest Overrides
- **Base**: `android/app/src/main/AndroidManifest.xml` (core permissions only)
- **Google Play**: `android/app/src/googlePlay/AndroidManifest.xml` (no transfer permissions)
- **F-Droid**: `android/app/src/fDroid/AndroidManifest.xml` (includes transfer permissions)

### Route Registration
- **File**: `lib/main.dart`
- **Method**: Conditional route registration using `FlavorConfig.hasTransferFeature`
- **Transfer routes**: Only registered for F-Droid flavor

### UI Conditionals
- **Home Drawer**: Transfer menu item hidden in Google Play flavor
- **Implementation**: `if (FlavorConfig.hasTransferFeature)` checks

## Excluded Permissions (Google Play Only)

- `INTERNET` - HTTP server/client
- `ACCESS_WIFI_STATE` - WiFi detection
- `ACCESS_NETWORK_STATE` - Network detection
- `CAMERA` - QR code scanning
- `NEARBY_WIFI_DEVICES` - WiFi device discovery

## Excluded Packages (Optional)

For minimal Google Play APK, consider excluding:
- `shelf` - HTTP server framework
- `shelf_router` - HTTP routing
- `network_info_plus` - Network info
- `qr_flutter` - QR generation
- `mobile_scanner` - QR scanning

## Testing

### Verify Google Play Build
```bash
flutter build apk --flavor googlePlay
# Check APK permissions
aapt dump permissions build/app/outputs/apk/googlePlay/release/app-googlePlay-release.apk
```

### Verify F-Droid Build
```bash
flutter build apk --flavor fDroid
# Check APK permissions
aapt dump permissions build/app/outputs/apk/fDroid/release/app-fDroid-release.apk
```

## Files Modified

### Gradle
- `android/app/build.gradle` - Added flavor definitions

### Manifests
- `android/app/src/main/AndroidManifest.xml` - Removed transfer permissions
- `android/app/src/googlePlay/AndroidManifest.xml` - Created (empty override)
- `android/app/src/fDroid/AndroidManifest.xml` - Created (transfer permissions)

### Dart
- `lib/config/flavor_config.dart` - Created (flavor configuration)
- `lib/config/transfer_routes.dart` - Created (conditional route builder)
- `lib/main.dart` - Updated (conditional route registration)
- `lib/widgets/home/home_drawer_widget.dart` - Updated (conditional UI)

## Future Enhancements

1. **Conditional Dependencies**: Use `pubspec.yaml` conditional imports
2. **Feature Modules**: Move transfer to separate feature module
3. **Runtime Flags**: Add user-facing feature toggle
4. **Analytics**: Track feature usage by flavor
