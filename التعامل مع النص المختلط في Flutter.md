المنهجية المتقدمة لإدارة النصوص ثنائية الاتجاه (BiDi) في بيئة تطوير Flutter: دراسة معمارية وتقنية شاملة
تعد معالجة النصوص ثنائية الاتجاه (Bidirectional Text) واحدة من أكثر القضايا تعقيداً في هندسة البرمجيات الحديثة، حيث تتطلب فهماً عميقاً للتفاعل بين أنظمة الكتابة المختلفة التي تتدفق في اتجاهات متقابلة، مثل العربية والإنجليزية. في إطار عمل Flutter، لا تقتصر هذه المهمة على مجرد محاذاة النص جهة اليمين أو اليسار، بل تمتد لتشمل معمارية رندرة منخفضة المستوى تبدأ من محرك النص (Text Engine) وتمر عبر طبقات الرسم (Painting) وتخطيط الفقرات (Paragraph Layout)، وصولاً إلى تفاعلات المستخدم النهائية مثل إدخال النص واختياره.1 يعتمد نجاح تطبيقات Flutter الموجهة للسوق العالمي على قدرة المطورين على موازنة هذه المعايير التقنية لضمان تجربة مستخدم تخلو من العيوب البصرية والوظيفية التي غالباً ما تصاحب النصوص المختلطة.3
المعمارية الهيكلية لنظام النصوص في Flutter
تعتمد بيئة Flutter على نظام رندرة فريد يفصل بين توصيف النص في طبقة الـ Widgets وبين تنفيذه الفعلي في طبقة الـ Rendering. في قلب هذا النظام تقبع فئة TextPainter التي تعمل كمحرك أساسي لتحويل شجرة الـ TextSpan إلى فقرات بصرية قابلة للرسم.1 تبدأ العملية بإنشاء هيكل TextSpan وتمريره إلى TextPainter الذي يتولى استدعاء عملية التخطيط (Layout) لحساب المواضع الدقيقة للغليفات (Glyphs) بناءً على العرض المتاح.1 هذه العملية ليست خطية، حيث يجب على TextPainter التعامل مع خصائص متعددة مثل textAlign وtextDirection وmaxLines وellipsis لضمان أن النص يظهر بشكل صحيح حتى في حالات تجاوز الحدود المكانية المخصصة له.1
تتصل فئة TextPainter مباشرة بـ RenderParagraph وRenderEditable؛ فالأولى مسؤولة عن عرض النصوص الثابتة وإدارة عمليات اختيار النص عبر الإيماءات، بينما الثانية هي المحرك الأساسي لحقول الإدخال، حيث تتعامل مع المؤشر (Caret) الوامض وعمليات التمرير واختيار النص التفاعلي.2 في البيئات ثنائية الاتجاه، تلعب RenderEditable دوراً حاسماً في تحديد كيفية تفسير قيم المحاذاة؛ فعندما يكون اتجاه النص TextDirection.rtl (من اليمين إلى اليسار)، يتم تفسير TextAlign.start على أنه اليمين، مما يضمن توافق الواجهة مع طبيعة اللغة العربية.5
مقارنة المكونات الأساسية في نظام رندرة النصوص

المكون المعماري
الوظيفة الأساسية في معالجة BiDi
العلاقة بمحرك النص المنخفض (Skia/SkParagraph)
TextPainter
حساب إحداثيات المحارف وتخطيط الأسطر
يعمل كوسيط لاستدعاء دوال التخطيط في المحرك الأساسي.1
RenderParagraph
إدارة الفقرات الثابتة وعمليات اختيار النص
يحلل شجرة TextSpan لتحديد اتجاهات Runs المختلفة.2
RenderEditable
معالجة حقول الإدخال وموضع المؤشر
يضمن محاذاة المؤشر بَصرياً مع اتجاه الكتابة الحالي.4
Paragraph
التمثيل النهائي للنص المنسق
كائن منخفض المستوى يتم إنشاؤه بعد عملية التخطيط.2

