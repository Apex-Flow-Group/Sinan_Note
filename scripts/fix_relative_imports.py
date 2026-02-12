#!/usr/bin/env python3
"""
Script to fix relative imports after screens folder reorganization
"""

import os
import re
from pathlib import Path

def count_parent_dirs(from_path, to_path):
    """Calculate how many '../' needed to go from one path to another"""
    from_parts = Path(from_path).parent.parts
    to_parts = Path(to_path).parent.parts
    
    # Find common prefix
    common = 0
    for i in range(min(len(from_parts), len(to_parts))):
        if from_parts[i] == to_parts[i]:
            common += 1
        else:
            break
    
    # Calculate ups needed
    ups = len(from_parts) - common
    return ups

def fix_imports_in_file(file_path, project_root):
    """Fix relative imports in a single file"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            lines = f.readlines()
        
        modified = False
        new_lines = []
        
        for line in lines:
            # Match relative imports
            match = re.match(r"^import '(\.\./+)([^']+)';", line)
            if match:
                relative_prefix = match.group(1)
                import_path = match.group(2)
                
                # Calculate correct relative path
                file_rel_path = file_path.relative_to(project_root / 'lib')
                
                # Determine target based on import_path
                if import_path.startswith('screens/'):
                    # This is already correct format
                    new_lines.append(line)
                    continue
                elif import_path.startswith('controllers/') or import_path.startswith('models/') or \
                     import_path.startswith('services/') or import_path.startswith('widgets/') or \
                     import_path.startswith('core/') or import_path.startswith('providers/'):
                    # These should go to lib root
                    depth = len(file_rel_path.parent.parts)
                    new_prefix = '../' * depth
                    new_line = f"import '{new_prefix}{import_path}';\n"
                    if new_line != line:
                        modified = True
                        new_lines.append(new_line)
                    else:
                        new_lines.append(line)
                else:
                    new_lines.append(line)
            else:
                new_lines.append(line)
        
        if modified:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.writelines(new_lines)
            return True
        
        return False
    except Exception as e:
        print(f"Error processing {file_path}: {e}")
        return False

def main():
    """Main function"""
    project_root = Path(__file__).parent.parent
    lib_dir = project_root / 'lib'
    
    fixed_count = 0
    total_count = 0
    
    # Process all Dart files in lib/screens
    screens_dir = lib_dir / 'screens'
    if screens_dir.exists():
        for dart_file in screens_dir.rglob('*.dart'):
            total_count += 1
            if fix_imports_in_file(dart_file, project_root):
                fixed_count += 1
                print(f"✓ Fixed: {dart_file.relative_to(project_root)}")
    
    print(f"\n{'='*60}")
    print(f"✅ Relative import fix complete!")
    print(f"   Files processed: {total_count}")
    print(f"   Files modified: {fixed_count}")
    print(f"{'='*60}")

if __name__ == '__main__':
    main()
