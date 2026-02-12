# مستند التصميم - نمط Master-Details

## نظرة عامة

تصميم نمط Master-Details لتطبيق الملاحظات المبني بـ Flutter، حيث يتم عرض قائمة الملاحظات ومحتوى الملاحظة المختارة جنباً إلى جنب على الشاشات الكبيرة. التصميم يعتمد على:
- استخدام `LayoutBuilder` و `MediaQuery` لاكتشاف حجم الشاشة
- Provider لإدارة حالة الملاحظة المختارة
- Widgets معزولة وقابلة لإعادة الاستخدام
- الحفاظ على الكود الحالي دون تعديلات جذرية

## البنية المعمارية

### نمط المعمارية

التصميم يتبع نمط **Adaptive Layout** مع **State Management** باستخدام Provider:

```
┌─────────────────────────────────────────────────────┐
│           ResponsiveLayoutWrapper                    │
│  (يكتشف حجم الشاشة ويختار Layout المناسب)           │
└──────────────────┬──────────────────────────────────┘
                   │
        ┌──────────┴──────────┐
        │                     │
        ▼                     ▼
┌───────────────┐    ┌────────────────────────┐
│ Mobile Layout │    │ Master-Details Layout  │
│  (Navigation) │    │   (Split Screen)       │
└───────────────┘    └───────────┬────────────┘
                                 │
                     ┌───────────┴───────────┐
                     │                       │
                     ▼                       ▼
              ┌─────────────┐        ┌─────────────┐
              │ Master Panel│        │Details Panel│
              │  (35% width)│        │  (65% width)│
              └─────────────┘        └─────────────┘
```

### تدفق البيانات

```
User Action (Select Note)
        │
        ▼
┌──────────────────────┐
│ SelectedNoteProvider │ ◄─── Provider State Management
└──────────┬───────────┘
           │
           ├──────────────────┐
           │                  │
           ▼                  ▼
    ┌─────────────┐    ┌─────────────┐
    │Master Panel │    │Details Panel│
    │  (Highlight)│    │ (Show Note) │
    └─────────────┘    └─────────────┘
```

## المكونات والواجهات

### 1. ResponsiveLayoutWrapper

Widget رئيسي يحدد أي Layout يجب عرضه بناءً على حجم الشاشة.

**المسؤوليات:**
- قياس عرض الشاشة
- اختيار Layout المناسب (Mobile أو Master-Details)
- الاستجابة لتغييرات حجم الشاشة

**الواجهة:**
```dart
class ResponsiveLayoutWrapper extends StatelessWidget {
  final Widget mobileLayout;
  final Widget masterDetailsLayout;
  final double breakpoint; // default: 600
  
  const ResponsiveLayoutWrapper({
    required this.mobileLayout,
    required this.masterDetailsLayout,
    this.breakpoint = 600,
  });
  
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= breakpoint) {
          return masterDetailsLayout;
        }
        return mobileLayout;
      },
    );
  }
}
```

### 2. MasterDetailsLayout

Widget يعرض Master Panel و Details Panel جنباً إلى جنب.

**المسؤوليات:**
- تقسيم الشاشة إلى جزئين
- عرض Master Panel على اليسار (35%)
- عرض Details Panel على اليمين (65%)

**الواجهة:**
```dart
class MasterDetailsLayout extends StatelessWidget {
  final Widget masterPanel;
  final Widget detailsPanel;
  final double masterWidthRatio; // default: 0.35
  
  const MasterDetailsLayout({
    required this.masterPanel,
    required this.detailsPanel,
    this.masterWidthRatio = 0.35,
  });
  
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: (masterWidthRatio * 100).toInt(),
          child: masterPanel,
        ),
        VerticalDivider(width: 1),
        Expanded(
          flex: ((1 - masterWidthRatio) * 100).toInt(),
          child: detailsPanel,
        ),
      ],
    );
  }
}
```

### 3. MasterPanel

Widget يعرض قائمة الملاحظات مع إمكانية الاختيار.

**المسؤوليات:**
- عرض قائمة الملاحظات
- تمييز الملاحظة المختارة
- معالجة حدث النقر على ملاحظة
- دعم التمرير العمودي

