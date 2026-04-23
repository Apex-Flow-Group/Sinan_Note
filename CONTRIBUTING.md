# 🤝 دليل المساهمة - Contributing Guide

<div dir="rtl">

## مرحباً بك في مشروع سنان نوت! 👋

نحن نرحب بجميع المساهمات - سواء كانت إصلاح أخطاء، إضافة ميزات، تحسين التوثيق، أو حتى اقتراحات.

---

## إعداد بيئة التطوير

### المتطلبات:
- Flutter SDK 3.0.0+
- Dart SDK 3.0.0+
- Android Studio / VS Code
- Git

### خطوات الإعداد:

```bash
git clone https://github.com/apexflow/sinan-note.git
cd sinan-note
flutter pub get
flutter run
```

### التحقق من عدم وجود أخطاء:
```bash
flutter analyze
flutter test
```

---

## معايير الكود

- اتبع [Effective Dart](https://dart.dev/guides/language/effective-dart)
- استخدم `Theme.of(context).colorScheme` بدل الألوان الثابتة
- استخدم `EdgeInsetsDirectional` لدعم RTL
- كل `try/catch` يجب أن يعالج الخطأ أو يعيد رميه — لا ابتلاع صامت
- الملفات الجديدة لا تتجاوز 400 سطر — قسّم إذا احتجت

### Commit Messages:
```
feat: إضافة ميزة جديدة
fix: إصلاح خطأ
refactor: إعادة هيكلة
docs: تحديث توثيق
```

---

## الإبلاغ عن الأخطاء

افتح Issue مع:
- خطوات إعادة الإنتاج
- السلوك المتوقع vs الفعلي
- الجهاز ونسخة الأندرويد
- Screenshot إن أمكن

---

## التواصل

- **Email:** contact.apex.flow@gmail.com

---

<div align="center">

**Copyright © 2025 Apex Flow Group**

</div>

</div>

---

## 📋 جدول المحتويات

1. [قواعد السلوك](#قواعد-السلوك)
2. [كيف يمكنني المساهمة؟](#كيف-يمكنني-المساهمة)
3. [إعداد بيئة التطوير](#إعداد-بيئة-التطوير)
4. [معايير الكود](#معايير-الكود)
5. [عملية Pull Request](#عملية-pull-request)
6. [الإبلاغ عن الأخطاء](#الإبلاغ-عن-الأخطاء)
7. [اقتراح ميزات جديدة](#اقتراح-ميزات-جديدة)

---

## قواعد السلوك

### قيمنا الأساسية:
- **الاحترام**: نحترم جميع المساهمين بغض النظر عن مستوى خبرتهم
- **التعاون**: نعمل معاً لتحسين المشروع
- **الشفافية**: نتواصل بوضوح ونشارك المعرفة
- **الجودة**: نلتزم بمعايير عالية للكود والتوثيق

### غير مقبول:
- ❌ التنمر أو المضايقة
- ❌ اللغة المسيئة أو التمييزية
- ❌ نشر معلومات خاصة للآخرين
- ❌ السلوك غير المهني

---

## كيف يمكنني المساهمة؟

### 🐛 إصلاح الأخطاء
1. ابحث في [Issues](https://github.com/apexflow/sinan-note/issues) عن أخطاء معروفة
2. اختر issue مع label `good first issue` للبدء
3. علّق على الـ issue لإعلامنا أنك تعمل عليه
4. أنشئ Pull Request مع الإصلاح

### ✨ إضافة ميزات جديدة
1. افتح issue أولاً لمناقشة الميزة
2. انتظر موافقة المشرفين
3. ابدأ التطوير بعد الموافقة
4. أنشئ Pull Request

### 📚 تحسين التوثيق
- إصلاح أخطاء إملائية
- إضافة أمثلة
- ترجمة التوثيق
- تحسين الشروحات

### 🎨 تحسين التصميم
- اقتراحات UI/UX
- تحسين الألوان
- تحسين الأيقونات
- تحسين الانتقالات

---

## إعداد بيئة التطوير

### المتطلبات:
- Flutter SDK 3.0.0+
- Dart SDK 3.0.0+
- Android Studio / VS Code
- Git

### خطوات الإعداد:

#### 1. Fork المشروع
```bash
# اذهب إلى GitHub وانقر على "Fork"
```

#### 2. Clone المشروع
```bash
git clone https://github.com/YOUR_USERNAME/sinan-note.git
cd sinan-note
```

#### 3. إضافة Remote للمشروع الأصلي
```bash
git remote add upstream https://github.com/apexflow/sinan-note.git
```

#### 4. تثبيت الاعتماديات
```bash
flutter pub get
```

#### 5. تشغيل التطبيق
```bash
# Android
flutter run

# Linux
flutter run -d linux

# Windows
flutter run -d windows
```

#### 6. التحقق من عدم وجود أخطاء
```bash
flutter analyze
```

---

## معايير الكود

### 🎯 Dart Style Guide

نتبع [Effective Dart](https://dart.dev/guides/language/effective-dart) مع بعض الإضافات:

#### 1. التسمية (Naming)

**Classes:**
```dart
// ✅ صحيح
class NoteEditor { }
class EncryptionService { }

// ❌ خطأ
class note_editor { }
class encryptionservice { }
```

**Variables & Functions:**
```dart
// ✅ صحيح
final userName = 'Ahmed';
void saveNote() { }

// ❌ خطأ
final UserName = 'Ahmed';
void SaveNote() { }
```

**Constants:**
```dart
// ✅ صحيح
const maxNoteLength = 10000;
const kDefaultColor = Colors.blue;

// ❌ خطأ
const MAX_NOTE_LENGTH = 10000;
```

#### 2. التعليقات (Comments)

**استخدم تعليقات واضحة:**
```dart
// ✅ صحيح
/// Encrypts the note content using AES-256
/// 
/// Returns encrypted string in format "iv:ciphertext"
Future<String> encrypt(String plainText) async { }

// ❌ خطأ (تعليق غير مفيد)
// This function encrypts
Future<String> encrypt(String plainText) async { }
```

**تعليقات TODO:**
```dart
// TODO(username): Add error handling for network failures
// FIXME: Memory leak in vault session
// HACK: Temporary workaround for Android 13 bug
```

#### 3. الهيكلية (Structure)

**فصل المسؤوليات:**
```dart
// ✅ صحيح - منطق منفصل
class NotesProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  
  Future<void> addNote(Note note) async {
    await _db.insertNote(note);
    notifyListeners();
  }
}

// ❌ خطأ - منطق مختلط
class NotesProvider extends ChangeNotifier {
  Future<void> addNote(Note note) async {
    final db = await openDatabase(...); // منطق قاعدة البيانات هنا
    await db.insert(...);
  }
}
```

#### 4. Error Handling

**استخدم try-catch بحكمة:**
```dart
// ✅ صحيح
try {
  await riskyOperation();
} catch (e, stack) {
  ApexDiagnosticsEngine().logError('RiskyOp', e, stack);
  rethrow; // أو معالجة مناسبة
}

// ❌ خطأ (ابتلاع الأخطاء)
try {
  await riskyOperation();
} catch (e) {
  // لا شيء
}
```

#### 5. Async/Await

**استخدم async/await بدلاً من .then():**
```dart
// ✅ صحيح
Future<void> loadNotes() async {
  final notes = await _db.getAllNotes();
  _allNotes = notes;
  notifyListeners();
}

// ❌ خطأ
Future<void> loadNotes() {
  return _db.getAllNotes().then((notes) {
    _allNotes = notes;
    notifyListeners();
  });
}
```

---

### 🎨 UI Guidelines

#### 1. Material Design 3
- استخدم Material 3 components
- اتبع Material You guidelines
- استخدم Theme colors بدلاً من hardcoded colors

```dart
// ✅ صحيح
Container(
  color: Theme.of(context).colorScheme.primary,
)

// ❌ خطأ
Container(
  color: Colors.blue,
)
```

#### 2. RTL Support
- استخدم Directionality-aware widgets
- اختبر على العربية والإنجليزية

```dart
// ✅ صحيح
Padding(
  padding: EdgeInsetsDirectional.only(start: 16),
)

// ❌ خطأ
Padding(
  padding: EdgeInsets.only(left: 16), // لن يعمل مع RTL
)
```

#### 3. Responsive Design
- استخدم MediaQuery للأحجام
- دعم الشاشات الكبيرة (Tablets)

```dart
// ✅ صحيح
final isTablet = MediaQuery.of(context).size.width > 600;
final columns = isTablet ? 3 : 2;
```

---

### 🧪 الاختبارات (Testing)

#### 1. Unit Tests
```dart
// test/services/encryption_service_test.dart
void main() {
  group('EncryptionService', () {
    test('should encrypt and decrypt correctly', () async {
      final plainText = 'Hello World';
      final encrypted = await EncryptionService.encrypt(plainText);
      final decrypted = await EncryptionService.decrypt(encrypted);
      
      expect(decrypted, equals(plainText));
    });
  });
}
```

#### 2. Widget Tests
```dart
// test/widgets/note_card_test.dart
void main() {
  testWidgets('NoteCard displays title and content', (tester) async {
    final note = Note(
      title: 'Test Note',
      content: 'Test Content',
      // ...
    );
    
    await tester.pumpWidget(
      MaterialApp(home: NoteCard(note: note)),
    );
    
    expect(find.text('Test Note'), findsOneWidget);
    expect(find.text('Test Content'), findsOneWidget);
  });
}
```

#### 3. تشغيل الاختبارات
```bash
# جميع الاختبارات
flutter test

# اختبار محدد
flutter test test/services/encryption_service_test.dart

# مع تغطية الكود
flutter test --coverage
```

---

## عملية Pull Request

### خطوات إنشاء PR:

#### 1. أنشئ فرع جديد
```bash
git checkout -b feature/amazing-feature
# أو
git checkout -b fix/bug-description
```

#### 2. اكتب الكود
- اتبع معايير الكود
- أضف تعليقات واضحة
- اكتب اختبارات

#### 3. Commit التغييرات
```bash
git add .
git commit -m "feat: Add amazing feature"
```

**معايير Commit Messages:**
```
feat: إضافة ميزة جديدة
fix: إصلاح خطأ
docs: تحديث التوثيق
style: تحسين التنسيق (لا يؤثر على الكود)
refactor: إعادة هيكلة الكود
test: إضافة اختبارات
chore: مهام صيانة
```

**أمثلة:**
```bash
git commit -m "feat: Add biometric authentication to vault"
git commit -m "fix: Resolve memory leak in vault session"
git commit -m "docs: Update README with new features"
git commit -m "refactor: Split note_editor into controllers"
```

#### 4. Push للـ Fork
```bash
git push origin feature/amazing-feature
```

#### 5. افتح Pull Request
1. اذهب إلى GitHub
2. انقر على "New Pull Request"
3. اختر الفرع الخاص بك
4. املأ النموذج:

```markdown
## الوصف
شرح مختصر للتغييرات

## نوع التغيير
- [ ] إصلاح خطأ (Bug fix)
- [ ] ميزة جديدة (New feature)
- [ ] تحسين (Enhancement)
- [ ] تحديث توثيق (Documentation)

## الاختبار
كيف تم اختبار التغييرات؟

## Screenshots (إن وجدت)
أضف صور للتغييرات في الواجهة

## Checklist
- [ ] الكود يتبع معايير المشروع
- [ ] أضفت تعليقات للكود المعقد
- [ ] أضفت/حدثت التوثيق
- [ ] أضفت اختبارات
- [ ] جميع الاختبارات تعمل
- [ ] لا توجد warnings في flutter analyze
```

#### 6. انتظر المراجعة
- سيراجع المشرفون الكود
- قد يطلبون تعديلات
- ناقش التعليقات بأدب

#### 7. التعديلات (إن طُلبت)
```bash
# عدّل الكود
git add .
git commit -m "fix: Address review comments"
git push origin feature/amazing-feature
```

---

## الإبلاغ عن الأخطاء

### قبل الإبلاغ:
1. ابحث في [Issues](https://github.com/apexflow/sinan-note/issues) - ربما تم الإبلاغ عنه
2. تأكد أنك تستخدم أحدث نسخة
3. جرّب إعادة تثبيت التطبيق

### نموذج الإبلاغ:

```markdown
## وصف الخطأ
شرح واضح ومختصر للخطأ

## خطوات إعادة الإنتاج
1. اذهب إلى '...'
2. انقر على '...'
3. مرر إلى '...'
4. شاهد الخطأ

## السلوك المتوقع
ماذا كنت تتوقع أن يحدث؟

## السلوك الفعلي
ماذا حدث بالفعل؟

## Screenshots
أضف صور إن أمكن

## البيئة:
- الجهاز: [مثال: Pixel 7]
- نظام التشغيل: [مثال: Android 14]
- نسخة التطبيق: [مثال: 2.1.1]

## معلومات إضافية
أي معلومات أخرى مفيدة
```

---

## اقتراح ميزات جديدة

### قبل الاقتراح:
1. ابحث في [Issues](https://github.com/apexflow/sinan-note/issues) - ربما تم اقتراحها
2. تأكد أن الميزة تتماشى مع رؤية المشروع
3. فكر في التأثير على الأداء والأمان

### نموذج الاقتراح:

```markdown
## وصف الميزة
شرح واضح للميزة المقترحة

## المشكلة التي تحلها
ما المشكلة التي ستحلها هذه الميزة؟

## الحل المقترح
كيف تتصور تنفيذ هذه الميزة؟

## البدائل
هل فكرت في حلول بديلة؟

## معلومات إضافية
- Mockups (إن وجدت)
- أمثلة من تطبيقات أخرى
- أي معلومات أخرى
```

---

## الأسئلة الشائعة

### س: هل يجب أن أكون خبيراً في Flutter؟
**ج:** لا! نرحب بجميع المستويات. ابدأ بـ issues مع label `good first issue`.

### س: كم من الوقت تستغرق مراجعة PR؟
**ج:** عادةً 2-5 أيام. قد تستغرق PRs الكبيرة وقتاً أطول.

### س: هل يمكنني العمل على أكثر من issue في نفس الوقت؟
**ج:** نفضل التركيز على issue واحد في كل مرة لضمان الجودة.

### س: ماذا لو رُفض PR الخاص بي؟
**ج:** لا تقلق! سنشرح السبب ونساعدك على التحسين.

### س: هل يمكنني المساهمة بدون كتابة كود؟
**ج:** بالتأكيد! يمكنك:
- تحسين التوثيق
- الإبلاغ عن أخطاء
- اقتراح ميزات
- مساعدة المستخدمين الآخرين

---

## الموارد المفيدة

### Flutter:
- [Flutter Documentation](https://flutter.dev/docs)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)
- [Effective Dart](https://dart.dev/guides/language/effective-dart)

### Material Design:
- [Material Design 3](https://m3.material.io/)
- [Material You](https://material.io/blog/announcing-material-you)

### Git:
- [Git Handbook](https://guides.github.com/introduction/git-handbook/)
- [GitHub Flow](https://guides.github.com/introduction/flow/)

---

## التواصل

### للأسئلة والمساعدة:
- **GitHub Issues**: [طرح سؤال](https://github.com/apexflow/sinan-note/issues/new)
- **Email**: support@apexflow.dev
- **Discussions**: [GitHub Discussions](https://github.com/apexflow/sinan-note/discussions)

---

## الشكر والتقدير

شكراً لاهتمامك بالمساهمة في سنان نوت! 🎉

كل مساهمة - مهما كانت صغيرة - تساعد في تحسين التطبيق للجميع.

---

<div align="center">

**صُنع بـ ❤️ من قبل المجتمع**

[⬆ العودة للأعلى](#-دليل-المساهمة---contributing-guide)

</div>

</div>
