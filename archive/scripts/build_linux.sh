#!/bin/bash

set -e

echo "🚀 Building Sinan Note for Linux..."
echo ""

# Auto-detect Flutter
if ! command -v flutter &> /dev/null; then
    echo "⚠️  Flutter not found in PATH!"
    exit 1
fi

echo "✅ Flutter: $(flutter --version | head -n 1)"
echo ""

# Clean
echo "🧹 Cleaning..."
flutter clean

# Get packages
echo "📦 Getting packages..."
flutter pub get

# Build
echo "🔨 Building Linux release..."
flutter build linux --release

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Build Complete!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📍 Location: build/linux/x64/release/bundle/"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
else
    echo ""
    echo "❌ Build failed!"
    exit 1
fi
