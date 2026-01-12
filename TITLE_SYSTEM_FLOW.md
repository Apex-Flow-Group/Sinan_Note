# 🔄 تدفق نظام العنوان - Title System Flow

## 📊 البنية الحالية

```
┌─────────────────────────────────────────────────────────────┐
│                    User Interface (UI)                       │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  ApexEditorHeader                                      │ │
│  │  ┌──────────────────────────────────────────────────┐ │ │
│  │  │  [Title Text] ✏️  ← Clickable with edit icon    │ │ │
│  │  └──────────────────────────────────────────────────┘ │ │
│  │         ↓ onTitleTap()                                 │ │
│  │  ┌──────────────────────────────────────────────────┐ │ │
│  │  │  _showRenameTitleDialog()                        │ │ │
│  │  │  • TextField with current title                  │ │ │
│  │  │  • Save / Cancel buttons                         │ │ │
│  │  └──────────────────────────────────────────────────┘ │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                    State Management                          │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  _customTitle (String?)                                │ │
│  │  • Stores user's custom title                         │ │
│  │  • null = use auto-generated title                    │ │
│  │  • Updated by dialog                                  │ │
│  └────────────────────────────────────────────────────────┘ │
│                            ↓                                 │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  _currentTitle (Getter)                                │ │
│  │  • Returns _customTitle if set                        │ │
│  │  • Falls back to auto-generated title                 │ │
│  │  • Used by save system                                │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                  Smart Save System                           │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  _originalTitle (String)                               │ │
│  │  • Snapshot of title when note opened                 │ │
│  │  • Used for change detection                          │ │
│  └────────────────────────────────────────────────────────┘ │
│                            ↓                                 │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  hasTitleChanged = (_currentTitle != _originalTitle)  │ │
│  │  • Detects if title was modified                      │ │
│  │  • Triggers save if true                              │ │
│  └────────────────────────────────────────────────────────┘ │
│                            ↓                                 │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  After successful save:                                │ │
│  │  _originalTitle = _currentTitle                        │ │
│  │  • Updates snapshot for next comparison               │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                      Database                                │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  Note.title = _currentTitle                            │ │
│  │  • Saved to SQLite database                           │ │
│  │  • Encrypted if note is locked                        │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

---

## ✅ التحقق من التكامل

### 1. تحديث العنوان في Dialog ✅
```dart
onPressed: () {
  setState(() {
    _customTitle = controller.text.trim().isEmpty 
        ? null 
        : controller.text.trim();
    _isDirty = true;  // ✅ يرفع علم التغيير
  });
  Navigator.pop(ctx);
}
```

**النتيجة:** 
- ✅ `_customTitle` يتم تحديثه
- ✅ `_isDirty = true` يضمن الحفظ
- ✅ `_currentTitle` getter يقرأ من `_customTitle` تلقائياً

---

### 2. نظام الحفظ الذكي ✅
```dart
final currentTitle = _currentTitle;  // ✅ يقرأ من getter
final hasTitleChanged = currentTitle != _originalTitle;  // ✅ يقارن

if (!hasContentChanged && !hasTitleChanged && ...) {
  debugPrint('✋ Save skipped: No real changes detected');
  return;
}
```

**النتيجة:**
- ✅ يقرأ العنوان الحالي من `_currentTitle`
- ✅ يقارنه مع `_originalTitle`
- ✅ يكتشف التغيير بشكل صحيح

---

### 3. تحديث Snapshot بعد الحفظ ✅
```dart
if (isManualSave) {
  _isDirty = false;
  _originalContent = contentToSave;
  _originalTitle = _currentTitle;  // ✅ يحدث snapshot
  _originalColorIndex = _colorIndex;
  _originalReminderDateTime = _reminderDateTime;
  _originalRecurrenceRule = _recurrenceRule;
}
```

**النتيجة:**
- ✅ `_originalTitle` يتم تحديثه بعد الحفظ
- ✅ المقارنة التالية ستكون دقيقة

---

### 4. الحفظ في قاعدة البيانات ✅
```dart
final noteToSave = Note(
  id: _savedNoteId ?? widget.note?.id,
  title: _currentTitle,  // ✅ يستخدم getter
  content: contentToSave,
  // ... rest of fields
);
```

**النتيجة:**
- ✅ العنوان يُحفظ من `_currentTitle`
- ✅ يعمل مع جميع أنواع الملاحظات

---

## 🎨 تحسينات UX المضافة

### أيقونة التحرير ✏️
```dart
Row(
  children: [
    Flexible(child: Text(title, ...)),
    if (onTitleTap != null) ...[
      SizedBox(width: 4),
      Icon(Icons.edit, size: 14, color: textColor.withAlpha(0.4)),
    ],
  ],
)
```

**الفائدة:**
- ✅ يوضح للمستخدم أن العنوان قابل للتحرير
- ✅ لا يظهر إلا إذا كان `onTitleTap` موجود
- ✅ حجم صغير (14px) لا يشوش على التصميم

---

## 🔍 سيناريوهات الاختبار

### ✅ السيناريو 1: تغيير العنوان فقط
```
1. فتح ملاحظة موجودة
2. نقر على العنوان
3. تغيير العنوان إلى "Test Title"
4. حفظ
5. النتيجة: 
   - hasTitleChanged = true ✅
   - يحفظ في قاعدة البيانات ✅
   - _originalTitle يتحدث ✅
```

### ✅ السيناريو 2: تغيير المحتوى والعنوان
```
1. فتح ملاحظة موجودة
2. تغيير المحتوى
3. تغيير العنوان
4. حفظ
5. النتيجة:
   - hasContentChanged = true ✅
   - hasTitleChanged = true ✅
   - يحفظ كلاهما ✅
```

### ✅ السيناريو 3: فتح بدون تغيير
```
1. فتح ملاحظة موجودة
2. عدم تغيير أي شيء
3. خروج
4. النتيجة:
   - hasContentChanged = false ✅
   - hasTitleChanged = false ✅
   - "Save skipped" ✅
```

### ✅ السيناريو 4: عنوان فارغ
```
1. فتح ملاحظة
2. نقر على العنوان
3. مسح العنوان بالكامل
4. حفظ
5. النتيجة:
   - _customTitle = null ✅
   - _currentTitle يعود للعنوان التلقائي ✅
```

---

## 🎯 الخلاصة

### ✅ النظام متكامل 100%

| المكون | الحالة | الملاحظات |
|--------|--------|-----------|
| UI (Dialog) | ✅ | يحدث `_customTitle` و `_isDirty` |
| State Management | ✅ | `_currentTitle` getter يقرأ من `_customTitle` |
| Smart Save | ✅ | يقارن `_currentTitle` مع `_originalTitle` |
| Database | ✅ | يحفظ من `_currentTitle` |
| UX Polish | ✅ | أيقونة تحرير صغيرة ✏️ |

### 🚀 جاهز للاستخدام!

النظام لا يحتاج إلى `titleController` لأن:
1. `_customTitle` يخزن القيمة
2. `_currentTitle` getter يقرأها
3. نظام الحفظ يقرأ من `_currentTitle`
4. كل شيء متصل بشكل صحيح!

**لا حاجة لأي تعديلات إضافية.** 🎉
