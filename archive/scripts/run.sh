#!/bin/bash

BUNDLE_PATH="build/linux/x64/release/bundle"

if [ ! -d "$BUNDLE_PATH" ]; then
    echo "❌ التطبيق غير مبني! قم بتشغيل ./build_linux.sh أولاً"
    exit 1
fi

echo "🚀 تشغيل Apex Note..."
cd "$BUNDLE_PATH" && ./apex_note
