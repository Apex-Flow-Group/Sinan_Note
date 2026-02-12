#!/usr/bin/env python3
"""
Script to fix imports after screens folder reorganization
"""

import os
import re
from pathlib import Path

# Define the import mappings
IMPORT_MAPPINGS = {
    # Onboarding screens
    r"import '(\.\./)*(screens/)?cinematic_intro_screen\.dart'": lambda m: f"import '{'../' * m.group(1).count('../') if m.group(1) else ''}screens/onboarding/cinematic_intro_screen.dart'",
    r"import '(\.\./)*(screens/)?splash_screen\.dart'": lambda m: f"import '{'../' * m.group(1).count('../') if m.group(1) else ''}screens/onboarding/splash_screen.dart'",
    r"import '(\.\./)*(screens/)?tour_screen\.dart'": lambda m: f"import '{'../' * m.group(1).count('../') if m.group(1) else ''}screens/onboarding/tour_screen.dart'",
    r"import '(\.\./)*(screens/)?terms_screen\.dart'": lambda m: f"import '{'../' * m.group(1).count('../') if m.group(1) else ''}screens/onboarding/terms_screen.dart'",
    
    # Mobile screens
    r"import '(.*/)?screens/home_screen\.dart'": "import '\\1screens/mobile/home_screen.dart'",
    r"import '(.*/)?screens/archive_screen\.dart'": "import '\\1screens/mobile/archive_screen.dart'",
    r"import '(.*/)?screens/trash_screen\.dart'": "import '\\1screens/mobile/trash_screen.dart'",
    r"import '(.*/)?screens/locked_notes_screen\.dart'": "import '\\1screens/mobile/locked_notes_screen.dart'",
    
    # Desktop screens
    r"import '(.*/)?screens/home_screen_responsive\.dart'": "import '\\1screens/desktop/home_screen_responsive.dart'",
    r"import '(.*/)?screens/archive_screen_responsive\.dart'": "import '\\1screens/desktop/archive_screen_responsive.dart'",
    r"import '(.*/)?screens/trash_screen_responsive\.dart'": "import '\\1screens/desktop/trash_screen_responsive.dart'",
    r"import '(.*/)?screens/locked_notes_screen_responsive\.dart'": "import '\\1screens/desktop/locked_notes_screen_responsive.dart'",
    
    # Shared screens
    r"import '(.*/)?screens/note_editor\.dart'": "import '\\1screens/shared/note_editor.dart'",
    r"import '(.*/)?screens/note_view_screen\.dart'": "import '\\1screens/shared/note_view_screen.dart'",
    r"import '(.*/)?screens/settings_screen\.dart'": "import '\\1screens/shared/settings_screen.dart'",
    r"import '(.*/)?screens/settings_screen_responsive\.dart'": "import '\\1screens/shared/settings_screen_responsive.dart'",
    r"import '(.*/)?screens/main_layout_screen\.dart'": "import '\\1screens/shared/main_layout_screen.dart'",
    
    # Auth screens
    r"import '(.*/)?screens/vault_entry_screen\.dart'": "import '\\1screens/auth/vault_entry_screen.dart'",
    r"import '(.*/)?screens/vault_unlock_screen\.dart'": "import '\\1screens/auth/vault_unlock_screen.dart'",
    r"import '(.*/)?screens/locked_notes_intro_screen\.dart'": "import '\\1screens/auth/locked_notes_intro_screen.dart'",
    
    # Sync screens
    r"import '(.*/)?screens/google_drive_screen\.dart'": "import '\\1screens/sync/google_drive_screen.dart'",
    r"import '(.*/)?screens/google_drive_screen_responsive\.dart'": "import '\\1screens/sync/google_drive_screen_responsive.dart'",
    r"import '(.*/)?screens/google_drive_sync_terms_screen\.dart'": "import '\\1screens/sync/google_drive_sync_terms_screen.dart'",
    
    # Other screens
    r"import '(.*/)?screens/about_screen\.dart'": "import '\\1screens/other/about_screen.dart'",
    r"import '(.*/)?screens/support_form_screen\.dart'": "import '\\1screens/other/support_form_screen.dart'",
    r"import '(.*/)?screens/version_history_screen\.dart'": "import '\\1screens/other/version_history_screen.dart'",
    r"import '(.*/)?screens/widget_selection_screen\.dart'": "import '\\1screens/other/widget_selection_screen.dart'",
}

def fix_imports_in_file(file_path):
    """Fix imports in a single file"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original_content = content
        
        # Apply all import mappings
        for pattern, replacement in IMPORT_MAPPINGS.items():
            content = re.sub(pattern, replacement, content)
        
        # Only write if content changed
        if content != original_content:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
            return True
        
        return False
    except Exception as e:
        print(f"Error processing {file_path}: {e}")
        return False

def main():
    """Main function to fix all imports"""
    project_root = Path(__file__).parent.parent
    lib_dir = project_root / 'lib'
    test_dir = project_root / 'test'
    
    fixed_count = 0
    total_count = 0
    
    # Process all Dart files in lib and test directories
    for directory in [lib_dir, test_dir]:
        if not directory.exists():
            continue
            
        for dart_file in directory.rglob('*.dart'):
            total_count += 1
            if fix_imports_in_file(dart_file):
                fixed_count += 1
                print(f"✓ Fixed: {dart_file.relative_to(project_root)}")
    
    print(f"\n{'='*60}")
    print(f"✅ Import fix complete!")
    print(f"   Files processed: {total_count}")
    print(f"   Files modified: {fixed_count}")
    print(f"{'='*60}")

if __name__ == '__main__':
    main()
