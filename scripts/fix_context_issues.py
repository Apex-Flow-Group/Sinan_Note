#!/usr/bin/env python3
# Fix all use_build_context_synchronously issues

import re
import os
from pathlib import Path

def fix_context_usage(file_path):
    """Fix BuildContext usage across async gaps"""
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original = content
    
    # Pattern 1: if (mounted) { context usage }
    # Change to: if (!mounted) return; then use context
    
    # Pattern 2: Add mounted check before context usage after await
    lines = content.split('\n')
    fixed_lines = []
    i = 0
    
    while i < len(lines):
        line = lines[i]
        
        # Check if line has await
        if 'await ' in line and i + 1 < len(lines):
            next_line = lines[i + 1]
            # Check if next line uses context without mounted check
            if 'context' in next_line and 'if' not in next_line and 'mounted' not in next_line:
                # Add mounted check
                indent = len(next_line) - len(next_line.lstrip())
                fixed_lines.append(line)
                fixed_lines.append(' ' * indent + 'if (!mounted) return;')
                fixed_lines.append(next_line)
                i += 2
                continue
        
        fixed_lines.append(line)
        i += 1
    
    content = '\n'.join(fixed_lines)
    
    if content != original:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        return True
    return False

def main():
    lib_dir = Path('lib')
    dart_files = list(lib_dir.rglob('*.dart'))
    
    fixed_count = 0
    for file_path in dart_files:
        if fix_context_usage(file_path):
            print(f'✅ Fixed: {file_path}')
            fixed_count += 1
    
    print(f'\n📊 Fixed {fixed_count} files')

if __name__ == '__main__':
    main()
