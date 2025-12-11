#!/bin/bash

echo "=========================================="
echo "   Sinan Note - APK Installer"
echo "   Copyright © 2025 Apex Flow Group"
echo "=========================================="
echo ""

# Auto-detect ADB
if ! command -v adb &> /dev/null; then
    echo "⚠️  ADB not in PATH, searching..."
    
    ADB_PATHS=(
        "$HOME/Android/Sdk/platform-tools"
        "$HOME/android-sdk/platform-tools"
        "$ANDROID_HOME/platform-tools"
        "/usr/local/android-sdk/platform-tools"
        "$HOME/Library/Android/sdk/platform-tools"
    )
    
    for path in "${ADB_PATHS[@]}"; do
        if [ -f "$path/adb" ]; then
            export PATH="$PATH:$path"
            echo "✅ Found ADB at: $path"
            break
        fi
    done
    
    if ! command -v adb &> /dev/null; then
        echo "❌ ADB not found!"
        exit 1
    fi
fi

echo ""
echo "📱 SELECT FLAVOR TO INSTALL:"
echo ""
echo "  1) Google Play (No P2P Transfer)"
echo "  2) F-Droid (Full Features)"
echo ""
read -p "Enter choice (1-2): " FLAVOR_CHOICE

case $FLAVOR_CHOICE in
    1)
        FLAVOR="googlePlay"
        FLAVOR_NAME="Google Play"
        ;;
    2)
        FLAVOR="fDroid"
        FLAVOR_NAME="F-Droid"
        ;;
    *)
        echo "❌ Invalid choice!"
        exit 1
        ;;
esac

APK_FILE="build/app/outputs/flutter-apk/app-$FLAVOR-release.apk"

if [ ! -f "$APK_FILE" ]; then
    echo ""
    echo "❌ APK not found: $APK_FILE"
    echo ""
    echo "Build it first:"
    echo "  ./build_android.sh $FLAVOR_CHOICE"
    echo ""
    exit 1
fi

echo ""
echo "📱 Installing $FLAVOR_NAME APK..."
echo ""

adb install -r "$APK_FILE"

if [ $? -eq 0 ]; then
    echo ""
    echo "=========================================="
    echo "✅ $FLAVOR_NAME installed successfully!"
    echo "=========================================="
    echo ""
else
    echo ""
    echo "=========================================="
    echo "❌ Installation failed!"
    echo "Make sure:"
    echo "- Device is connected"
    echo "- USB debugging is enabled"
    echo "- ADB drivers are installed"
    echo "=========================================="
    exit 1
fi
