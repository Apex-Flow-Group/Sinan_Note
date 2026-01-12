# 🧠 Smart Version Control System

## المشكلة (The Problem)
كان النظام القديم يحفظ نسخة جديدة كل 500ms بدون أي فلترة، مما أدى إلى:
- 📊 **تخمة بيانات**: آلاف النسخ المتطابقة
- 🐌 **بطء التطبيق**: قاعدة بيانات ضخمة
- 💾 **هدر الذاكرة**: استهلاك غير ضروري

## الحل (The Solution)
**VersionControlService** - نظام ذكي بـ 3 بوابات فلترة:

### 🚪 البوابة الأولى: بصمة المحتوى (Content Hash)
```dart
final currentHash = md5(title + content);
if (currentHash == lastHash) return; // ❌ محتوى مطابق
```
- يولد بصمة MD5 للمحتوى
- يقارنها بآخر نسخة محفوظة
- يرفض النسخ المتطابقة تماماً

### ⏱️ البوابة الثانية: فلتر الأهمية (Importance Filter)
```dart
if (!isManualAction) {
  if (timeDiff < 300s && contentDiff < 15 chars) return; // ❌ تغيير طفيف
}
```
- تطبق فقط على الحفظ التلقائي
- ترفض التغييرات الطفيفة (<15 حرف) في وقت قصير (<5 دقائق)
- الحفظ اليدوي يتجاوز هذه البوابة

### 🧹 البوابة الثالثة: المكنسة الآلية (Auto Pruning)
```dart
await keepMaxVersions(noteId, 20); // احتفظ بأحدث 20 نسخة فقط
```
- تحذف النسخ القديمة تلقائياً بعد كل حفظ
- تبقي فقط أحدث 20 نسخة
- تمنع تراكم البيانات

## الاستخدام (Usage)

### في الحفظ التلقائي (Auto-save):
```dart
await VersionControlService().smartLogVersion(
  noteId: noteId,
  title: title,
  content: content,
  isManualAction: false, // 👈 حفظ تلقائي
);
```

### في الحفظ اليدوي (Manual save):
```dart
await VersionControlService().smartLogVersion(
  noteId: noteId,
  title: title,
  content: content,
  isManualAction: true, // 👈 حفظ يدوي (يتجاوز فلتر الأهمية)
);
```

## الإعدادات (Settings)
```dart
static const int _minCharsChange = 15;      // أدنى تغيير مطلوب
static const int _minTimeSeconds = 300;     // 5 دقائق بين النسخ
static const int _maxVersionsPerNote = 20;  // الحد الأقصى للنسخ
```

## النتائج المتوقعة (Expected Results)
- ✅ تقليل النسخ بنسبة **90%**
- ✅ قاعدة بيانات أخف وأسرع
- ✅ استهلاك ذاكرة أقل
- ✅ تجربة مستخدم أفضل

## الملفات المعدلة (Modified Files)
1. `lib/services/version_control_service.dart` - الخدمة الجديدة
2. `lib/services/database_service.dart` - إضافة `getLastNoteVersion()` و `keepMaxVersions()` و `runLegacyHistoryCleanup()`
3. `lib/screens/note_editor.dart` - تحديث الحفظ التلقائي
4. `lib/screens/note_editor/controllers/editor_storage_controller.dart` - تحديث الحفظ اليدوي
5. `lib/main.dart` - إضافة استدعاء التنظيف العميق

## 🧹 التنظيف العميق (Legacy Cleanup)

### المشكلة:
المستخدمون القدامى لديهم آلاف النسخ القديمة في قاعدة البيانات.

### الحل:
```dart
// في main.dart - يعمل مرة واحدة فقط
DatabaseService().runLegacyHistoryCleanup();
```

### كيف يعمل:
1. يتحقق من `SharedPreferences` - هل تم التنظيف من قبل؟
2. يبحث عن الملاحظات التي لديها >20 نسخة
3. يحذف النسخ القديمة باستخدام `transaction` للسرعة
4. يحفظ علامة لمنع التكرار

### النتيجة:
- ✅ تنظيف تلقائي عند أول تشغيل بعد التحديث
- ✅ يعمل في الخلفية بدون تأخير
- ✅ آمن تماماً (يستخدم transactions)
- ✅ لا يتكرر أبداً

---

**Made with 🧠 by Apex Flow Group**
