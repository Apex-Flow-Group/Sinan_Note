#!/bin/bash

echo "==========================================="
echo "   Sinan Note - Android Builder"
echo "   Copyright © 2025 Apex Flow Group"
echo "==========================================="
echo ""

# Auto-detect Flutter
if ! command -v flutter &> /dev/null; then
    echo "⚠️  Flutter not in PATH, searching..."
    
    FLUTTER_PATHS=(
        "$HOME/flutter/bin"
        "$HOME/development/flutter/bin"
        "$HOME/snap/flutter/common/flutter/bin"
        
        "/usr/local/flutter/bin"
        "/opt/flutter/bin"
    )
    
    for path in "${FLUTTER_PATHS[@]}"; do
        if [ -f "$path/flutter" ]; then
            export PATH="$PATH:$path"
            echo "✅ Found Flutter at: $path"
            break
        fi
    done
    
    if ! command -v flutter &> /dev/null; then
        echo "❌ Flutter not found!"
        exit 1
    fi
fi

echo "✅ Flutter: $(flutter --version | head -n 1)"
echo ""

# Show menu if no argument provided
if [ -z "$1" ]; then
    echo "📱 SELECT BUILD FLAVOR:"
    echo ""
    echo "  1) Google Play (No P2P Transfer)"
    echo "  2) F-Droid (Full Features)"
    echo "  3) Both (Sequential)"
    echo ""
    read -p "Enter choice (1-3): " CHOICE
else
    CHOICE=$1
fi

build_flavor() {
    local FLAVOR=$1
    local FLAVOR_NAME=$2
    local DART_DEFINE=$3
    
    echo "🧹 Cleaning..."
    flutter clean
    
    echo ""
    echo "📦 Getting packages..."
    flutter pub get
    
    echo ""
    echo "🔨 Building $FLAVOR_NAME APK..."
    flutter build apk --flavor $FLAVOR --release --dart-define=$DART_DEFINE
    
    if [ $? -eq 0 ]; then
        echo ""
        echo "✅ $FLAVOR_NAME build completed!"
        echo ""
        
        APK_PATH="build/app/outputs/flutter-apk/app-$FLAVOR-release.apk"
        if [ -f "$APK_PATH" ]; then
            SIZE=$(du -h "$APK_PATH" | cut -f1)
            echo "📁 Location: $APK_PATH"
            echo "💾 Size: $SIZE"
        fi
    else
        echo ""
        echo "❌ $FLAVOR_NAME build failed!"
        exit 1
    fi
}

case $CHOICE in
    1)
        echo "🎯 Building Google Play flavor..."
        echo ""
        build_flavor "googlePlay" "Google Play" "FLAVOR=googlePlay"
        ;;
    2)
        echo "🎯 Building F-Droid flavor..."
        echo ""
        build_flavor "fDroid" "F-Droid" "FLAVOR=fDroid"
        ;;
    3)
        echo "🎯 Building both flavors (sequential)..."
        echo ""
        
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "Building Google Play..."
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        build_flavor "googlePlay" "Google Play" "FLAVOR=googlePlay"
        
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "Building F-Droid..."
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        build_flavor "fDroid" "F-Droid" "FLAVOR=fDroid"
        
        echo ""
        echo "==========================================="
        echo "✅ Both builds completed successfully!"
        echo "==========================================="
        echo ""
        echo "📁 APK Locations:"
        echo "  • Google Play: build/app/outputs/flutter-apk/app-googlePlay-release.apk"
        echo "  • F-Droid:     build/app/outputs/flutter-apk/app-fDroid-release.apk"
        ;;
    *)
        echo "❌ Invalid choice!"
        exit 1
        ;;
esac

echo ""
