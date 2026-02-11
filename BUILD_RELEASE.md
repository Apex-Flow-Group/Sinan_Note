# 🚀 Sinan Note - Release Build Guide

## Quick Build (Recommended)

```bash
./build_release.sh
```

## Manual Build

```bash
flutter build appbundle --release --obfuscate --split-debug-info=./build/app/outputs/symbols
```

## What's Included

### ✅ Maximum Protection
- **Dart Code Obfuscation**: All class/function names scrambled
- **R8 Minification**: Android code optimized and protected
- **Resource Shrinking**: Unused resources removed

### ✅ Maximum Compression
- **Tree Shaking**: Unused code removed
- **AAB Format**: Google Play splits by device (50% smaller downloads)
- **Optimized Assets**: Images and fonts compressed

## Output Files

- **AAB**: `build/app/outputs/bundle/release/app-release.aab`
- **Symbols**: `build/app/outputs/symbols/` (Keep for crash reports!)

## Upload to Google Play

1. Go to: https://play.google.com/console
2. Select your app
3. Production → Create new release
4. Upload `app-release.aab`
5. Done! ✅

## Important Notes

⚠️ **Keep the symbols folder!** You'll need it to read crash reports from users.

📦 **AAB vs APK**: AAB is required by Google Play and produces smaller downloads.

🔒 **Obfuscation**: Makes reverse engineering nearly impossible.

---

**Made with ❤️ by Apex Flow Group**
