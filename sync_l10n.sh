#!/bin/bash
# نسخ ملفات الترجمة المولدة تلقائياً

flutter pub get
cp -v .dart_tool/flutter_gen/gen_l10n/*.dart lib/generated/l10n/
echo "✅ تم تحديث ملفات الترجمة"
