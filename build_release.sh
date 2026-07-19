#!/bin/bash

# Sinan Note - Release Build Script
# Maximum protection + compression

export JAVA_HOME=/usr/lib/jvm/java-25-openjdk
export PATH=$JAVA_HOME/bin:$PATH

echo "🚀 Building Sinan Note - Release AAB"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Build AAB with obfuscation
echo "🔒 Building with maximum protection..."
flutter build appbundle --release \
  --obfuscate \
  --split-debug-info=./build/app/outputs/symbols \
  --android-skip-build-dependency-validation

# Check if build succeeded
if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Build successful!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📍 AAB Location:"
    echo "   build/app/outputs/bundle/release/app-release.aab"
    echo ""
    echo "🔐 Debug symbols saved to:"
    echo "   build/app/outputs/symbols/"
    echo ""
    echo "⚠️  Keep symbols folder for crash reports!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
else
    echo ""
    echo "❌ Build failed!"
    exit 1
fi
