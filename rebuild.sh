#!/bin/bash
# Force clean rebuild to see diagnostic logs

echo "🧹 Cleaning build cache..."
flutter clean

echo "📦 Getting dependencies..."
flutter pub get

echo "🔨 Building debug APK..."
flutter build apk --debug

echo "✅ Done! Install the APK from: build/app/outputs/flutter-apk/app-debug.apk"
echo ""
echo "Or run directly with: flutter run"
