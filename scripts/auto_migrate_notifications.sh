#!/bin/bash
# Auto-migrate all notification usages to UnifiedNotificationService

echo "🔄 Starting automatic migration to UnifiedNotificationService..."
echo "=================================================="

# Counter for changes
total_files=0
updated_files=0

# Find all Dart files
dart_files=$(find lib -name "*.dart" -type f)

for file in $dart_files; do
    ((total_files++))
    changed=false
    
    # Create backup
    cp "$file" "$file.bak"
    
    # 1. Replace import statements
    if grep -q "import.*toast_service\.dart" "$file"; then
        sed -i "s|import '.*toast_service\.dart';|import '../../services/unified_notification_service.dart';|g" "$file"
        sed -i "s|import '.*toast_service\.dart';|import '../../../services/unified_notification_service.dart';|g" "$file"
        sed -i "s|import '.*toast_service\.dart';|import '../../../../services/unified_notification_service.dart';|g" "$file"
        changed=true
        echo "  ✓ Updated toast_service import in: $file"
    fi
    
    if grep -q "import.*apex_snackbar\.dart" "$file"; then
        sed -i "s|import '.*apex_snackbar\.dart';|import '../../services/unified_notification_service.dart';|g" "$file"
        sed -i "s|import '.*apex_snackbar\.dart';|import '../../../services/unified_notification_service.dart';|g" "$file"
        sed -i "s|import '.*apex_snackbar\.dart';|import '../../../../services/unified_notification_service.dart';|g" "$file"
        changed=true
        echo "  ✓ Updated apex_snackbar import in: $file"
    fi
    
    # 2. Replace ToastService().showToast
    if grep -q "ToastService()\.showToast" "$file"; then
        sed -i "s/ToastService()\.showToast/UnifiedNotificationService().show/g" "$file"
        changed=true
        echo "  ✓ Replaced ToastService().showToast in: $file"
    fi
    
    # 3. Replace ToastService().showUndoToast
    if grep -q "ToastService()\.showUndoToast" "$file"; then
        sed -i "s/ToastService()\.showUndoToast/UnifiedNotificationService().showWithUndo/g" "$file"
        changed=true
        echo "  ✓ Replaced ToastService().showUndoToast in: $file"
    fi
    
    # 4. Replace ApexSnackBar.show
    if grep -q "ApexSnackBar\.show" "$file"; then
        sed -i "s/ApexSnackBar\.show/UnifiedNotificationService().show/g" "$file"
        changed=true
        echo "  ✓ Replaced ApexSnackBar.show in: $file"
    fi
    
    # 5. Replace enum types
    if grep -q "ToastType\." "$file"; then
        sed -i "s/ToastType\./NotificationType./g" "$file"
        changed=true
        echo "  ✓ Replaced ToastType enum in: $file"
    fi
    
    if grep -q "SnackBarType\." "$file"; then
        sed -i "s/SnackBarType\./NotificationType./g" "$file"
        changed=true
        echo "  ✓ Replaced SnackBarType enum in: $file"
    fi
    
    # 6. Fix import paths (remove duplicates and fix relative paths)
    if grep -q "unified_notification_service\.dart" "$file"; then
        # Count directory depth
        depth=$(echo "$file" | tr -cd '/' | wc -c)
        depth=$((depth - 1))  # Subtract 1 for 'lib/'
        
        # Build correct relative path
        if [ $depth -eq 1 ]; then
            correct_path="import '../services/unified_notification_service.dart';"
        elif [ $depth -eq 2 ]; then
            correct_path="import '../../services/unified_notification_service.dart';"
        elif [ $depth -eq 3 ]; then
            correct_path="import '../../../services/unified_notification_service.dart';"
        elif [ $depth -eq 4 ]; then
            correct_path="import '../../../../services/unified_notification_service.dart';"
        else
            correct_path="import 'package:apex_note/services/unified_notification_service.dart';"
        fi
        
        # Remove all unified_notification_service imports
        sed -i "/import.*unified_notification_service\.dart/d" "$file"
        
        # Add correct import after package imports
        sed -i "/^import 'package:/a\\
$correct_path" "$file"
        
        changed=true
    fi
    
    if [ "$changed" = true ]; then
        ((updated_files++))
        echo "✅ Updated: $file"
        rm "$file.bak"
    else
        # Restore from backup if no changes
        mv "$file.bak" "$file"
    fi
done

echo ""
echo "=================================================="
echo "✨ Migration Complete!"
echo "   Total files scanned: $total_files"
echo "   Files updated: $updated_files"
echo ""
echo "📝 Next steps:"
echo "   1. Run: flutter pub get"
echo "   2. Run: flutter analyze"
echo "   3. Test the application"
echo "   4. If everything works, delete archive files:"
echo "      rm archive/toast_service.dart"
echo "      rm archive/apex_snackbar.dart"
echo "      rm archive/README_TOAST_SERVICE.md"
echo "=================================================="
