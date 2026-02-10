#!/usr/bin/env python3
"""
تحليل صحة المشروع - فحص الملفات الكبيرة والديون التقنية
"""

import os
import re
from pathlib import Path
from collections import defaultdict

class Colors:
    GREEN = '\033[92m'
    RED = '\033[91m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    CYAN = '\033[96m'
    RESET = '\033[0m'
    BOLD = '\033[1m'

def analyze_file_sizes():
    """تحليل أحجام الملفات"""
    print(f"\n{Colors.BOLD}{Colors.BLUE}📊 1. تحليل أحجام الملفات{Colors.RESET}")
    print(f"{Colors.BLUE}{'='*60}{Colors.RESET}\n")
    
    large_files = []
    
    for dart_file in Path('lib').rglob('*.dart'):
        # تجاهل الملفات المولدة
        if 'generated' in str(dart_file) or dart_file.name.endswith('.g.dart'):
            continue
        
        lines = len(dart_file.read_text(encoding='utf-8').splitlines())
        size = dart_file.stat().st_size
        
        if lines > 400:  # ملفات كبيرة
            large_files.append((dart_file, lines, size))
    
    large_files.sort(key=lambda x: x[1], reverse=True)
    
    if large_files:
        print(f"{Colors.YELLOW}⚠️  ملفات كبيرة (>400 سطر):{Colors.RESET}\n")
        for file, lines, size in large_files[:10]:
            size_kb = size / 1024
            status = f"{Colors.RED}🔴{Colors.RESET}" if lines > 600 else f"{Colors.YELLOW}🟡{Colors.RESET}"
            print(f"  {status} {lines:4d} سطر ({size_kb:5.1f}KB) - {file}")
        
        if len(large_files) > 10:
            print(f"\n  ... و {len(large_files) - 10} ملف آخر")
    else:
        print(f"{Colors.GREEN}✅ جميع الملفات بحجم معقول!{Colors.RESET}")
    
    return large_files

def analyze_technical_debt():
    """تحليل الديون التقنية"""
    print(f"\n{Colors.BOLD}{Colors.BLUE}📊 2. تحليل الديون التقنية{Colors.RESET}")
    print(f"{Colors.BLUE}{'='*60}{Colors.RESET}\n")
    
    debt_markers = {
        'TODO': [],
        'FIXME': [],
        'HACK': [],
        'XXX': [],
        'BUG': [],
        'DEPRECATED': [],
        'TEMP': [],
        'TEMPORARY': []
    }
    
    for dart_file in Path('lib').rglob('*.dart'):
        if 'generated' in str(dart_file):
            continue
        
        try:
            content = dart_file.read_text(encoding='utf-8')
            for i, line in enumerate(content.splitlines(), 1):
                for marker in debt_markers.keys():
                    if marker in line.upper() and '//' in line:
                        debt_markers[marker].append((dart_file, i, line.strip()))
        except Exception:
            continue
    
    total_debt = sum(len(items) for items in debt_markers.values())
    
    if total_debt > 0:
        print(f"{Colors.YELLOW}⚠️  وجدنا {total_debt} علامة ديون تقنية:{Colors.RESET}\n")
        
        for marker, items in debt_markers.items():
            if items:
                print(f"  {Colors.RED}• {marker}: {len(items)}{Colors.RESET}")
                for file, line_num, line in items[:3]:
                    print(f"    {file}:{line_num}")
                    print(f"    {Colors.CYAN}{line[:80]}...{Colors.RESET}")
                if len(items) > 3:
                    print(f"    ... و {len(items) - 3} آخرين\n")
    else:
        print(f"{Colors.GREEN}✅ لا توجد ديون تقنية واضحة!{Colors.RESET}")
    
    return debt_markers

def analyze_unused_files():
    """البحث عن ملفات محتملة غير مستخدمة"""
    print(f"\n{Colors.BOLD}{Colors.BLUE}📊 3. تحليل الملفات المحتملة غير المستخدمة{Colors.RESET}")
    print(f"{Colors.BLUE}{'='*60}{Colors.RESET}\n")
    
    # قراءة كل الكود
    all_imports = set()
    all_files = []
    
    for dart_file in Path('lib').rglob('*.dart'):
        if 'generated' in str(dart_file):
            continue
        
        all_files.append(dart_file)
        
        try:
            content = dart_file.read_text(encoding='utf-8')
            # استخراج الـ imports
            imports = re.findall(r"import\s+['\"](.+?)['\"]", content)
            for imp in imports:
                if imp.startswith('package:'):
                    # استخراج المسار النسبي
                    path = imp.replace('package:apex_note/', 'lib/')
                    all_imports.add(path)
        except Exception:
            continue
    
    # البحث عن ملفات غير مستوردة
    potentially_unused = []
    
    for dart_file in all_files:
        file_path = str(dart_file)
        
        # تجاهل main.dart والملفات المولدة
        if dart_file.name == 'main.dart' or dart_file.name.endswith('.g.dart'):
            continue
        
        # تحقق إذا كان الملف مستورد
        is_imported = any(file_path.endswith(imp) for imp in all_imports)
        
        if not is_imported:
            potentially_unused.append(dart_file)
    
    if potentially_unused:
        print(f"{Colors.YELLOW}⚠️  ملفات محتملة غير مستخدمة ({len(potentially_unused)}):{Colors.RESET}\n")
        for file in potentially_unused[:15]:
            print(f"  {Colors.YELLOW}•{Colors.RESET} {file}")
        
        if len(potentially_unused) > 15:
            print(f"\n  ... و {len(potentially_unused) - 15} ملف آخر")
        
        print(f"\n{Colors.CYAN}💡 ملاحظة: قد تكون هذه الملفات مستخدمة بطرق أخرى (widgets، providers، إلخ){Colors.RESET}")
    else:
        print(f"{Colors.GREEN}✅ جميع الملفات يبدو أنها مستخدمة!{Colors.RESET}")
    
    return potentially_unused

def analyze_documentation():
    """تحليل ملفات التوثيق"""
    print(f"\n{Colors.BOLD}{Colors.BLUE}📊 4. تحليل ملفات التوثيق{Colors.RESET}")
    print(f"{Colors.BLUE}{'='*60}{Colors.RESET}\n")
    
    doc_files = []
    
    for md_file in Path('.').rglob('*.md'):
        if '.git' in str(md_file):
            continue
        
        size = md_file.stat().st_size
        lines = len(md_file.read_text(encoding='utf-8').splitlines())
        
        doc_files.append((md_file, lines, size))
    
    doc_files.sort(key=lambda x: x[2], reverse=True)
    
    total_size = sum(f[2] for f in doc_files)
    
    print(f"إجمالي ملفات التوثيق: {len(doc_files)}")
    print(f"الحجم الإجمالي: {total_size / 1024:.1f} KB\n")
    
    if doc_files:
        print(f"أكبر 10 ملفات:\n")
        for file, lines, size in doc_files[:10]:
            size_kb = size / 1024
            print(f"  {size_kb:6.1f}KB ({lines:4d} سطر) - {file}")
    
    # فحص مجلد archive
    archive_path = Path('archive')
    if archive_path.exists():
        archive_size = sum(f.stat().st_size for f in archive_path.rglob('*') if f.is_file())
        print(f"\n{Colors.YELLOW}📦 مجلد archive: {archive_size / 1024:.1f} KB{Colors.RESET}")
        print(f"{Colors.CYAN}💡 يمكن حذف هذا المجلد إذا لم تعد بحاجة للملفات القديمة{Colors.RESET}")
    
    return doc_files

def generate_report(large_files, debt_markers, potentially_unused, doc_files):
    """إنشاء تقرير شامل"""
    print(f"\n{Colors.BOLD}{Colors.GREEN}{'='*60}{Colors.RESET}")
    print(f"{Colors.BOLD}{Colors.GREEN}📋 ملخص التحليل{Colors.RESET}")
    print(f"{Colors.BOLD}{Colors.GREEN}{'='*60}{Colors.RESET}\n")
    
    # الملفات الكبيرة
    critical_files = [f for f in large_files if f[1] > 600]
    warning_files = [f for f in large_files if 400 < f[1] <= 600]
    
    print(f"🔴 ملفات كبيرة جداً (>600 سطر): {len(critical_files)}")
    print(f"🟡 ملفات كبيرة (400-600 سطر): {len(warning_files)}")
    
    # الديون التقنية
    total_debt = sum(len(items) for items in debt_markers.values())
    print(f"⚠️  علامات ديون تقنية: {total_debt}")
    
    # الملفات غير المستخدمة
    print(f"❓ ملفات محتملة غير مستخدمة: {len(potentially_unused)}")
    
    # التوثيق
    total_doc_size = sum(f[2] for f in doc_files) / 1024
    print(f"📄 ملفات توثيق: {len(doc_files)} ({total_doc_size:.1f} KB)")
    
    # التوصيات
    print(f"\n{Colors.BOLD}{Colors.CYAN}💡 التوصيات:{Colors.RESET}\n")
    
    if critical_files:
        print(f"{Colors.RED}1. إعادة هيكلة الملفات الكبيرة جداً (>600 سطر){Colors.RESET}")
    
    if total_debt > 10:
        print(f"{Colors.YELLOW}2. معالجة الديون التقنية (TODO/FIXME){Colors.RESET}")
    
    if len(potentially_unused) > 5:
        print(f"{Colors.YELLOW}3. مراجعة الملفات المحتملة غير المستخدمة{Colors.RESET}")
    
    if Path('archive').exists():
        print(f"{Colors.CYAN}4. حذف مجلد archive إذا لم تعد بحاجته{Colors.RESET}")
    
    if not critical_files and total_debt < 10:
        print(f"{Colors.GREEN}✅ المشروع في حالة صحية جيدة!{Colors.RESET}")
    
    print()

def main():
    print(f"\n{Colors.BOLD}{Colors.BLUE}{'='*60}{Colors.RESET}")
    print(f"{Colors.BOLD}{Colors.BLUE}  🏥 تحليل صحة المشروع - Sinan Note{Colors.RESET}")
    print(f"{Colors.BOLD}{Colors.BLUE}{'='*60}{Colors.RESET}")
    
    large_files = analyze_file_sizes()
    debt_markers = analyze_technical_debt()
    potentially_unused = analyze_unused_files()
    doc_files = analyze_documentation()
    
    generate_report(large_files, debt_markers, potentially_unused, doc_files)

if __name__ == "__main__":
    main()
