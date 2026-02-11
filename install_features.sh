#!/bin/bash

# تثبيت الميزات الجديدة | Install New Features
# Sinan Note v2.2.0

echo "🚀 Installing new features for Sinan Note..."

# 1. Install dependencies
echo "📦 Installing dependencies..."
flutter pub get

# 2. Generate localization files
echo "🌍 Generating localization files..."
flutter gen-l10n

# 3. Build runner (if needed for Isar)
echo "🔨 Running build runner..."
flutter pub run build_runner build --delete-conflicting-outputs

# 4. Clean build
echo "🧹 Cleaning previous builds..."
flutter clean

# 5. Get dependencies again
flutter pub get

echo "✅ Installation complete!"
echo ""
echo "📝 New Features Added:"
echo "  1. ✨ Make a Copy - Duplicate notes instantly"
echo "  2. 💾 Save As - Save note with new name"
echo "  3. 📂 Open Programming Files - Open code files directly"
echo ""
echo "🔧 To build APK:"
echo "  flutter build apk --release"
echo ""
echo "🎉 Ready to test!"
