#!/bin/bash
# Quick test script for notification fixes

echo "🔔 Sinan Note - Notification Test Script"
echo "========================================"
echo ""

# Clean build
echo "📦 Cleaning previous builds..."
cd android
./gradlew clean > /dev/null 2>&1
cd ..
flutter clean > /dev/null 2>&1

echo "✅ Clean complete"
echo ""

# Get dependencies
echo "📥 Getting dependencies..."
flutter pub get > /dev/null 2>&1
echo "✅ Dependencies ready"
echo ""

# Build debug APK
echo "🔨 Building debug APK..."
flutter build apk --debug
echo "✅ Build complete"
echo ""

# Install
echo "📲 Installing on device..."
flutter install
echo "✅ Installation complete"
echo ""

# Show logs
echo "📋 Watching logs (press Ctrl+C to stop)..."
echo "Look for: 'Notification permissions granted' and 'Notification scheduled'"
echo ""
flutter logs | grep -i --color=always "notification\|reminder\|permission\|scheduled"
