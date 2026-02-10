#!/bin/bash

# Google Play Build Script
# Builds appbundle for Google Play flavor and saves to build/google folder

set -e

echo "🚀 Starting Google Play Build..."
echo ""

# Clean cache
echo "🧹 Cleaning cache..."
flutter clean

# Get packages
echo "📦 Getting packages..."
flutter pub get

# Create output directory
mkdir -p build/google

# Build appbundle
echo "📦 Building appbundle for Google Play..."
flutter build appbundle --release --flavor googlePlay --dart-define=FLAVOR=googlePlay

# Generate timestamp for filename
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
OUTPUT_FILE="build/google/app-googlePlay-release_${TIMESTAMP}.aab"

# Copy to google folder with timestamp
echo "📁 Copying to build/google..."
cp build/app/outputs/bundle/googlePlayRelease/app-googlePlay-release.aab "$OUTPUT_FILE"

# Get file info
FILE_SIZE=$(du -h "$OUTPUT_FILE" | cut -f1)
BUILD_TIME=$(date '+%Y-%m-%d %H:%M:%S')

echo ""
echo "✅ Build Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📍 Location: $OUTPUT_FILE"
echo "📊 Size: $FILE_SIZE"
echo "⏰ Time: $BUILD_TIME"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