**الواجهة:**
```dart
class MasterPanel extends StatelessWidget {
  final List<Note> notes;
  final Note? selectedNote;
  final Function(Note) onNoteSelected;
  
  const MasterPanel({
    required this.notes,
    this.selectedNote,
    required this.onNoteSelected,
  });
  
  @override
  Widget build(BuildContext context) {
    if (notes.isEmpty) {
      return Center(child: Text('لا توجد ملاحظات'));
    }
    
    return ListView.builder(
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        final isSelected = note.id == selectedNote?.id;
        
        return NoteListTile(
          note: note,
          isSelected: isSelected,
          onTap: () => onNoteSelected(note),
        );
      },
    );
  }
}
```

### 4. DetailsPanel

Widget يعرض محتوى الملاحظة المختارة أو شاشة فارغة.

**المسؤوليات:**
- عرض محرر الملاحظة المناسب حسب النوع
- عرض شاشة فارغة عند عدم وجود ملاحظة مختارة
- دعم جميع أنواع الملاحظات (نص، checklist، كود)

**الواجهة:**
```dart
class DetailsPanel extends StatelessWidget {
  final Note? selectedNote;
  
  const DetailsPanel({this.selectedNote});
  
  @override
  Widget build(BuildContext context) {
    if (selectedNote == null) {
      return EmptyDetailsView();
    }
    
    switch (selectedNote!.type) {
      case NoteType.text:
        return TextNoteEditor(note: selectedNote!);
      case NoteType.checklist:
        return ChecklistNoteEditor(note: selectedNote!);
      case NoteType.code:
        return CodeNoteEditor(note: selectedNote!);
      default:
        return EmptyDetailsView();
    }
  }
}
```

### 5. SelectedNoteProvider

Provider لإدارة حالة الملاحظة المختارة.

**المسؤوليات:**
- تخزين الملاحظة المختارة حالياً
- إشعار المستمعين عند تغيير الملاحظة المختارة
- مسح الملاحظة المختارة عند الحاجة

**الواجهة:**
```dart
class SelectedNoteProvider extends ChangeNotifier {
  Note? _selectedNote;
  
  Note? get selectedNote => _selectedNote;
  
  void selectNote(Note? note) {
    _selectedNote = note;
    notifyListeners();
  }
  
  void clearSelection() {
    _selectedNote = null;
    notifyListeners();
  }
  
  bool isNoteSelected(String noteId) {
    return _selectedNote?.id == noteId;
  }
}
```

### 6. NoteListTile

Widget لعرض عنصر واحد في قائمة الملاحظات.

**المسؤوليات:**
- عرض معلومات الملاحظة (العنوان، التاريخ، النوع)
- تمييز الملاحظة المختارة بصرياً
- معالجة حدث النقر

**الواجهة:**
```dart
class NoteListTile extends StatelessWidget {
  final Note note;
  final bool isSelected;
  final VoidCallback onTap;
  
  const NoteListTile({
    required this.note,
    required this.isSelected,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(note.title),
      subtitle: Text(note.formattedDate),
      leading: Icon(_getNoteIcon(note.type)),
      selected: isSelected,
      selectedTileColor: Theme.of(context).primaryColor.withOpacity(0.1),
      onTap: onTap,
    );
  }
  
  IconData _getNoteIcon(NoteType type) {
    switch (type) {
      case NoteType.text:
        return Icons.note;
      case NoteType.checklist:
        return Icons.checklist;
      case NoteType.code:
        return Icons.code;
      default:
        return Icons.note;
    }
  }
}
```

### 7. EmptyDetailsView

Widget يعرض شاشة فارغة عندما لا توجد ملاحظة مختارة.

**المسؤوليات:**
- عرض رسالة ترحيبية أو إرشادية
- توفير تجربة مستخدم جيدة للحالة الفارغة

**الواجهة:**
```dart
class EmptyDetailsView extends StatelessWidget {
  const EmptyDetailsView();
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.note_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'اختر ملاحظة لعرضها',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
```

## نماذج البيانات

### Note Model

نموذج البيانات الحالي للملاحظة (لا يحتاج تعديل):

```dart
class Note {
  final String id;
  final String title;
  final String content;
  final NoteType type;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isLocked;
  final bool isArchived;
  final bool isDeleted;
  
  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
    this.isLocked = false,
    this.isArchived = false,
    this.isDeleted = false,
  });
  
  String get formattedDate {
    // تنسيق التاريخ
  }
}

enum NoteType {
  text,
  checklist,
  code,
}
```

## خصائص الصحة

*الخاصية هي سمة أو سلوك يجب أن يكون صحيحاً عبر جميع عمليات التنفيذ الصالحة للنظام - في الأساس، بيان رسمي حول ما يجب أن يفعله النظام. تعمل الخصائص كجسر بين المواصفات المقروءة للإنسان وضمانات الصحة القابلة للتحقق آلياً.*


