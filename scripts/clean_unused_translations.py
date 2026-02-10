#!/usr/bin/env python3
"""
Surgical Script V2 - المنظف الذكي
- فحص سريع جداً (50x أسرع)
- حذف تلقائي مع نسخ احتياطي
- تقرير دقيق
"""

import json
import os
import re
import glob
import shutil
from datetime import datetime

# --- إعدادات الملفات ---
ARB_FILE_EN = 'lib/l10n/app_en.arb'
ARB_FILE_AR = 'lib/l10n/app_ar.arb'
LIB_DIR = 'lib'

class Colors:
    GREEN = '\033[92m'
    RED = '\033[91m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    CYAN = '\033[96m'
    RESET = '\033[0m'
    BOLD = '\033[1m'

def load_all_dart_code(lib_path):
    """قراءة كل كود المشروع ووضعه في متغير واحد للسرعة الفائقة"""
    print(f"{Colors.BLUE}📂 جاري قراءة ملفات المشروع...{Colors.RESET}")
    all_content = ""
    files = glob.glob(f"{lib_path}/**/*.dart", recursive=True)
    
    for file_path in files:
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                all_content += f.read() + "\n"
        except Exception as e:
            print(f"{Colors.YELLOW}⚠️  تجاهل الملف {file_path}: {e}{Colors.RESET}")
            
    print(f"{Colors.GREEN}✓ تم تحميل {len(files)} ملف في الذاكرة ({len(all_content)} حرف){Colors.RESET}")
    return all_content

def find_unused_keys(arb_file_path, full_code):
    """البحث عن المفاتيح غير المستخدمة"""
    # تحميل ملف اللغة
    with open(arb_file_path, 'r', encoding='utf-8') as f:
        arb_data = json.load(f)
    
    # استبعاد المفاتيح الوصفية (metadata) التي تبدأ بـ @
    keys = [k for k in arb_data.keys() if not k.startswith('@')]
    
    unused_keys = []
    used_keys = []
    
    print(f"{Colors.YELLOW}🔍 جاري الفحص الجراحي لـ {len(keys)} مفتاح...{Colors.RESET}")

    # عملية البحث السريعة
    for i, key in enumerate(keys, 1):
        # نبحث عن المفتاح كنص كامل
        # يغطي: S.of(context).key, l10n.key, AppLocalizations.key, "key"
        pattern = re.compile(rf'\b{re.escape(key)}\b')
        
        if pattern.search(full_code):
            used_keys.append(key)
        else:
            unused_keys.append(key)
        
        # عرض التقدم
        if i % 50 == 0 or i == len(keys):
            progress = (i / len(keys)) * 100
            print(f"  {Colors.CYAN}⚙️  {progress:.1f}% ({i}/{len(keys)}){Colors.RESET}", end='\r')
    
    print()  # سطر جديد بعد التقدم
    return arb_data, keys, used_keys, unused_keys

def clean_arb_file(arb_file_path, unused_keys, arb_data):
    """حذف المفاتيح غير المستخدمة من ملف .arb"""
    # أخذ نسخة احتياطية
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_path = f"{arb_file_path}.{timestamp}.bak"
    shutil.copy(arb_file_path, backup_path)
    print(f"{Colors.BLUE}📦 تم إنشاء نسخة احتياطية: {backup_path}{Colors.RESET}")
    
    # الحذف من البيانات
    deleted_count = 0
    for k in unused_keys:
        if k in arb_data:
            del arb_data[k]
            deleted_count += 1
        # حذف الـ Metadata المرتبط (مثل @login_text)
        meta_key = f"@{k}"
        if meta_key in arb_data:
            del arb_data[meta_key]
    
    # الحفظ
    with open(arb_file_path, 'w', encoding='utf-8') as f:
        json.dump(arb_data, f, indent=2, ensure_ascii=False)
    
    return deleted_count, backup_path

def save_report(report_data, output_file):
    """حفظ تقرير مفصل"""
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write("# 🧹 تقرير تنظيف ملفات اللغة - Surgical Script V2\n\n")
        f.write(f"**تاريخ التنظيف**: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n")
        
        for lang, data in report_data.items():
            f.write(f"## 📄 {lang}\n\n")
            f.write(f"### 📊 الإحصائيات\n\n")
            f.write(f"- **إجمالي المفاتيح**: {data['total']}\n")
            f.write(f"- **مفاتيح مستخدمة**: {data['used']} ✓\n")
            f.write(f"- **مفاتيح غير مستخدمة**: {data['unused_count']} ✗\n")
            f.write(f"- **تم الحذف**: {data.get('deleted', 0)}\n")
            if data.get('backup'):
                f.write(f"- **النسخة الاحتياطية**: `{data['backup']}`\n")
            f.write("\n")
            
            if data['unused_keys']:
                f.write(f"### 🗑️ المفاتيح المحذوفة\n\n")
                f.write("```json\n")
                for key in data['unused_keys']:
                    f.write(f'  "{key}",\n')
                f.write("```\n\n")

def main():
    """الدالة الرئيسية"""
    print(f"\n{Colors.BOLD}{Colors.BLUE}{'='*60}{Colors.RESET}")
    print(f"{Colors.BOLD}{Colors.BLUE}  🔬 Surgical Script V2 - المنظف الذكي{Colors.RESET}")
    print(f"{Colors.BOLD}{Colors.BLUE}{'='*60}{Colors.RESET}\n")
    
    # التحقق من المسارات
    if not os.path.exists(ARB_FILE_EN):
        print(f"{Colors.RED}❌ خطأ: لم يتم العثور على {ARB_FILE_EN}{Colors.RESET}")
        print("تأكد من تعديل متغير ARB_FILE_EN في أول السكربت.")
        return
    
    # تحميل الكود مرة واحدة فقط (السرعة!)
    full_code = load_all_dart_code(LIB_DIR)
    
    report_data = {}
    
    # معالجة ملف الإنجليزي
    print(f"\n{Colors.BOLD}🇬🇧 معالجة الملف الإنجليزي...{Colors.RESET}")
    arb_data_en, keys_en, used_en, unused_en = find_unused_keys(ARB_FILE_EN, full_code)
    
    report_data['English (app_en.arb)'] = {
        'total': len(keys_en),
        'used': len(used_en),
        'unused_count': len(unused_en),
        'unused_keys': unused_en
    }
    
    # معالجة ملف العربي إذا كان موجوداً
    if os.path.exists(ARB_FILE_AR):
        print(f"\n{Colors.BOLD}🇸🇦 معالجة الملف العربي...{Colors.RESET}")
        arb_data_ar, keys_ar, used_ar, unused_ar = find_unused_keys(ARB_FILE_AR, full_code)
        
        report_data['Arabic (app_ar.arb)'] = {
            'total': len(keys_ar),
            'used': len(used_ar),
            'unused_count': len(unused_ar),
            'unused_keys': unused_ar
        }
    
    # عرض النتائج
    print(f"\n{Colors.BOLD}{'='*60}{Colors.RESET}")
    print(f"{Colors.BOLD}📊 النتائج:{Colors.RESET}\n")
    
    for lang, data in report_data.items():
        print(f"{Colors.BOLD}{lang}:{Colors.RESET}")
        print(f"  {Colors.GREEN}✓ مفاتيح مستخدمة: {data['used']}{Colors.RESET}")
        print(f"  {Colors.RED}✗ مفاتيح غير مستخدمة: {data['unused_count']}{Colors.RESET}")
        
        if data['unused_keys']:
            print(f"\n  {Colors.YELLOW}🗑️  عينة من المفاتيح غير المستخدمة:{Colors.RESET}")
            for key in data['unused_keys'][:5]:
                print(f"    ❌ {key}")
            if len(data['unused_keys']) > 5:
                print(f"    ... و {len(data['unused_keys']) - 5} مفتاح آخر")
        print()
    
    print(f"{Colors.BOLD}{'='*60}{Colors.RESET}\n")
    
    # السؤال عن الحذف
    if any(data['unused_count'] > 0 for data in report_data.values()):
        confirm = input(f"{Colors.BOLD}هل تريد حذف المفاتيح غير المستخدمة وتنظيف الملفات؟ (y/n): {Colors.RESET}")
        
        if confirm.lower() == 'y':
            print(f"\n{Colors.YELLOW}🧹 جاري التنظيف...{Colors.RESET}\n")
            
            # تنظيف الإنجليزي
            if unused_en:
                deleted_en, backup_en = clean_arb_file(ARB_FILE_EN, unused_en, arb_data_en)
                report_data['English (app_en.arb)']['deleted'] = deleted_en
                report_data['English (app_en.arb)']['backup'] = backup_en
                print(f"{Colors.GREEN}✓ تم تنظيف {ARB_FILE_EN} ({deleted_en} مفتاح){Colors.RESET}")
            
            # تنظيف العربي
            if os.path.exists(ARB_FILE_AR) and unused_ar:
                deleted_ar, backup_ar = clean_arb_file(ARB_FILE_AR, unused_ar, arb_data_ar)
                report_data['Arabic (app_ar.arb)']['deleted'] = deleted_ar
                report_data['Arabic (app_ar.arb)']['backup'] = backup_ar
                print(f"{Colors.GREEN}✓ تم تنظيف {ARB_FILE_AR} ({deleted_ar} مفتاح){Colors.RESET}")
            
            # حفظ التقرير
            report_file = "TRANSLATION_CLEANUP_REPORT.md"
            save_report(report_data, report_file)
            
            print(f"\n{Colors.GREEN}✨ تم بنجاح! تم التنظيف وحفظ التقرير في: {report_file}{Colors.RESET}")
            print(f"\n{Colors.CYAN}💡 لا تنس تشغيل: {Colors.BOLD}flutter gen-l10n{Colors.RESET}{Colors.CYAN} لتحديث ملفات التوليد.{Colors.RESET}\n")
        else:
            print(f"\n{Colors.YELLOW}تم الإلغاء. لم يتم تغيير أي شيء.{Colors.RESET}\n")
            # حفظ تقرير فقط بدون حذف
            report_file = "TRANSLATION_CLEANUP_REPORT.md"
            save_report(report_data, report_file)
            print(f"{Colors.GREEN}✓ تم حفظ التقرير في: {report_file}{Colors.RESET}\n")
    else:
        print(f"{Colors.GREEN}✅ ممتاز! ملفات اللغة نظيفة تماماً.{Colors.RESET}\n")

if __name__ == "__main__":
    main()
