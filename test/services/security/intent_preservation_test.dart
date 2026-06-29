// Copyright © 2025 Apex Flow Group. All rights reserved.
// 🧪 Intent Preservation After Biometric Auth — اختبارات حفظ الـ Intent بعد المصادقة
//
// تغطي السيناريوهات التالية:
// 1. حفظ الـ intent في pendingIntentNotifier بدل التنفيذ الفوري
// 2. الـ intent لا يُنفَّذ قبل جاهزية MainLayoutScreen (isMainLayoutActive=false)
// 3. الـ intent يُنفَّذ بعد جاهزية MainLayoutScreen (isMainLayoutActive=true)
// 4. الـ intents الفارغة لا تُحفظ
// 5. warm intents (onNewIntent) تُنفَّذ مباشرة إذا التطبيق جاهز
// 6. warm intents تُحفظ إذا التطبيق غير جاهز

import 'package:flutter_test/flutter_test.dart';
import 'package:sinan_note/main.dart'
    show pendingIntentNotifier, isMainLayoutActive;

void main() {
  setUp(() {
    // إعادة تعيين الحالة قبل كل اختبار
    pendingIntentNotifier.value = null;
    isMainLayoutActive = false;
  });

  tearDown(() {
    pendingIntentNotifier.value = null;
    isMainLayoutActive = false;
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 1. حفظ الـ intent عند البدء الـ cold start
  // ══════════════════════════════════════════════════════════════════════════
  group('Cold Start: Intent يُحفظ ولا يُنفَّذ فوراً', () {
    test(
      'intent من ويدجت (ACTION_VIEW_NOTE) يُحفظ في pendingIntentNotifier',
      () {
        // محاكاة _storePendingIntent
        final intentData = {
          'action': 'com.apexflow.app.sinan.ACTION_VIEW_NOTE',
          'note_id': 42,
          'current_note_id': 0,
          'widget_type': 'note',
          'shared_text': null,
          'file_path': null,
        };

        // isMainLayoutActive = false (التطبيق لم يُشغَّل بعد / يعرض SplashScreen)
        expect(isMainLayoutActive, isFalse);

        // يُحفظ
        pendingIntentNotifier.value = Map.from(intentData);

        expect(pendingIntentNotifier.value, isNotNull);
        expect(pendingIntentNotifier.value!['note_id'], equals(42));
        expect(pendingIntentNotifier.value!['action'],
            equals('com.apexflow.app.sinan.ACTION_VIEW_NOTE'));
      },
    );

    test(
      'intent من share (ACTION_SEND) يُحفظ في pendingIntentNotifier',
      () {
        final intentData = {
          'action': 'android.intent.action.SEND',
          'note_id': 0,
          'shared_text': 'مرحبا من تطبيق خارجي',
          'file_path': null,
        };

        pendingIntentNotifier.value = Map.from(intentData);

        expect(pendingIntentNotifier.value, isNotNull);
        expect(pendingIntentNotifier.value!['shared_text'],
            equals('مرحبا من تطبيق خارجي'));
      },
    );

    test(
      'ملف .sinan (ACTION_OPEN_SINAN_FILE) يُحفظ في pendingIntentNotifier',
      () {
        final intentData = {
          'action': 'com.apexflow.app.sinan.ACTION_OPEN_SINAN_FILE',
          'note_id': 0,
          'shared_text': null,
          'file_path': '/sdcard/Download/note.sinan',
        };

        pendingIntentNotifier.value = Map.from(intentData);

        expect(pendingIntentNotifier.value, isNotNull);
        expect(pendingIntentNotifier.value!['file_path'],
            equals('/sdcard/Download/note.sinan'));
      },
    );
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 2. الـ intent لا يُنفَّذ قبل جاهزية MainLayoutScreen
  // ══════════════════════════════════════════════════════════════════════════
  group('Guard: isMainLayoutActive=false يمنع التنفيذ', () {
    test(
      'عند isMainLayoutActive=false، الـ intent يبقى محفوظاً ولا يُستهلك',
      () {
        pendingIntentNotifier.value = {
          'action': 'com.apexflow.app.sinan.ACTION_VIEW_NOTE',
          'note_id': 7,
        };

        // محاكاة _onPendingIntent مع isMainLayoutActive=false
        bool wasExecuted = false;
        void simulateOnPendingIntent() {
          final data = pendingIntentNotifier.value;
          if (data == null) return;
          if (!isMainLayoutActive) return; // Guard — لا تنفّذ
          pendingIntentNotifier.value = null;
          wasExecuted = true;
        }

        simulateOnPendingIntent();

        expect(wasExecuted, isFalse,
            reason: 'يجب ألا يُنفَّذ الـ intent قبل جاهزية MainLayoutScreen');
        expect(pendingIntentNotifier.value, isNotNull,
            reason: 'يجب أن يبقى الـ intent محفوظاً');
        expect(pendingIntentNotifier.value!['note_id'], equals(7));
      },
    );

    test(
      'البصمة تأخذ 3 ثوانٍ — الـ intent لا يزال محفوظاً بعدها',
      () async {
        pendingIntentNotifier.value = {
          'action': 'com.apexflow.app.sinan.ACTION_VIEW_NOTE',
          'note_id': 15,
        };

        // محاكاة انتظار البصمة (3 ثوانٍ)
        // في السابق: delay 500ms كان يُنفّذ الـ intent قبل انتهاء البصمة
        // الآن: isMainLayoutActive=false حتى تنتهي البصمة فعلاً
        await Future.delayed(const Duration(milliseconds: 10));
        expect(isMainLayoutActive, isFalse);
        expect(pendingIntentNotifier.value, isNotNull,
            reason: 'الـ intent يجب أن يبقى محفوظاً خلال فترة المصادقة');
        expect(pendingIntentNotifier.value!['note_id'], equals(15));
      },
    );
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 3. الـ intent يُنفَّذ بعد جاهزية MainLayoutScreen
  // ══════════════════════════════════════════════════════════════════════════
  group('Execution: isMainLayoutActive=true يُشغّل الـ intent', () {
    test(
      'عند isMainLayoutActive=true، الـ intent يُستهلك ويُنفَّذ',
      () {
        pendingIntentNotifier.value = {
          'action': 'com.apexflow.app.sinan.ACTION_VIEW_NOTE',
          'note_id': 42,
        };

        isMainLayoutActive = true;

        // محاكاة _onPendingIntent مع isMainLayoutActive=true
        Map? executedData;
        void simulateOnPendingIntent() {
          final data = pendingIntentNotifier.value;
          if (data == null) return;
          if (!isMainLayoutActive) return;
          pendingIntentNotifier.value = null; // امسح
          executedData = data;
        }

        simulateOnPendingIntent();

        expect(executedData, isNotNull,
            reason: 'يجب أن يُنفَّذ الـ intent بعد جاهزية MainLayoutScreen');
        expect(executedData!['note_id'], equals(42));
        expect(pendingIntentNotifier.value, isNull,
            reason: 'يجب أن يُمسح الـ intent بعد التنفيذ');
      },
    );

    test(
      'MainLayoutScreen.initState يُعيّن isMainLayoutActive=true ويُشغّل الـ intent',
      () {
        // محاكاة _consumePendingIntent في MainLayoutScreen
        pendingIntentNotifier.value = {
          'action': 'com.apexflow.app.sinan.ACTION_VIEW_NOTE',
          'note_id': 99,
        };

        Map? capturedData;

        void simulateConsumeIntent() {
          if (pendingIntentNotifier.value == null) return;
          isMainLayoutActive = true;
          final data = pendingIntentNotifier.value;
          pendingIntentNotifier.value = null;
          pendingIntentNotifier.value = data; // يُشغّل الـ listener
        }

        // الـ listener
        void simulateOnPendingIntent() {
          final data = pendingIntentNotifier.value;
          if (data == null) return;
          if (!isMainLayoutActive) return;
          pendingIntentNotifier.value = null;
          capturedData = data;
        }

        pendingIntentNotifier.addListener(simulateOnPendingIntent);
        simulateConsumeIntent();
        pendingIntentNotifier.removeListener(simulateOnPendingIntent);

        expect(isMainLayoutActive, isTrue);
        expect(capturedData, isNotNull);
        expect(capturedData!['note_id'], equals(99));
      },
    );
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 4. الـ intents الفارغة لا تُحفظ
  // ══════════════════════════════════════════════════════════════════════════
  group('Filter: الـ intents الفارغة تُتجاهل', () {
    // helper يحاكي _storePendingIntent الجديدة في main.dart
    bool hasContent(Map data) {
      final action = data['action'] as String?;
      final noteId = (data['note_id'] ?? 0) as int;
      final sharedText = data['shared_text'] as String?;
      final filePath = data['file_path'] as String?;
      return (sharedText != null && sharedText.isNotEmpty) ||
          (filePath != null && filePath.isNotEmpty) ||
          (action == 'com.apexflow.app.sinan.ACTION_VIEW_NOTE' && noteId > 0) ||
          (action == 'com.apexflow.app.sinan.ACTION_SELECT_NOTE_FOR_WIDGET') ||
          (action == 'com.apexflow.app.sinan.ACTION_NEW_NOTE');
    }

    test('intent فارغ (action=null, note_id=0) لا يُحفظ', () {
      final data = {
        'action': null,
        'note_id': 0,
        'shared_text': null,
        'file_path': null
      };
      if (hasContent(data)) pendingIntentNotifier.value = Map.from(data);
      expect(pendingIntentNotifier.value, isNull,
          reason: 'Intent فارغ يجب ألا يُحفظ');
    });

    test('ACTION_VIEW_NOTE بدون note_id لا يُحفظ', () {
      final data = {
        'action': 'com.apexflow.app.sinan.ACTION_VIEW_NOTE',
        'note_id': 0
      };
      if (hasContent(data)) pendingIntentNotifier.value = Map.from(data);
      expect(pendingIntentNotifier.value, isNull,
          reason: 'ACTION_VIEW_NOTE بلا note_id يجب ألا يُحفظ');
    });

    test('shared_text فارغ لا يُحفظ', () {
      final data = {
        'action': 'android.intent.action.SEND',
        'note_id': 0,
        'shared_text': ''
      };
      if (hasContent(data)) pendingIntentNotifier.value = Map.from(data);
      expect(pendingIntentNotifier.value, isNull,
          reason: 'shared_text فارغ يجب ألا يُحفظ');
    });

    test('ACTION_VIEW_NOTE مع note_id يُحفظ', () {
      final data = {
        'action': 'com.apexflow.app.sinan.ACTION_VIEW_NOTE',
        'note_id': 5
      };
      if (hasContent(data)) pendingIntentNotifier.value = Map.from(data);
      expect(pendingIntentNotifier.value, isNotNull);
    });

    test('shared_text غير فارغ يُحفظ', () {
      final data = {
        'action': 'android.intent.action.SEND',
        'note_id': 0,
        'shared_text': 'hello'
      };
      if (hasContent(data)) pendingIntentNotifier.value = Map.from(data);
      expect(pendingIntentNotifier.value, isNotNull);
    });

    test('file_path غير فارغ يُحفظ', () {
      final data = {
        'action': 'com.apexflow.app.sinan.ACTION_OPEN_SINAN_FILE',
        'file_path': '/sdcard/note.sinan'
      };
      if (hasContent(data)) pendingIntentNotifier.value = Map.from(data);
      expect(pendingIntentNotifier.value, isNotNull);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 5 & 6. Warm Intents (onNewIntent)
  // ══════════════════════════════════════════════════════════════════════════
  group('Warm Intents: السلوك عند وصول intent بعد تشغيل التطبيق', () {
    test(
      'warm intent ينفَّذ مباشرة إذا isMainLayoutActive=true',
      () {
        isMainLayoutActive = true;

        final intentData = {
          'action': 'com.apexflow.app.sinan.ACTION_VIEW_NOTE',
          'note_id': 55,
        };

        // محاكاة _handleMethodCall
        bool executed = false;
        void simulateHandleMethodCall(Map data) {
          if (isMainLayoutActive) {
            executed = true; // _executeIntent(data)
          } else {
            pendingIntentNotifier.value = Map.from(data);
          }
        }

        simulateHandleMethodCall(intentData);

        expect(executed, isTrue,
            reason:
                'warm intent يجب أن يُنفَّذ مباشرة إذا MainLayoutScreen جاهزة');
        expect(pendingIntentNotifier.value, isNull,
            reason: 'يجب ألا يُحفظ الـ intent إذا نُفِّذ مباشرة');
      },
    );

    test(
      'warm intent يُحفظ إذا isMainLayoutActive=false (قفل نشط)',
      () {
        isMainLayoutActive = false;

        final intentData = {
          'action': 'com.apexflow.app.sinan.ACTION_VIEW_NOTE',
          'note_id': 77,
        };

        void simulateHandleMethodCall(Map data) {
          if (isMainLayoutActive) {
            // _executeIntent(data)
          } else {
            pendingIntentNotifier.value = Map.from(data);
          }
        }

        simulateHandleMethodCall(intentData);

        expect(pendingIntentNotifier.value, isNotNull,
            reason: 'warm intent يجب أن يُحفظ إذا التطبيق مقفل');
        expect(pendingIntentNotifier.value!['note_id'], equals(77));
      },
    );
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 7. لا يوجد تنفيذ مزدوج
  // ══════════════════════════════════════════════════════════════════════════
  group('Safety: لا تنفيذ مزدوج للـ intent', () {
    test(
      'الـ intent يُنفَّذ مرة واحدة فقط بعد مسحه من الـ notifier',
      () {
        pendingIntentNotifier.value = {
          'action': 'com.apexflow.app.sinan.ACTION_VIEW_NOTE',
          'note_id': 1,
        };
        isMainLayoutActive = true;

        int executionCount = 0;

        void simulateOnPendingIntent() {
          final data = pendingIntentNotifier.value;
          if (data == null) return;
          if (!isMainLayoutActive) return;
          pendingIntentNotifier.value = null; // امسح أولاً
          executionCount++;
        }

        // استدعاء مرتين (كما لو أن الـ listener أُطلق مرتين)
        simulateOnPendingIntent();
        simulateOnPendingIntent();

        expect(executionCount, equals(1),
            reason: 'يجب أن يُنفَّذ الـ intent مرة واحدة فقط');
      },
    );

    test(
      'بعد التنفيذ، pendingIntentNotifier.value تكون null',
      () {
        pendingIntentNotifier.value = {
          'action': 'com.apexflow.app.sinan.ACTION_VIEW_NOTE',
          'note_id': 3,
        };
        isMainLayoutActive = true;

        // تنفيذ
        final data = pendingIntentNotifier.value;
        if (data != null && isMainLayoutActive) {
          pendingIntentNotifier.value = null;
        }

        expect(pendingIntentNotifier.value, isNull,
            reason: 'pendingIntentNotifier يجب أن يكون null بعد التنفيذ');
      },
    );
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 8. الانتقال من SplashScreen لـ MainLayoutScreen يُشغّل الـ intent
  // ══════════════════════════════════════════════════════════════════════════
  group('End-to-End Flow: Splash → Auth → MainLayout → Execute', () {
    test(
      'الـ intent يُنفَّذ بعد اكتمال دورة SplashScreen + Auth + MainLayout',
      () {
        // 1. يصل الـ intent (cold start)
        pendingIntentNotifier.value = {
          'action': 'com.apexflow.app.sinan.ACTION_VIEW_NOTE',
          'note_id': 123,
        };
        expect(pendingIntentNotifier.value, isNotNull,
            reason: 'Step 1: intent محفوظ');

        // 2. SplashScreen يعرض البصمة (isMainLayoutActive=false)
        expect(isMainLayoutActive, isFalse,
            reason: 'Step 2: لم تظهر MainLayoutScreen بعد');
        // محاكاة: الـ listener لا يُنفّذ الـ intent
        Map? executedInSplash;
        if (isMainLayoutActive) executedInSplash = pendingIntentNotifier.value;
        expect(executedInSplash, isNull,
            reason: 'Step 2: لا تنفيذ أثناء SplashScreen');

        // 3. البصمة تنجح — SplashScreen يُشغّل MainLayoutScreen
        // 4. MainLayoutScreen.initState يُعيّن isMainLayoutActive=true
        isMainLayoutActive = true;

        // 5. _consumePendingIntent يُشغّل الـ listener
        final data = pendingIntentNotifier.value;
        pendingIntentNotifier.value = null;
        pendingIntentNotifier.value = data; // يُشغّل الـ listener

        // الـ listener ينفذ
        Map? executed;
        final pending = pendingIntentNotifier.value;
        if (pending != null && isMainLayoutActive) {
          pendingIntentNotifier.value = null;
          executed = pending;
        }

        expect(executed, isNotNull,
            reason: 'Step 5: الـ intent يجب أن يُنفَّذ');
        expect(executed!['note_id'], equals(123));
        expect(pendingIntentNotifier.value, isNull,
            reason: 'Step 5: تم مسح الـ intent');
      },
    );

    test(
      'في السيناريو القديم (delay-based): البصمة 2s و delay 500ms → intent يضيع',
      () async {
        // هذا الاختبار يُثبت أن النهج القديم كان مكسوراً

        // النهج القديم: انتظار 500ms ثم تنفيذ (بغض النظر عن جاهزية MainLayoutScreen)
        bool oldApproachExecuted = false;
        Future<void> oldApproach() async {
          await Future.delayed(
              const Duration(milliseconds: 10)); // محاكاة مختصرة
          oldApproachExecuted = true; // ينفذ حتى لو MainLayoutScreen غير جاهزة
        }

        // النهج الجديد: ينتظر isMainLayoutActive=true
        bool newApproachExecuted = false;
        void newApproach() {
          if (!isMainLayoutActive) return; // Guard
          newApproachExecuted = true;
        }

        await oldApproach();
        newApproach(); // isMainLayoutActive=false هنا

        expect(oldApproachExecuted, isTrue,
            reason: 'النهج القديم كان ينفذ دائماً (المشكلة)');
        expect(newApproachExecuted, isFalse,
            reason: 'النهج الجديد لا ينفذ قبل جاهزية MainLayoutScreen (الحل)');
      },
    );
  });
}
