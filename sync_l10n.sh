#!/bin/bash
# نسخ ملفات الترجمة المولدة تلقائياً

flutter gen-l10n
cp -v lib/l10n/app_localizations*.dart lib/generated/l10n/
echo "✅ تم تحديث ملفات الترجمة"
