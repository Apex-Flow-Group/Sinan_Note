#!/bin/bash

# 🗑️ حذف المكتبات والأصول الزائدة

echo "🗑️  حذف الأصول الزائدة..."

# حذف صور التسويق (23MB)
rm -f assets/"Feature graphic.png"
rm -f assets/"Feature graphic0.png"
rm -f assets/Feature_graphic_clean.png
rm -f assets/Gemini_Generated_Image.png
rm -f assets/note.jpg
rm -f assets/Note.png
rm -f assets/Checlist.png

# حذف صور الويدجت غير المستخدمة
rm -f assets/images/widget_checklist_preview.png
rm -f assets/images/widget_note_preview.png

echo "✅ تم حذف 23MB من الأصول"
echo ""
echo "⚠️  يدوياً: احذف من pubspec.yaml:"
echo "  - shelf"
echo "  - shelf_router"
echo "  - network_info_plus"
echo "  - math_expressions"
echo "  - receive_sharing_intent"
echo ""
echo "⚠️  يدوياً: صغّر app_icon.png من 4.2MB"