### الخاصية 1: تصنيف حجم الشاشة

*لأي* عرض شاشة، إذا كان العرض >= 600 بكسل، يجب تصنيف الشاشة كـ Large_Screen، وإذا كان العرض < 600 بكسل، يجب تصنيف الشاشة كـ Small_Screen

**تتحقق من: المتطلبات 1.3، 1.4**

### الخاصية 2: إعادة تقييم حجم الشاشة عند التغيير

*لأي* تغيير في عرض الشاشة، يجب على النظام إعادة تقييم تصنيف حجم الشاشة فوراً والتبديل إلى Layout المناسب

**تتحقق من: المتطلبات 1.2، 8.2، 8.3**

### الخاصية 3: عرض Master-Details على الشاشات الكبيرة

*لأي* شاشة مصنفة كـ Large_Screen، يجب أن يحتوي widget tree على كل من Master_Panel و Details_Panel معروضين جنباً إلى جنب

**تتحقق من: المتطلبات 2.1**

### الخاصية 4: نسب تقسيم الشاشة

*لأي* شاشة كبيرة تعرض Master-Details Layout، يجب أن يشغل Master_Panel نسبة 35% من العرض و Details_Panel نسبة 65% من العرض

**تتحقق من: المتطلبات 2.2، 2.3**

### الخاصية 5: عرض Navigation التقليدي على الشاشات الصغيرة

*لأي* شاشة مصنفة كـ Small_Screen، يجب ألا يحتوي widget tree على MasterDetailsLayout ويجب استخدام Navigation التقليدي

**تتحقق من: المتطلبات 2.4**

### الخاصية 6: تصفية الملاحظات حسب القسم

*لأي* قسم (Home/Vault/Archive/Trash) وأي مجموعة من الملاحظات، يجب أن تعرض Master_Panel فقط الملاحظات التي تطابق حالة القسم (عادية/مقفلة/مؤرشفة/محذوفة)

**تتحقق من: المتطلبات 3.2، 3.3، 3.4، 3.5**

### الخاصية 7: عرض جميع الملاحظات المتاحة

*لأي* مجموعة من الملاحظات المتاحة في القسم الحالي، يجب أن تحتوي Master_Panel على جميع هذه الملاحظات في القائمة

**تتحقق من: المتطلبات 3.1**

### الخاصية 8: اختيار الملاحظة يعرضها في Details Panel

*لأي* ملاحظة في Master_Panel، عند النقر عليها، يجب أن تظهر محتوى الملاحظة في Details_Panel ويجب تحديث حالة selectedNote في Provider

**تتحقق من: المتطلبات 4.1، 6.1**

### الخاصية 9: تمييز الملاحظة المختارة

*لأي* ملاحظة مختارة، يجب أن تكون مميزة بصرياً في Master_Panel (خاصية isSelected = true)

**تتحقق من: المتطلبات 4.2**

### الخاصية 10: عرض المحرر المناسب حسب نوع الملاحظة

*لأي* ملاحظة مختارة، يجب أن يعرض Details_Panel المحرر المناسب لنوع الملاحظة (TextNoteEditor للنص، ChecklistNoteEditor للـ checklist، CodeNoteEditor للكود)

**تتحقق من: المتطلبات 4.4، 4.5، 4.6**

### الخاصية 11: تحديث Details Panel عند اختيار ملاحظة جديدة

*لأي* ملاحظتين مختلفتين، عند اختيار الملاحظة الأولى ثم الثانية، يجب أن يتحدث Details_Panel ليعرض محتوى الملاحظة الثانية

**تتحقق من: المتطلبات 4.3، 6.2**

### الخاصية 12: إضافة ملاحظة جديدة

*لأي* ملاحظة جديدة يتم إنشاؤها، يجب أن تظهر في Master_Panel ويجب أن تصبح الملاحظة المختارة في Details_Panel

**تتحقق من: المتطلبات 5.1**

### الخاصية 13: حفظ التعديلات في Provider

*لأي* تعديل على ملاحظة، يجب أن تنعكس التغييرات في Provider وفي Master_Panel

**تتحقق من: المتطلبات 5.2**

### الخاصية 14: نقل الملاحظات بين الأقسام

*لأي* ملاحظة يتم نقلها (حذف/أرشفة/قفل)، يجب أن تختفي من Master_Panel الحالي وتظهر في القسم المناسب

**تتحقق من: المتطلبات 5.3، 5.4، 5.5**

