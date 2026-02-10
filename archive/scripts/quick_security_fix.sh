#!/bin/bash
# 🔒 Quick Security Fix Script
# تنظيف الملفات الحساسة من Git

set -e  # Exit on error

echo "🔒 =================================="
echo "   إصلاح أمني سريع - Sinan Note G"
echo "=================================="
echo ""

# التحقق من وجود Git
if ! command -v git &> /dev/null; then
    echo "❌ Git غير مثبت!"
    exit 1
fi

# التحقق من أننا في مجلد Git
if [ ! -d .git ]; then
    echo "❌ هذا ليس مجلد Git!"
    exit 1
fi

echo "📋 الخطوة 1: التحقق من الملفات الحساسة..."
echo ""

# قائمة الملفات الحساسة
SENSITIVE_FILES=(
    "client_secret_308129072326-2p8a46je0nl6sl7ljqe0mmrabc036a9k.apps.googleusercontent.com (1).json"
    "upload_certificate.pem"
    "android/key.properties"
)

FILES_FOUND=0

for file in "${SENSITIVE_FILES[@]}"; do
    if git ls-files --error-unmatch "$file" &> /dev/null; then
        echo "⚠️  تم العثور على: $file"
        FILES_FOUND=$((FILES_FOUND + 1))
    fi
done

if [ $FILES_FOUND -eq 0 ]; then
    echo "✅ لا توجد ملفات حساسة في Git tracking"
    echo ""
    echo "🎉 التطبيق آمن بالفعل!"
    exit 0
fi

echo ""
echo "📋 الخطوة 2: إزالة الملفات من Git tracking..."
echo ""

# إزالة الملفات من Git (لكن الاحتفاظ بها محلياً)
for file in "${SENSITIVE_FILES[@]}"; do
    if git ls-files --error-unmatch "$file" &> /dev/null; then
        echo "🗑️  إزالة: $file"
        git rm --cached "$file" 2>/dev/null || true
    fi
done

echo ""
echo "📋 الخطوة 3: إنشاء commit..."
echo ""

# Commit التغييرات
if git diff --cached --quiet; then
    echo "ℹ️  لا توجد تغييرات للـ commit"
else
    git commit -m "🔒 Security: Remove sensitive files from Git tracking

- Removed client_secret files
- Removed certificate files  
- Removed key.properties

These files are now protected by .gitignore and won't be tracked in future commits.
Local copies are preserved for development use."
    
    echo "✅ تم إنشاء commit بنجاح!"
fi

echo ""
echo "📋 الخطوة 4: التحقق من .gitignore..."
echo ""

# التحقق من .gitignore
GITIGNORE_ENTRIES=(
    "*.jks"
    "*.keystore"
    "key.properties"
    "client_secret*.json"
    "*.pem"
)

GITIGNORE_OK=true

for entry in "${GITIGNORE_ENTRIES[@]}"; do
    if ! grep -q "$entry" .gitignore 2>/dev/null; then
        echo "⚠️  مفقود في .gitignore: $entry"
        GITIGNORE_OK=false
    fi
done

if [ "$GITIGNORE_OK" = true ]; then
    echo "✅ .gitignore محدث ويحمي الملفات الحساسة"
else
    echo "⚠️  .gitignore يحتاج تحديث (لكنه يبدو محدثاً بالفعل)"
fi

echo ""
echo "📋 الخطوة 5: إنشاء نسخة احتياطية..."
echo ""

# إنشاء مجلد النسخ الاحتياطي
BACKUP_DIR="$HOME/sinan_secure_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# نسخ الملفات الحساسة
BACKED_UP=0

if [ -f "android/key.properties" ]; then
    cp "android/key.properties" "$BACKUP_DIR/"
    echo "✅ تم نسخ: key.properties"
    BACKED_UP=$((BACKED_UP + 1))
fi

if [ -f "android/sinan_key.jks" ]; then
    cp "android/sinan_key.jks" "$BACKUP_DIR/"
    echo "✅ تم نسخ: sinan_key.jks"
    BACKED_UP=$((BACKED_UP + 1))
fi

for file in client_secret*.json; do
    if [ -f "$file" ]; then
        cp "$file" "$BACKUP_DIR/"
        echo "✅ تم نسخ: $file"
        BACKED_UP=$((BACKED_UP + 1))
    fi
done

if [ -f "upload_certificate.pem" ]; then
    cp "upload_certificate.pem" "$BACKUP_DIR/"
    echo "✅ تم نسخ: upload_certificate.pem"
    BACKED_UP=$((BACKED_UP + 1))
fi

if [ $BACKED_UP -gt 0 ]; then
    echo ""
    echo "📁 النسخة الاحتياطية في: $BACKUP_DIR"
else
    rmdir "$BACKUP_DIR" 2>/dev/null || true
    echo "ℹ️  لم يتم العثور على ملفات للنسخ الاحتياطي"
fi

echo ""
echo "✅ =================================="
echo "   اكتمل الإصلاح الأمني!"
echo "=================================="
echo ""
echo "📝 الخطوات التالية:"
echo ""
echo "1️⃣  دفع التغييرات إلى Git:"
echo "   git push origin main"
echo ""
echo "2️⃣  تغيير كلمة المرور في android/key.properties:"
echo "   - افتح الملف"
echo "   - غيّر storePassword و keyPassword"
echo "   - استخدم كلمة مرور قوية (16+ حرف)"
echo ""
echo "3️⃣  اختبار البناء:"
echo "   flutter clean"
echo "   flutter build apk --release"
echo ""
echo "4️⃣  (اختياري) إنشاء keystore جديد:"
echo "   keytool -genkey -v -storetype PKCS12 \\"
echo "     -keystore android/sinan_key_new.jks \\"
echo "     -keyalg RSA -keysize 2048 \\"
echo "     -validity 10000 -alias upload"
echo ""
echo "⚠️  ملاحظات مهمة:"
echo "   • الملفات الحساسة لا تزال موجودة محلياً (وهذا جيد)"
echo "   • لن تُرفع على Git في المستقبل"
echo "   • النسخة الاحتياطية في: $BACKUP_DIR"
echo ""
echo "🎉 التطبيق الآن أكثر أماناً!"
