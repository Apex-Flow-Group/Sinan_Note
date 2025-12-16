# 🧹 دليل التنظيف العميق للمستخدمين القدامى

## 🎯 المشكلة

عند إطلاق التحديث الجديد، سيكون لدى المستخدمين القدامى:
```
❌ آلاف النسخ القديمة غير المفيدة
❌ قاعدة بيانات ضخمة (50+ MB)
❌ بطء في التحميل والحفظ
❌ استهلاك ذاكرة مفرط
```

## 💡 الحل: سكريبت الترحيل لمرة واحدة

### كيف يعمل:
```dart
// في main.dart - يعمل في الخلفية بدون await
DatabaseService().runLegacyHistoryCleanup();
```

---

## 🔍 خطوات التنظيف

### 1️⃣ التحقق من الحالة
```dart
final prefs = await SharedPreferences.getInstance();
bool isCleaned = prefs.getBool('is_legacy_history_cleaned_v1') ?? false;
if (isCleaned) return; // تم التنظيف من قبل
```

**الهدف:** التأكد من عدم تكرار التنظيف

---

### 2️⃣ البحث عن الملاحظات المثقلة
```sql
SELECT note_id, COUNT(*) as count 
FROM note_versions 
GROUP BY note_id 
HAVING count > 20
```

**الهدف:** استهداف الملاحظات التي لديها >20 نسخة فقط

**مثال:**
```
🔍 النتيجة:
  - note_id: 1, count: 500
  - note_id: 5, count: 300
  - note_id: 12, count: 150
```

---

### 3️⃣ الحذف الدفعي (Batch Delete)
```dart
await db.transaction((txn) async {
  for (var row in targetNotes) {
    int noteId = row['note_id'];
    
    // حذف كل شيء ما عدا أحدث 20 نسخة
    await txn.rawDelete('''
      DELETE FROM note_versions 
      WHERE note_id = ? 
      AND id NOT IN (
        SELECT id FROM note_versions 
        WHERE note_id = ? 
        ORDER BY timestamp DESC 
        LIMIT 20
      )
    ''', [noteId, noteId]);
  }
});
```

**الهدف:** حذف سريع وآمن باستخدام transactions

---

### 4️⃣ حفظ العلامة
```dart
await prefs.setBool('is_legacy_history_cleaned_v1', true);
```

**الهدف:** منع التكرار في المستقبل

---

## 📊 مثال عملي

### قبل التنظيف:
```
📝 المستخدم لديه:
  - ملاحظة #1: 500 نسخة
  - ملاحظة #2: 300 نسخة
  - ملاحظة #3: 15 نسخة (لا تحتاج تنظيف)
  - ملاحظة #4: 8 نسخ (لا تحتاج تنظيف)

💾 حجم قاعدة البيانات: 50 MB
⏱️ وقت التحميل: 3 ثواني
```

### بعد التنظيف:
```
🧹 النتيجة:
  - ملاحظة #1: 20 نسخة (حذف 480) ✅
  - ملاحظة #2: 20 نسخة (حذف 280) ✅
  - ملاحظة #3: 15 نسخة (بدون تغيير) ✅
  - ملاحظة #4: 8 نسخ (بدون تغيير) ✅

💾 حجم قاعدة البيانات: 5 MB (تقليل 90%)
⏱️ وقت التحميل: 0.3 ثانية (تحسين 10x)
🎉 تم حذف 760 نسخة في ثوانٍ!
```

---

## 🛡️ لماذا هو آمن؟

### ✅ استخدام Transactions
```dart
await db.transaction((txn) async {
  // كل العمليات تتم كوحدة واحدة
  // إذا فشلت أي عملية، يتم التراجع عن الكل
});
```
**الفائدة:** حماية البيانات من الفساد

---

### ✅ استهداف ذكي
```sql
HAVING count > 20
```
**الفائدة:** لا يمس الملاحظات التي لديها نسخ قليلة

---

### ✅ Fire and Forget
```dart
// في main.dart - بدون await
DatabaseService().runLegacyHistoryCleanup();
```
**الفائدة:** التطبيق يفتح فوراً، التنظيف يعمل في الخلفية

---

### ✅ لا يتكرر أبداً
```dart
prefs.setBool('is_legacy_history_cleaned_v1', true);
```
**الفائدة:** يعمل مرة واحدة فقط

---

## 🧪 كيفية الاختبار

### اختبار 1: محاكاة مستخدم قديم
```dart
// أنشئ 100 نسخة لملاحظة واحدة
for (int i = 0; i < 100; i++) {
  await db.logNoteVersion(NoteVersion(
    noteId: 1,
    title: "Test",
    content: "Version $i",
    timestamp: DateTime.now(),
    action: "test",
  ));
}

// شغّل التنظيف
await DatabaseService().runLegacyHistoryCleanup();

// تحقق من النتيجة
final versions = await db.getNoteHistory(1);
print(versions.length); // النتيجة المتوقعة: 20 ✅
```

---

### اختبار 2: التحقق من عدم التكرار
```dart
// شغّل التنظيف مرتين
await DatabaseService().runLegacyHistoryCleanup();
await DatabaseService().runLegacyHistoryCleanup();

// النتيجة المتوقعة: المرة الثانية تتوقف فوراً ✅
```

---

### اختبار 3: قياس الأداء
```dart
final stopwatch = Stopwatch()..start();

await DatabaseService().runLegacyHistoryCleanup();

stopwatch.stop();
print('⏱️ وقت التنظيف: ${stopwatch.elapsedMilliseconds}ms');
// النتيجة المتوقعة: < 1000ms لـ 1000 نسخة ✅
```

---

## 📈 النتائج المتوقعة

### للمستخدم العادي (10 ملاحظات):
```
📊 قبل: 5,000 نسخة
📊 بعد: 200 نسخة
🗑️ حذف: 4,800 نسخة (96%)
💾 توفير: 45 MB
⏱️ وقت التنظيف: 0.5 ثانية
```

### للمستخدم الكثيف (100 ملاحظة):
```
📊 قبل: 50,000 نسخة
📊 بعد: 2,000 نسخة
🗑️ حذف: 48,000 نسخة (96%)
💾 توفير: 450 MB
⏱️ وقت التنظيف: 2 ثواني
```

---

## 🎯 الخلاصة

**سكريبت الترحيل** يحول "أكداس القمامة" الرقمية إلى أرشيف منظم:

- 🧹 **تنظيف تلقائي**: يعمل عند أول تشغيل بعد التحديث
- ⚡ **سريع**: ثوانٍ معدودة لآلاف النسخ
- 🛡️ **آمن**: يستخدم transactions لحماية البيانات
- 🔒 **لا يتكرر**: يعمل مرة واحدة فقط
- 🎉 **نتائج فورية**: المستخدم يلاحظ السرعة فوراً

---

**Made with 🧹 by Apex Flow Group**