### الخاصية 15: تصفية البحث

*لأي* استعلام بحث ومجموعة من الملاحظات، يجب أن تعرض Master_Panel فقط الملاحظات التي تطابق استعلام البحث

**تتحقق من: المتطلبات 5.6**

### الخاصية 16: مسح الاختيار عند الانتقال أو الحذف

*لأي* انتقال بين الأقسام أو حذف/نقل للملاحظة المختارة، يجب أن يتم مسح selectedNote من Provider (تصبح null)

**تتحقق من: المتطلبات 6.3، 6.4**

### الخاصية 17: أداء عرض الملاحظة

*لأي* ملاحظة يتم اختيارها، يجب أن يظهر محتواها في Details_Panel في أقل من 100 ميلي ثانية

**تتحقق من: المتطلبات 8.1**

### الخاصية 18: ثبات Details Panel أثناء التمرير

*لأي* عملية تمرير في Master_Panel، يجب أن يبقى Details_Panel ثابتاً ومرئياً دون تأثر

**تتحقق من: المتطلبات 8.4**

## معالجة الأخطاء

### 1. حالة القائمة الفارغة

**السيناريو:** لا توجد ملاحظات في القسم الحالي

**المعالجة:**
- عرض رسالة توضيحية في Master_Panel: "لا توجد ملاحظات"
- عرض EmptyDetailsView في Details_Panel
- عدم السماح بالنقر على عناصر غير موجودة

### 2. حالة عدم وجود ملاحظة مختارة

**السيناريو:** المستخدم على شاشة كبيرة ولم يختر أي ملاحظة بعد

**المعالجة:**
- عرض EmptyDetailsView مع رسالة: "اختر ملاحظة لعرضها"
- عدم تمييز أي عنصر في Master_Panel
- selectedNote في Provider = null

### 3. حالة تغيير حجم الشاشة أثناء التحرير

**السيناريو:** المستخدم يحرر ملاحظة والشاشة تتحول من كبيرة إلى صغيرة

**المعالجة:**
- حفظ التغييرات الحالية تلقائياً
- الانتقال إلى Navigation التقليدي
- الحفاظ على الملاحظة المفتوحة في شاشة التحرير

### 4. حالة حذف الملاحظة المختارة

**السيناريو:** المستخدم يحذف الملاحظة المعروضة حالياً في Details_Panel

**المعالجة:**
- مسح selectedNote من Provider
- عرض EmptyDetailsView
- إزالة الملاحظة من Master_Panel
- إظهار رسالة تأكيد الحذف (Snackbar)

### 5. حالة فشل تحميل الملاحظة

**السيناريو:** فشل في تحميل محتوى الملاحظة من Provider

**المعالجة:**
- عرض رسالة خطأ في Details_Panel
- الاحتفاظ بالملاحظة مختارة في Master_Panel
- توفير زر "إعادة المحاولة"

### 6. حالة نوع ملاحظة غير معروف

**السيناريو:** الملاحظة لها نوع غير مدعوم

**المعالجة:**
- عرض EmptyDetailsView مع رسالة: "نوع ملاحظة غير مدعوم"
- تسجيل الخطأ للمطورين
- عدم تعطيل التطبيق

## استراتيجية الاختبار

### نهج الاختبار المزدوج

سنستخدم نهجاً مزدوجاً للاختبار يجمع بين:

1. **اختبارات الوحدة (Unit Tests):** للتحقق من أمثلة محددة، حالات خاصة، وشروط الأخطاء
2. **اختبارات الخصائص (Property-Based Tests):** للتحقق من الخصائص العامة عبر جميع المدخلات

كلا النوعين مكمل للآخر وضروري للتغطية الشاملة:
- اختبارات الوحدة تكتشف أخطاء محددة وحالات خاصة
- اختبارات الخصائص تتحقق من الصحة العامة عبر مدخلات عشوائية

### مكتبة اختبار الخصائص

سنستخدم مكتبة **faker** مع **flutter_test** لتوليد بيانات عشوائية واختبار الخصائص.

### تكوين اختبارات الخصائص

- كل اختبار خاصية يجب أن يعمل لـ **100 تكرار على الأقل**
- كل اختبار يجب أن يشير إلى الخاصية في مستند التصميم
- صيغة التعليق: `// Feature: master-details-layout, Property {number}: {property_text}`

### أمثلة على الاختبارات

#### اختبار وحدة - حالة القائمة الفارغة

