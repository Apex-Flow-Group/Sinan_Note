# lib/ — هيكل الكود

MVVM بطبقات: **View → ViewModel → Repository → Service**، مع Provider للحقن.
القواعد مفروضة باختبار `test/architecture/architecture_test.dart`، وأي مخالفة تُفشل CI.

```
lib/
├── main.dart          # نقطة التركيب: تُنشأ القاعدة والمستودعات مرة وتُحقن
├── domain/            # Dart خالص: النماذج والقواعد (دمج المزامنة، الإصدارات،
│                      #   مسودة المحرر، سياسة المحاولات، معالجة النص)
├── data/
│   ├── repositories/  # مصدر الحقيقة: Notes (الكاتب الوحيد لجدول notes)،
│   │                  #   Vault، Categories، Sync، Backup
│   └── services/      # بلا حالة وبلا واجهة: SQLite، تشفير الخزنة، Drive،
│                      #   الإشعارات، ويدجت الشاشة الرئيسية، الأمان، التشخيص
├── ui/
│   ├── core/          # مشترك: theme، direction، navigation، input، widgets
│   └── features/<f>/  # الشاشات، و view_models/ لكل ميزة
├── l10n/              # app_ar.arb / app_en.arb
└── generated/         # flutter gen-l10n (لا يُعدَّل يدوياً)
```

## القواعد

| | القاعدة |
|---|---|
| A1، A4 | الواجهة لا تستورد `data/services` ولا `data/repositories`؛ تمر عبر ViewModel |
| A2، A7 | `data` و`domain` بلا Flutter UI ولا `BuildContext`، ولا تعرف `ui` ولا `main.dart` |
| A3 | `domain` لا يعتمد على `data` |
| A5 | جدول `notes` يكتبه `NotesRepository` وحده |
| A6 | لا حالة عامة على مستوى الملف؛ الحالة المشتركة تُحقن (مثل `AppNavigation`) |
| T1–T3 | الألوان من `context.colors` و`colorScheme`، والخطوط من `TextTheme` |
| L1، L2 | لا نصوص للمستخدم في الكود: كلها من `AppLocalizations` (أو `AppStrings` خارج الشجرة) |
| D1 | لا يُخزَّن اتجاه النص في المستندات؛ يُشتق عند العرض (`ui/core/direction`) |

## إضافة ميزة

1. القواعد الخالصة في `domain/`، مع اختبار وحدة.
2. الوصول للبيانات عبر مستودع موجود، أو مستودع جديد في `data/repositories`.
3. ViewModel في `ui/features/<f>/view_models/`، يُسجَّل في `main.dart`
   (`test/architecture/providers_test.dart` يتحقق من ذلك).
4. الشاشة في `ui/features/<f>/` تقرأ الـ ViewModel فقط.
5. النصوص في `l10n/app_*.arb` ثم `flutter gen-l10n`.
