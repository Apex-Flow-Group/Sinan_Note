#!/usr/bin/env python3
# Copyright © 2025 Apex Flow Group. All rights reserved.
# Import Analyzer for Sinan Note

import os
import re
from pathlib import Path
from collections import defaultdict
import json

class ImportAnalyzer:
    def __init__(self, root_dir='lib'):
        self.root_dir = Path(root_dir)
        self.stats = {
            'total_files': 0,
            'total_imports': 0,
            'dart_imports': 0,
            'flutter_imports': 0,
            'package_imports': 0,
            'relative_imports': 0,
            'duplicates': 0,
            'unused_imports': 0,
        }
        self.issues = defaultdict(list)
        self.import_graph = defaultdict(set)
        
    def analyze(self):
        print('🔍 Sinan Note - Import Analyzer')
        print('━' * 66)
        print()
        
        dart_files = list(self.root_dir.rglob('*.dart'))
        dart_files = [f for f in dart_files if not self._is_generated(f)]
        
        self.stats['total_files'] = len(dart_files)
        print(f'📁 Analyzing {len(dart_files)} Dart files...')
        print()
        
        for file_path in dart_files:
            self._analyze_file(file_path)
        
        self._print_report()
        self._save_report()
        
    def _is_generated(self, path):
        return any(x in str(path) for x in ['.g.dart', '.freezed.dart', 'generated/', '.mocks.dart'])
    
    def _analyze_file(self, file_path):
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
                
            imports = re.findall(r"^import\s+['\"](.+?)['\"];?", content, re.MULTILINE)
            
            seen = set()
            for imp in imports:
                self.stats['total_imports'] += 1
                
                if imp in seen:
                    self.stats['duplicates'] += 1
                    self.issues[str(file_path)].append(f'Duplicate: {imp}')
                seen.add(imp)
                
                if imp.startswith('dart:'):
                    self.stats['dart_imports'] += 1
                elif imp.startswith('package:flutter'):
                    self.stats['flutter_imports'] += 1
                elif imp.startswith('package:'):
                    self.stats['package_imports'] += 1
                else:
                    self.stats['relative_imports'] += 1
                
                self.import_graph[str(file_path)].add(imp)
                
        except Exception as e:
            self.issues[str(file_path)].append(f'Error: {str(e)}')
    
    def _print_report(self):
        print('━' * 66)
        print('📊 Analysis Report')
        print('━' * 66)
        print()
        
        print('📈 Statistics:')
        print(f'   Total Files:        {self.stats["total_files"]}')
        print(f'   Total Imports:      {self.stats["total_imports"]}')
        print(f'   Dart Imports:       {self.stats["dart_imports"]}')
        print(f'   Flutter Imports:    {self.stats["flutter_imports"]}')
        print(f'   Package Imports:    {self.stats["package_imports"]}')
        print(f'   Relative Imports:   {self.stats["relative_imports"]}')
        print(f'   Duplicates Found:   {self.stats["duplicates"]}')
        print()
        
        if self.stats['total_files'] > 0:
            avg = self.stats['total_imports'] / self.stats['total_files']
            print(f'📊 Average imports per file: {avg:.1f}')
            print()
        
        if self.issues:
            print('⚠️  Issues Found:')
            for file_path, issues in list(self.issues.items())[:10]:
                rel_path = Path(file_path).relative_to(Path.cwd())
                print(f'   {rel_path}:')
                for issue in issues[:3]:
                    print(f'      - {issue}')
            
            if len(self.issues) > 10:
                print(f'   ... and {len(self.issues) - 10} more files with issues')
            print()
        
        print('━' * 66)
        
    def _save_report(self):
        report = {
            'timestamp': str(Path.cwd()),
            'statistics': self.stats,
            'issues': {k: v for k, v in self.issues.items()},
            'top_imported_packages': self._get_top_packages(),
        }
        
        output_file = Path('scripts/import_analysis_report.json')
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(report, f, indent=2, ensure_ascii=False)
        
        print(f'📄 Report saved to: {output_file}')
        print()
    
    def _get_top_packages(self):
        package_count = defaultdict(int)
        for imports in self.import_graph.values():
            for imp in imports:
                if imp.startswith('package:'):
                    pkg = imp.split('/')[0]
                    package_count[pkg] += 1
        
        return dict(sorted(package_count.items(), key=lambda x: x[1], reverse=True)[:10])

if __name__ == '__main__':
    import sys
    
    root = sys.argv[1] if len(sys.argv) > 1 else 'lib'
    analyzer = ImportAnalyzer(root)
    analyzer.analyze()
