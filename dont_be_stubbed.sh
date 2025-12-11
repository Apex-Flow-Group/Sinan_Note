#!/bin/bash

# 1. تحديد التاريخ والوقت بدقة (عشان لو عملت نسختين في نفس اليوم)
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M")
PROJECT_NAME="Sinan_Note"
OUTPUT_FILE="${PROJECT_NAME}_Golden_${TIMESTAMP}.zip"

# رسالة البداية
echo "🛡️  Starting Operation: Don't Be Stubbed..."
echo "📦  Target: $OUTPUT_FILE"

# 2. أمر الضغط الذكي (يستثني الملفات الثقيلة وغير الضرورية)
# -q: Quiet (بدون إزعاج في الشاشة)
# -r: Recursive (كل المجلدات)
zip -r -q "$OUTPUT_FILE" . \
    -x "*.git*" \
    -x "build/*" \
    -x ".dart_tool/*" \
    -x ".idea/*" \
    -x "*.vscode/*" \
    -x "*.DS_Store" \
    -x "*.zip" \
    -x "*.apk" \
    -x "*.aab"

# 3. التحقق من النجاح
if [ $? -eq 0 ]; then
    echo "✅  Success! Your code is safe."
    echo "📁  File created: $OUTPUT_FILE"
    echo "🎉  No stubbed toes today!"
else
    echo "❌  Error! Something went wrong."
fi