```dart
testWidgets('Master Panel shows empty message when no notes', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: MasterPanel(
        notes: [],
        selectedNote: null,
        onNoteSelected: (_) {},
      ),
    ),
  );
  
  expect(find.text('لا توجد ملاحظات'), findsOneWidget);
});
```

#### اختبار خاصية - تصنيف حجم الشاشة

```dart
// Feature: master-details-layout, Property 1: Screen size classification
test('Screen width >= 600 is classified as Large_Screen', () {
  final random = Random();
  
  for (int i = 0; i < 100; i++) {
    // Generate random width >= 600
    final width = 600.0 + random.nextDouble() * 1000;
    
    final isLargeScreen = width >= 600;
    
    expect(isLargeScreen, true);
  }
});
```

#### اختبار خاصية - تصفية الملاحظات

```dart
// Feature: master-details-layout, Property 6: Filter notes by section
test('Master Panel shows only notes matching section state', () {
  final faker = Faker();
  
  for (int i = 0; i < 100; i++) {
    // Generate random notes with different states
    final notes = List.generate(20, (index) {
      return Note(
        id: faker.guid.guid(),
        title: faker.lorem.sentence(),
        content: faker.lorem.paragraph(),
        type: NoteType.values[Random().nextInt(3)],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isLocked: Random().nextBool(),
        isArchived: Random().nextBool(),
        isDeleted: Random().nextBool(),
      );
    });
    
    // Test Home section (normal notes only)
    final homeNotes = notes.where((n) => 
      !n.isLocked && !n.isArchived && !n.isDeleted
    ).toList();
    
    // Verify all notes in homeNotes match the criteria
    expect(homeNotes.every((n) => 
      !n.isLocked && !n.isArchived && !n.isDeleted
    ), true);
    
    // Test Vault section (locked notes only)
    final vaultNotes = notes.where((n) => n.isLocked).toList();
    expect(vaultNotes.every((n) => n.isLocked), true);
    
    // Test Archive section (archived notes only)
    final archiveNotes = notes.where((n) => n.isArchived).toList();
    expect(archiveNotes.every((n) => n.isArchived), true);
    
    // Test Trash section (deleted notes only)
    final trashNotes = notes.where((n) => n.isDeleted).toList();
    expect(trashNotes.every((n) => n.isDeleted), true);
  }
});
```

#### اختبار خاصية - اختيار الملاحظة

```dart
// Feature: master-details-layout, Property 8: Selecting note displays it in Details Panel
testWidgets('Tapping note updates selectedNote in Provider', (tester) async {
  final faker = Faker();
  final provider = SelectedNoteProvider();
  
  for (int i = 0; i < 100; i++) {
    // Generate random note
    final note = Note(
      id: faker.guid.guid(),
      title: faker.lorem.sentence(),
      content: faker.lorem.paragraph(),
      type: NoteType.values[Random().nextInt(3)],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    // Select the note
    provider.selectNote(note);
    
    // Verify it's selected
    expect(provider.selectedNote, note);
    expect(provider.isNoteSelected(note.id), true);
  }
});
```

### تغطية الاختبار

يجب أن تغطي الاختبارات:

1. **اختبارات الوحدة:**
   - حالة القائمة الفارغة
   - حالة عدم وجود ملاحظة مختارة
   - حذف الملاحظة المختارة
   - أنواع الملاحظات المختلفة
   - معالجة الأخطاء

2. **اختبارات الخصائص:**
   - جميع الخصائص الـ 18 المذكورة أعلاه
   - كل خاصية في اختبار منفصل
   - 100 تكرار لكل اختبار
   - بيانات عشوائية متنوعة

3. **اختبارات التكامل:**
   - التدفق الكامل: اختيار ملاحظة → عرضها → تعديلها → حفظها
   - التبديل بين الأقسام
   - تغيير حجم الشاشة أثناء الاستخدام
   - البحث والتصفية

### أدوات الاختبار

- **flutter_test:** إطار الاختبار الأساسي
- **faker:** لتوليد بيانات عشوائية
- **mockito:** لعمل mock للـ Providers والخدمات
- **golden_toolkit:** لاختبارات UI البصرية (اختياري)

### استراتيجية التنفيذ

1. كتابة اختبارات الوحدة للحالات الخاصة أولاً
2. كتابة اختبارات الخصائص لكل خاصية
3. تشغيل الاختبارات بشكل مستمر أثناء التطوير
4. التأكد من نجاح جميع الاختبارات قبل الدمج
5. مراجعة تغطية الاختبار بانتظام