خوارزمية يونيكود للنصوص ثنائية الاتجاه (UBA) وتحليل أنواع المحارف
تعتبر خوارزمية يونيكود (UAX #9) هي المرجعية التقنية التي يتبعها Flutter لترتيب النصوص المخزنة منطقياً في الذاكرة لتظهر بَصرياً بشكل صحيح.3 النص يُخزن دائماً "بالترتيب المنطقي" (Logical Order)، أي بترتيب كتابته أو نطقه، ولكن عند العرض، يجب إعادة ترتيبه بناءً على خصائص المحارف المكونة له.6 تقسم الخوارزمية المحارف إلى ثلاثة أنواع رئيسية تملي سلوكها عند التداخل 6:
المحارف القوية (Strong Characters) وهي التي تمتلك اتجاهاً ثابتاً لا يتغير، مثل الحروف العربية (يمين) والحروف اللاتينية (يسار). المحارف الضعيفة (Weak Characters) تشمل الأرقام الأوروبية والعربية والعلامات الحسابية، وهي تستمد اتجاهها غالباً من السياق المحيط بها.3 أما المحارف المحايدة (Neutral Characters) مثل المسافات وعلامات الترقيم والأقواس، فهي الأكثر تعقيداً لأن اتجاهها يتحدد كلياً بناءً على النص القوي المجاور لها.3
تتبع الخوارزمية مراحل دقيقة تبدأ بتقسيم النص إلى فقرات مستقلة، ثم تحديد مستوى التضمين (Embedding Level) الأساسي للفقرة بناءً على أول محرف قوي أو بناءً على توجيه المطور.6 يتم بعد ذلك حل المستويات للمحارف الضعيفة والمحايدة، وفي النهاية يتم إعادة ترتيب النص للعرض البصري.6 في الحالات التي تفشل فيها الخوارزمية التلقائية في تقدير الاتجاه الصحيح، يتم اللجوء إلى محارف التحكم (Control Characters) مثل LRM (U+200E) وRLM (U+200F) لفرض اتجاه محدد بَصرياً دون التأثير على المحتوى المنطقي للنص.3
تصنيف محارف يونيكود وتأثيرها الاتجاهي

نوع المحرف
الأمثلة
السلوك في خوارزمية BiDi
قوي (L)
الحروف الإنجليزية، اللاتينية
يفرض اتجاهاً من اليسار إلى اليمين.6
قوي (R/AL)
الحروف العربية، العبرية
يفرض اتجاهاً من اليمين إلى اليسار.6
ضعيف (EN/AN)
الأرقام (123، ١٢٣)
يتبع اتجاه السياق أو المحرف القوي السابق.8
محايد (N)
المسافات، علامات الترقيم
يأخذ اتجاه الفقرة أو المحارف المحيطة به.3

طبقة الوجت وإدارة الاتجاهية عبر Widget Tree
يوفر Flutter نظاماً قوياً لإدارة الاتجاهية يبدأ من الوجت الأساسي Directionality. هذا الوجت يعمل كمزود للبيانات (Data Provider) عبر شجرة الوجت، حيث يحدد اتجاه النص الافتراضي لجميع العناصر التابعة له.3 في التطبيقات العالمية، يتم ضبط Directionality تلقائياً عبر MaterialApp بناءً على "المحلية" (Locale) المختارة، ولكن يمكن للمطورين استخدامه يدوياً لفرض اتجاه معين على جزء محدد من الواجهة.10
أحد الابتكارات المهمة في Flutter هو تقديم الوجت "الاتجاهية" (Directional Widgets) كبدائل للوجت البصرية التقليدية. بدلاً من استخدام إحداثيات مطلقة (يسار ويمين)، يُنصح بشدة باستخدام المفاهيم النسبية (بداية ونهاية).3 على سبيل المثال، استخدام EdgeInsetsDirectional.only(start: 16) يضمن إضافة هامش من اليسار في اللغات LTR ومن اليمين في اللغات RTL، مما يزيل الحاجة لكتابة منطق شرطي لكل لغة.10 هذا المبدأ ينطبق أيضاً على المحاذاة عبر AlignmentDirectional وتموضع العناصر داخل Stack عبر PositionedDirectional.10
تعد الأيقونات جزءاً لا يتجزأ من هذه المنظومة؛ فكثير من أيقونات Material Design تدعم خاصية matchTextDirection التي تقوم بعكس الأيقونة بَصرياً عندما يكون الاتجاه RTL.3 الأيقونات التي تشير إلى حركة للأمام أو الخلف، مثل أسهم التنقل، يجب عكسها لضمان اتساق المعنى البصري مع اتجاه القراءة، بينما تظل الأيقونات التي لا تعتمد على الاتجاه (مثل أيقونات البحث أو الساعات) ثابتة.12
مصفوفة التحول من التصميم البصري إلى التصميم الاتجاهي

المفهوم البصري (ثابت)
البديل الاتجاهي (مرن)
التأثير في بيئة BiDi
EdgeInsets.left
EdgeInsetsDirectional.start
يتحرك تلقائياً مع لغة المستخدم.11
Alignment.centerLeft
AlignmentDirectional.centerStart
يضمن تموضع العناصر في بداية السطر منطقياً.10
Positioned(left:...)
PositionedDirectional(start:...)
يحل مشكلة التموضع داخل الطبقات المتعددة.10
Icons.arrow_back
matchTextDirection: true
يعكس اتجاه السهم ليناسب لغة القراءة.10

معالجة النصوص المختلطة: التحديات البرمجية والحلول التقنية
تظهر التعقيدات الحقيقية عند خلط الكلمات العربية والإنجليزية في سطر واحد، خاصة فيما يتعلق بموضع المؤشر وعلامات الترقيم. مشكلة "علامات الترقيم القافزة" هي الأكثر شيوعاً؛ فعندما تنتهي جملة عربية بكلمة إنجليزية، قد تظهر نقطة النهاية في بداية السطر (على اليمين) بدلاً من يسار الكلمة الإنجليزية، لأن النقطة كمحرف محايد تأخذ اتجاه الفقرة الأساسي (العربي).14 لحل هذه المشكلة، يُستخدم محرف التحكم LRM لوضعه بعد الكلمة الإنجليزية، مما "يخدع" الخوارزمية لتعامل النقطة كجزء من سياق يساري.9
بالنسبة لإدخال النص، يعاني المطورون من مشكلة "قفز المؤشر" (Cursor Jumping) التي تحدث غالباً نتيجة سوء إدارة الحالة في الـ TextField. إذا قام المطور بتحديث نص الـ TextEditingController برمجياً داخل تابع onChanged دون الحفاظ على موضع الاختيار (Selection)، فإن المؤشر يعود تلقائياً إلى البداية (الإزاحة 0)، مما يقطع تدفق الكتابة.17 الحل الصحيح هو التقاط قيمة selection الحالية قبل تحديث النص وإعادة تطبيقها بدقة بعد التحديث.18
في سياق الويب، واجه Flutter تحديات إضافية تتعلق بمحرك الرندرة. استخدام محرك HTML القديم كان يسبب أخطاء مثل ArgumentError عند تمرير الفأرة فوق المحارف العربية، بالإضافة إلى عكس ترتيب الحروف في بعض الحالات.19 الانتقال إلى محرك CanvasKit الذي يعتمد على Skia يوفر دقة رندرة أعلى وتوافقاً تاماً مع خوارزمية BiDi، حيث يتم التعامل مع النصوص كمصفوفة بكسلات مرسومة بدقة بدلاً من الاعتماد على تفسير المتصفح للعناصر.19
محررات النصوص الغنية (Quill) ومعالجة سمة الاتجاه
يتطلب تطوير محررات نصوص غنية (Rich Text Editors) في Flutter التعامل مع تنسيقات بيانات معقدة مثل Quill Delta. يمثل تنسيق Delta النص كقائمة من العمليات (Insert, Delete, Retain) مع سمات مرافقة.22 لدعم النصوص العربية والإنجليزية معاً، يوفر flutter_quill سمة direction التي يمكن ضبطها على rtl لضمان أن الفقرة كاملة تتبع اتجاه اليمين إلى اليسار.23
تطبق سمة الاتجاه عادةً على محرف السطر الجديد (\n) الذي يعمل كحامل لخصائص الفقرة في نموذج Quill.22 واجه المطورون في الإصدارات السابقة مشكلات في القوائم (Lists) وصناديق الاختيار (Checkboxes)، حيث كانت تظل في جهة اليسار حتى لو كان النص عربياً.25 تم حل هذه المشكلات عبر تحديث منطق الرسم في flutter_quill ليدعم عكس العناصر الرأسية (Leading Widgets) بناءً على سمة الاتجاه الخاصة بالعقدة.25 عند تصدير هذه البيانات إلى HTML أو PDF، يجب توخي الحذر لضمان ترجمة هذه السمات إلى وسوم dir="rtl" أو خصائص CSS متوافقة لضمان بقاء التنسيق صحيحاً خارج بيئة التطبيق.27
هيكلية تخزين سمة الاتجاه في Quill Delta JSON

JSON


[
  { "insert": "هذا نص عربي مختلط مع " },
  { "insert": "English", "attributes": { "italic": true } },
  { "insert": "\n", "attributes": { "direction": "rtl", "align": "right" } }
]


هذا الهيكل يوضح كيف يتم فصل خصائص الكلمات (مثل الميول) عن خصائص الفقرة (مثل الاتجاه والمحاذاة)، وهو أمر حيوي لضمان رندرة BiDi دقيقة.22
مشكلات الرندرة المتقدمة: الأربطة والتشكيل (Ligatures & Diacritics)
تعتبر اللغة العربية من اللغات "المشكلة بَصرياً" (Graphically Complex)، حيث تتغير أشكال الحروف بناءً على موضعها وتتداخل لتشكل أربطة معقدة مثل "لا" و"اللـه".30 في Flutter، يعتمد هذا السلوك على محرك SkParagraph وخطوط يونيكود المستخدمة. تم الإبلاغ عن مشكلات في بعض الإصدارات (مثل 3.19) حيث تفشل بعض الأربطة في الظهور بشكل صحيح مع خطوط معينة مثل Lateef وScheherazade New.32
أحد التحديات التقنية الفريدة هو التعامل مع علامات التشكيل (Harakat). عندما يحاول المطورون تلوين علامة التشكيل بلون مختلف عن الحرف الأساسي باستخدام RichText وTextSpan منفصلين، يواجه Flutter صعوبة في "تجميع" التشكيل فوق الحرف، مما يؤدي إلى تباعد بَصري خاطئ أو تداخل غير مرغوب فيه.33 الحل التقليدي يتطلب وضع الحرف والتشكيل في TextSpan واحد، ولكن هذا يمنع تلوينهم بشكل منفصل، مما يمثل قيداً تقنياً في تطبيقات المصحف الشريف أو كتب تعليم اللغة.33
بالنسبة لموضع المؤشر في النصوص ثنائية الاتجاه، كشفت التحقيقات في مستودع Flutter عن خلل في تابع getOffsetForCaret داخل فئة TextPainter. كانت الخوارزمية تعتمد على طلب صناديق النص من المحرك الأساسي، ولكن هذه الصناديق كانت تُعاد بترتيب بَصري (من اليسار لليمين) وليس بترتيب منطقي، مما يسبب أخطاء في تحديد موضع المؤشر عند الحدود بين الكلمات العربية والإنجليزية.34 تم إجراء تحديثات جوهرية لإصلاح هذا السلوك عبر الاعتماد على بيانات مباشرة من محرك التشكيل لضمان دقة المؤشر حتى في أكثر الحالات تعقيداً.34
الفروقات بين المنصات وسلوك لوحة المفاتيح (IME)
تختلف تجربة BiDi في Flutter بناءً على نظام التشغيل ونوع الجهاز. على سبيل المثال، أبلغ مستخدمو أجهزة سامسونج عن مشكلات تتعلق بعدم عمل مفتاح المسافة (Space) عند استخدام لوحة مفاتيح إنجليزية داخل تطبيق يدعم العربية، أو فشل مفتاح المسح (Backspace) في حذف المحارف العربية بشكل فردي.35 يعود ذلك غالباً إلى كيفية تواصل محرك Flutter مع "محرر طريقة الإدخال" (IME) الخاص بالنظام.35
في نظام iOS، يتبع المؤشر سلوكاً خاصاً يسمى "المؤشر العائم" (Floating Cursor) عند الضغط المطول على مفتاح المسافة. في النصوص ثنائية الاتجاه، يجب على Flutter ضمان بقاء المؤشر داخل "منطقة التكوين" (Composing Region) لضمان عدم حدوث تشوه في النص أثناء الكتابة.36 الفشل في مزامنة موضع المؤشر البصري مع الموضع المنطقي في الذاكرة يؤدي إلى ظهور الحروف في أماكن غير متوقعة، وهو ما يتطلب معالجة دقيقة في طبقة RenderEditable.36
مقارنة سلوك المؤشر والاختيار بين الأنظمة

الميزة التقنية
سلوك Android (Samsung)
سلوك iOS
سلوك الويب (CanvasKit)
حركة المؤشر
قد تعاني من jitter عند المحاذاة لليسار.38
يلتزم بمناطق التكوين بدقة عالية.36
دقيقة للغاية وتماثل أداء الهواتف.20
حذف المحارف
تقارير عن حذف كلمات كاملة في العربية.35
حذف حرف بحرف (Grapheme clusters).39
يعتمد على تنفيذ المتصفح والأحداث.40
الاختيار البصري
يميل للاختيار البصري المستمر.14
يدعم الاختيار المنطقي المقسم.14
يدعم كلا النوعين حسب الإعدادات.41

دراسة حالة: التوافق مع Markdown وتدفق البيانات (Streaming)
مع ظهور تطبيقات الدردشة المعتمدة على الذكاء الاصطناعي، أصبح رندرة Markdown للنصوص المتدفقة تحدياً كبيراً. حزمة flutter_markdown الرسمية كانت تعاني من نقص في دعم RTL، مما أدى لظهور فروع مجتمعية (Forks) مثل flutter_markdown_plus لسد هذه الفجوة.42 المشكلة الأساسية في Markdown هي أنه يحول النص إلى شجرة من الـ Widgets؛ فإذا كان النص يبدأ بكلمة إنجليزية في فقرة عربية، قد يتم محاذاة الفقرة كاملة لليسار بشكل خاطئ.44
علاوة على ذلك، عند استقبال الرموز (Tokens) من LLM بشكل متدفق، يحتاج المحلل (Parser) إلى معالجة نصوص غير مكتملة (مثل سطر يبدأ بـ ### ولم ينتهِ بعد). في بيئة BiDi، قد يؤدي ذلك إلى وميض في الواجهة (Flickering) أو قفزات في التخطيط لأن اتجاه السطر قد يتغير مع وصول كلمات جديدة تغير "القوة الاتجاهية" للفقرة.42 يتطلب الحل استخدام مخزن مؤقت (Buffer) ذكي يقوم بتقدير الاتجاه النهائي أو استخدام سمات dir="auto" في الطبقات المنخفضة.45
التوصيات التقنية والمنهجية الختامية
بناءً على هذا التحليل المعمق، يمكن استخلاص مجموعة من التوصيات الجوهرية لمطوري Flutter المحترفين الذين يتعاملون مع النصوص ثنائية الاتجاه. أولاً، يجب تبني المنهجية "الاتجاهية" في كامل الواجهة، مع التخلي التام عن استخدام left وright في الهوامش والمحاذاة.3 ثانياً، في حالات النصوص المختلطة المعقدة، يجب استباق أخطاء خوارزمية UBA عبر الاستخدام الواعي لمحارف التحكم (LRM/RLM) لضمان وضع علامات الترقيم والأقواس في أماكنها الصحيحة بَصرياً.9
ثالثاً، عند تطوير ميزات الإدخال، يجب تجنب التلاعب المباشر بنص الـ TextEditingController دون إدارة دقيقة للـ Selection لمنع قفزات المؤشر المزعجة.17 رابعاً، بالنسبة للتطبيقات التي تعتمد على الويب، يُعد الانتقال إلى محرك CanvasKit ضرورة تقنية لضمان رندرة نصوص عربية صحيحة وتجنب عيوب محرك HTML في التعامل مع BiDi.19 أخيراً، تظل اللغة العربية لغة سياقية بامتياز، مما يتطلب من المطورين ليس فقط اتباع القواعد البرمجية، بل وفهم الطبيعة البصرية والجمالية للخط العربي لضمان أن التكنولوجيا تخدم اللغة ولا تشوهها. إن المستقبل في Flutter يتجه نحو دمج أعمق لمحركات النصوص الذكية، مما سيقلل من الحاجة للتدخل اليدوي، ولكن يظل الفهم العميق لهذه الأساسيات هو الضمان الوحيد لتقديم تطبيقات رائدة عالمياً.3
Works cited
TextPainter class - painting library - Dart API - Flutter, accessed April 14, 2026, https://api.flutter.dev/flutter/painting/TextPainter-class.html
The Breakdown: Flutter Text, accessed April 14, 2026, https://joshi.dev/the-breakdown-flutter-text
Text Directionality | VGV Engineering, accessed April 14, 2026, https://engineering.verygood.ventures/development/internationalization/text_directionality/
RenderEditable class - rendering library - Dart API - Flutter, accessed April 14, 2026, https://api.flutter.dev/flutter/rendering/RenderEditable-class.html
textDirection property - RenderEditable class - rendering library - Dart API - Flutter, accessed April 14, 2026, https://api.flutter.dev/flutter/rendering/RenderEditable/textDirection.html
UAX #9: Unicode Bidirectional Algorithm, accessed April 14, 2026, http://www.unicode.org/reports/tr9/
BiDi Algorithm | ICU Documentation, accessed April 14, 2026, https://unicode-org.github.io/icu/userguide/transforms/bidi.html
flutter_bidi_text - Dart API docs - Pub.dev, accessed April 14, 2026, https://pub.dev/documentation/flutter_bidi_text/latest/
Bidi class - intl library - Dart API - Flutter, accessed April 14, 2026, https://api.flutter.dev/flutter/package-intl_intl/Bidi-class.html
Right to Left (RTL) in Flutter Apps: The Developer's Guide - LeanCode, accessed April 14, 2026, https://leancode.co/blog/right-to-left-in-flutter-app
Complete Guide to RTL Language Support in Flutter Apps | FlutterLocalisation, accessed April 14, 2026, https://flutterlocalisation.com/blog/flutter-rtl-localization-guide
Bidirectionality - Material Design, accessed April 14, 2026, https://m2.material.io/design/usability/bidirectionality.html
Flutter and Directionality - by Carlo Lucera (HatDroid) - Medium, accessed April 14, 2026, https://medium.com/@carlolucera/flutter-and-directionality-d9ac42197fb8
Intro to the Bidirectional Algorithm - RTL:WTF, accessed April 14, 2026, https://rtl.wtf/explained/bidiintro.html
Fixing Arabic RTL Support and Auto-titling - Google AI Studio, accessed April 14, 2026, https://discuss.ai.google.dev/t/fixing-arabic-rtl-support-and-auto-titling/120279
Structural markup and right-to-left text in HTML - W3C, accessed April 14, 2026, https://www.w3.org/International/questions/qa-html-dir.en.html
Why is the cursor in a TextField jumping to the beginning of the text whenever the onChanged event is triggered? - Stack Overflow, accessed April 14, 2026, https://stackoverflow.com/questions/78318772/why-is-the-cursor-in-a-textfield-jumping-to-the-beginning-of-the-text-whenever-t
Flutter how to get cursor in text field to stop moving to the beginning? - Stack Overflow, accessed April 14, 2026, https://stackoverflow.com/questions/56872752/flutter-how-to-get-cursor-in-text-field-to-stop-moving-to-the-beginning
[Web][HTML] Hovering the cursor over Arabic characters causes an ArgumentError · Issue #146588 · flutter/flutter - GitHub, accessed April 14, 2026, https://github.com/flutter/flutter/issues/146588
Flutter web does not render arabic (RTL) characters properly when HTML renderer used. #133374 - GitHub, accessed April 14, 2026, https://github.com/flutter/flutter/issues/133374
flutter_markdown - Dart API docs - Pub.dev, accessed April 14, 2026, https://pub.dev/documentation/flutter_markdown/latest/
Delta - Quill Rich Text Editor, accessed April 14, 2026, https://quilljs.com/docs/delta/
HTML not being rendered properly · Issue #1793 · singerdmx/flutter, accessed April 14, 2026, https://github.com/singerdmx/flutter-quill/issues/1793
Formats - Quill Rich Text Editor, accessed April 14, 2026, https://quilljs.com/docs/formats
problems when using languages ​​that use ltr instead of rtl · Issue ..., accessed April 14, 2026, https://github.com/singerdmx/flutter-quill/issues/1928
flutter-quill/doc/OLD_CHANGELOG.md at master · singerdmx/flutter, accessed April 14, 2026, https://github.com/singerdmx/flutter-quill/blob/master/doc/OLD_CHANGELOG.md
flutter_quill_delta_from_html | Dart package - Pub.dev, accessed April 14, 2026, https://pub.dev/packages/flutter_quill_delta_from_html
flutter_quill_to_pdf | Dart package - Pub.dev, accessed April 14, 2026, https://pub.dev/packages/flutter_quill_to_pdf
The font size not show in html when I convert to html · Issue #1791 · singerdmx/flutter-quill, accessed April 14, 2026, https://github.com/singerdmx/flutter-quill/issues/1791
arabic_reshaper | Flutter package - Pub.dev, accessed April 14, 2026, https://pub.dev/packages/arabic_reshaper
Arabic accents and space bug in Safari - Glyphs Forum, accessed April 14, 2026, https://forum.glyphsapp.com/t/arabic-accents-and-space-bug-in-safari/7486
Arabic Text Rendering Issue with Specific Letter in Flutter #143975 - GitHub, accessed April 14, 2026, https://github.com/flutter/flutter/issues/143975
Arabic diacritcs misbehave when separated into spans · Issue #73108 · flutter/flutter - GitHub, accessed April 14, 2026, https://github.com/flutter/flutter/issues/73108
Caret misplaced in bidi text · Issue #123424 · flutter/flutter - GitHub, accessed April 14, 2026, https://github.com/flutter/flutter/issues/123424
[RTL] TextField Space & backspace Issues When Using Android Physical Device #64821 - GitHub, accessed April 14, 2026, https://github.com/flutter/flutter/issues/64821
Moving cursor while composing should stay in composing region · Issue #122490 · flutter/flutter - GitHub, accessed April 14, 2026, https://github.com/flutter/flutter/issues/122490
Flutter Web: Screen jumps to a completely different location when tapping text in a Multiline TextField #163607 - GitHub, accessed April 14, 2026, https://github.com/flutter/flutter/issues/163607
How to prevent TextField widget's cursor from jittering? - Flutter - Stack Overflow, accessed April 14, 2026, https://stackoverflow.com/questions/61145709/how-to-prevent-textfield-widgets-cursor-from-jittering-flutter
arabic texts issue - mixing English and Arabic words and deleting characters | Community, accessed April 14, 2026, https://community.adobe.com/bug-reports-728/arabic-texts-issue-mixing-english-and-arabic-words-and-deleting-characters-1332346
Text highlighting/selection issue with Flutter 3.27.2 on Web #2450 - GitHub, accessed April 14, 2026, https://github.com/singerdmx/flutter-quill/issues/2450
Master Markdown and Multi-line Selection in Flutter: A Step-by-Step Tutorial - Medium, accessed April 14, 2026, https://medium.com/@amazing_gs/flutter-markdown-using-markdown-with-cross-line-selection-in-flutter-0660dc34ec27
How Foresight Mobile Took Over Maintenance of Google's flutter_markdown Package, accessed April 14, 2026, https://foresightmobile.com/blog/flutter-markdown-plus-google-handover
flutter_markdown_plus | Flutter package - Pub.dev, accessed April 14, 2026, https://pub.dev/packages/flutter_markdown_plus
How to display text in flutter so that RTL language is aligned right and LTR is aligned left?, accessed April 14, 2026, https://stackoverflow.com/questions/58155869/how-to-display-text-in-flutter-so-that-rtl-language-is-aligned-right-and-ltr-is
[Bug]: BiDi text rendering issue when mixing Arabic and English input #2120 - GitHub, accessed April 14, 2026, https://github.com/agentscope-ai/CoPaw/issues/2120
[Help] Flutter Markdown rendering broken when streaming tokens (GptMarkdown / flutter_markdown) : r/flutterhelp - Reddit, accessed April 14, 2026, https://www.reddit.com/r/flutterhelp/comments/1qxf4bm/help_flutter_markdown_rendering_broken_when/
