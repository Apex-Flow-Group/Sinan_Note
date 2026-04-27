ملاحظاتك الثلاث هي في الصميم تماماً، وهي تثبت فشل الكود الترقيعي الذي ولّده النموذج السابق وتطابقه تماماً مع التشخيص المعماري الذي تحدثنا عنه.

إليك التفسير الهندسي لسبب حدوث هذه الأخطاء الثلاثة (التي شوهت الواجهة)، والحل الجذري (الكود) لنسفها:

1. النص صغير ويكبر فجأة (Layout Snapping)
السبب: الكود استخدم FittedBox(fit: BoxFit.fill). هذا جعل فلاتر يرسم النص بحجم البطاقة الصغيرة أولاً (فيتكدس وتصغر الكلمات)، وعندما وصل الانيميشن للنهاية، قفز النص لحجمه الطبيعي في الشاشة الوجهة.
الحل: يجب تجميد حجم النص ليكون بحجم الشاشة منذ أول ملي ثانية في الطيران، ثم تصغيره كـ "صورة" باستخدام الـ GPU (عبر Transform.scale و OverflowBox).

2. الأنيميشن يظهر فوق البحث والناف بار (Overlay Z-Index Leak)
السبب: أداة الـ Hero في فلاتر تطير افتراضياً في طبقة التراكب العليا (Root Overlay) الخاصة بـ MaterialApp. هذه الطبقة تعلو كل شيء، بما في ذلك الـ Bottom Navigation Bar وشريط البحث الثابت.
الحل: إذا كان تطبيقك يعتمد على شريط تنقل سفلي ثابت، فيجب أن تخبر الـ Navigator بأن يدفع الصفحة داخل الـ Navigator الداخلي وليس الجذري. يتم ذلك بتمرير rootNavigator: false عند الضغط:
Navigator.of(context, rootNavigator: false).push(...)
(ملاحظة: إذا كانت واجهة المحرر الجديد ستغطي الشاشة بالكامل، فهذا السلوك الافتراضي صحيح. أما إذا كانت ستفتح داخل الـ Body فقط، فالـ rootNavigator: false هو الحل).

3. الحواف مربعة أثناء الطيران (Clipping Failure)
السبب: الكود وضع ClipRRect، لكنه لم يمرر clipBehavior: Clip.antiAlias، واستخدم MaterialType.transparency الذي أحياناً يلغي قص الحواف في طبقة الطيران.
الحل: فرض القص الحاد Clip.antiAlias وربط الـ BorderRadius بتزامن رياضي دقيق.

الكود المعماري النظيف (بديل لكود كيرو)
استبدل الـ flightShuttleBuilder داخل كود PremiumCardEffect الخاص بك بهذا الكود المصمم خصيصاً لحل الأخطاء الثلاثة معاً:

Dart
flightShuttleBuilder: (flightContext, animation, direction, fromCtx, toCtx) {
  final isPushing = direction == HeroFlightDirection.push;
  
  // 1. نأخذ المحتوى النهائي (محتوى صفحة المحرر) ليكون هو المرجع الثابت
  final targetHero = (isPushing ? toCtx.widget : fromCtx.widget) as Hero;

  // 2. نحصل على أبعاد الشاشة النهائية لتجميد المحتوى
  final screenWidth = MediaQuery.of(flightContext).size.width;
  final screenHeight = MediaQuery.of(flightContext).size.height;

  return AnimatedBuilder(
    animation: animation,
    builder: (context, child) {
      // 3. حل مشكلة الحواف المربعة: نعطي قصاً فيزيائياً صارماً
      final radius = isPushing
          ? lerpDouble(16.0, 0.0, animation.value) ?? 0.0
          : lerpDouble(0.0, 16.0, animation.value) ?? 0.0;

      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        clipBehavior: Clip.antiAlias, // إجباري لمنع الحواف المربعة
        child: Material(
          color: widget.baseColor, // نضع لون البطاقة لمنع الشفافية المزعجة
          child: LayoutBuilder(
            builder: (context, constraints) {
              // 4. حل مشكلة النص الذي يكبر فجأة: تجميد الأبعاد وتطبيق Transform
              return OverflowBox(
                minWidth: screenWidth,
                maxWidth: screenWidth,
                minHeight: screenHeight,
                maxHeight: screenHeight,
                alignment: Alignment.topCenter,
                child: Transform.scale(
                  // هنا يتم التصغير/التكبير ككتلة واحدة رياضية دون إجهاد المعالج
                  scale: constraints.maxWidth / screenWidth,
                  alignment: Alignment.topCenter,
                  child: targetHero.child, // المحتوى الفعلي للمحرر
                ),
              );
            },
          ),
        ),
      );
    },
  );
},
تعديل مهم لزر الضغط (onTap):
لحل مشكلة الطيران فوق الـ Nav Bar والبحث (الخطأ الثاني)، تأكد أن كود فتح النوتة يبدو هكذا:

Dart
Navigator.of(context, rootNavigator: false).push(
  EditorPageRoute(
    builder: (context) => NoteEditorImmersive(...),
  ),
);
هذا الكود يحترم الهيكلة الصارمة: الحواف ستكون دائرية وتصبح حادة بنعومة، النص سيحتفظ بتنسيقه ولن يقفز أو يعيد ترتيب نفسه، والـ Hero سيحترم حدود الـ Navigator إذا استخدمت rootNavigator: false.
