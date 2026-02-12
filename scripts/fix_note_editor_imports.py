#!/usr/bin/env python3
"""
Fix imports in note_editor subdirectories
Files in lib/screens/shared/note_editor/[subfolder]/ need ../../../../ to reach lib/
"""

import os
import re
from pathlib import Path

def fix_imports_in_file(file_path, project_root):
    """Fix imports in a single file"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original_content = content
        
        # Get relative path from lib/
        rel_path = file_path.relative_to(project_root / 'lib')
        depth = len(rel_path.parent.parts)
        
        # Files in lib/screens/shared/note_editor/[subfolder]/ have depth 4
        # They need ../../../../ to reach lib/
        if depth == 4 and 'note_editor' in str(rel_path):
            # Replace ../../../ with ../../../../ for lib root imports
            # But keep relative imports within note_editor as is
            
            lines = content.split('\n')
            new_lines = []
            
            for line in lines:
                # Match imports that go to lib root (models, services, controllers, widgets, core)
                if re.match(r"^import '\.\./\.\./\.\./(models|services|controllers|widgets|core|providers)/", line):
                    # Replace ../../../ with ../../../../
                    new_line = line.replace("import '../../../", "import '../../../../")
                    new_lines.append(new_line)
                else:
                    new_lines.append(line)
            
            content = '\n'.join(new_lines)
        
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
    """Main function"""
    project_root = Path(__file__).parent.parent
    note_editor_dir = project_root / 'lib' / 'screens' / 'shared' / 'note_editor'
    
    fixed_count = 0
    total_count = 0
    
    # Process all Dart files in note_editor subdirectories
    if note_editor_dir.exists():
        for dart_file in note_editor_dir.rglob('*.dart'):
            # Skip files directly in note_editor/ (they have correct depth)
            if dart_file.parent == note_editor_dir:
                continue
                
            total_count += 1
            if fix_imports_in_file(dart_file, project_root):
                fixed_count += 1
                print(f"✓ Fixed: {dart_file.relative_to(project_root)}")
    
    print(f"\n{'='*60}")
    print(f"✅ Note editor import fix complete!")
    print(f"   Files processed: {total_count}")
    print(f"   Files modified: {fixed_count}")
    print(f"{'='*60}")

if __name__ == '__main__':
    main()
