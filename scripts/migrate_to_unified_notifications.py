#!/usr/bin/env python3
"""
Script to migrate from old notification systems to UnifiedNotificationService
يقوم بتحديث جميع استخدامات الإشعارات القديمة للنظام الموحد الجديد
"""

import os
import re
from pathlib import Path

# الأنماط القديمة والبدائل الجديدة
PATTERNS = [
    # ApexSnackBar.show
    {
        'old': r'ApexSnackBar\.show\(\s*context,\s*([^,]+),\s*type:\s*SnackBarType\.(\w+)',
        'new': r"UnifiedNotificationService().show(\n      context: context,\n      message: \1,\n      type: NotificationType.\2",
        'description': 'ApexSnackBar.show to UnifiedNotificationService.show'
    },
    
    # ToastService().showToast
    {
        'old': r'ToastService\(\)\.showToast\(\s*context:\s*context,\s*message:\s*([^,]+),\s*type:\s*ToastType\.(\w+)',
        'new': r'UnifiedNotificationService().show(\n      context: context,\n      message: \1,\n      type: NotificationType.\2',
        'description': 'ToastService.showToast to UnifiedNotificationService.show'
    },
    
    # ToastService().showUndoToast
    {
        'old': r'ToastService\(\)\.showUndoToast\(',
        'new': r'UnifiedNotificationService().showWithUndo(',
        'description': 'ToastService.showUndoToast to UnifiedNotificationService.showWithUndo'
    },
    
    # Import statements
    {
        'old': r"import\s+'[^']*apex_snackbar\.dart';",
        'new': "import 'package:sinan_note/services/unified_notification_service.dart';",
        'description': 'Update apex_snackbar import'
    },
    {
        'old': r"import\s+'[^']*toast_service\.dart';",
        'new': "import 'package:sinan_note/services/unified_notification_service.dart';",
        'description': 'Update toast_service import'
    },
    
    # Enum types
    {
        'old': r'SnackBarType\.',
        'new': r'NotificationType.',
        'description': 'Update enum type'
    },
    {
        'old': r'ToastType\.',
        'new': r'NotificationType.',
        'description': 'Update enum type'
    },
]

# ScaffoldMessenger patterns (more complex, needs manual review)
SCAFFOLD_PATTERNS = [
    r'ScaffoldMessenger\.of\(context\)\.showSnackBar\(',
    r'ScaffoldMessenger\.of\(context\)\.clearSnackBars\(\)',
    r'ScaffoldMessenger\.of\(context\)\.hideCurrentSnackBar\(\)',
]

def find_dart_files(root_dir='lib'):
    """البحث عن جميع ملفات Dart"""
    dart_files = []
    for path in Path(root_dir).rglob('*.dart'):
        dart_files.append(str(path))
    return dart_files

def migrate_file(file_path, dry_run=True):
    """ترحيل ملف واحد"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original_content = content
        changes = []
        
        # تطبيق جميع الأنماط
        for pattern in PATTERNS:
            matches = re.findall(pattern['old'], content, re.MULTILINE)
            if matches:
                content = re.sub(pattern['old'], pattern['new'], content, flags=re.MULTILINE)
                changes.append(f"  ✓ {pattern['description']}: {len(matches)} occurrence(s)")
        
        # البحث عن استخدامات ScaffoldMessenger (للمراجعة اليدوية)
        scaffold_uses = []
        for pattern in SCAFFOLD_PATTERNS:
            matches = re.findall(pattern, content)
            if matches:
                scaffold_uses.append(f"  ⚠ Found {len(matches)} ScaffoldMessenger usage(s) - needs manual review")
        
        # حفظ التغييرات
        if content != original_content:
            if not dry_run:
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write(content)
                print(f"\n✅ Updated: {file_path}")
            else:
                print(f"\n📝 Would update: {file_path}")
            
            for change in changes:
                print(change)
            
            for warning in scaffold_uses:
                print(warning)
            
            return True
        
        return False
        
    except Exception as e:
        print(f"\n❌ Error processing {file_path}: {e}")
        return False

def main():
    """الدالة الرئيسية"""
    import argparse
    
    parser = argparse.ArgumentParser(description='Migrate to UnifiedNotificationService')
    parser.add_argument('--apply', action='store_true', help='Apply changes (default is dry-run)')
    parser.add_argument('--dir', default='lib', help='Directory to scan (default: lib)')
    args = parser.parse_args()
    
    print("🔄 Notification System Migration Tool")
    print("=" * 50)
    
    if args.apply:
        print("⚠️  APPLY MODE: Changes will be written to files")
    else:
        print("👀 DRY-RUN MODE: No files will be modified")
        print("   Use --apply to actually modify files")
    
    print(f"📁 Scanning directory: {args.dir}")
    print("=" * 50)
    
    dart_files = find_dart_files(args.dir)
    print(f"\n📊 Found {len(dart_files)} Dart files")
    
    updated_count = 0
    for file_path in dart_files:
        if migrate_file(file_path, dry_run=not args.apply):
            updated_count += 1
    
    print("\n" + "=" * 50)
    print(f"✨ Migration Summary:")
    print(f"   Files scanned: {len(dart_files)}")
    print(f"   Files {'updated' if args.apply else 'to update'}: {updated_count}")
    
    if not args.apply and updated_count > 0:
        print(f"\n💡 Run with --apply to apply changes")
    
    print("\n📚 Next steps:")
    print("   1. Review the changes")
    print("   2. Manually update ScaffoldMessenger usages")
    print("   3. Test the application")
    print("   4. Delete old files from archive/ after verification")
    print("=" * 50)

if __name__ == '__main__':
    main()
