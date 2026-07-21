// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:home_widget/home_widget.dart';
import 'package:provider/provider.dart';
import 'package:sinan_note/controllers/categories/categories_provider.dart';
import 'package:sinan_note/controllers/master_width_provider.dart';
import 'package:sinan_note/controllers/notes/notes_provider.dart';
import 'package:sinan_note/controllers/selected_note_provider.dart';
import 'package:sinan_note/controllers/settings/settings_provider.dart';
import 'package:sinan_note/core/theme/app_theme.dart';
import 'package:sinan_note/core/utils/app_navigator.dart';
import 'package:sinan_note/core/utils/paste_handler.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';
import 'package:sinan_note/models/note.dart';
import 'package:sinan_note/models/note_mode.dart';
import 'package:sinan_note/screens/desktop/archive_screen_responsive.dart';
import 'package:sinan_note/screens/desktop/locked_notes_screen_responsive.dart';
import 'package:sinan_note/screens/desktop/trash_screen_responsive.dart';
import 'package:sinan_note/screens/onboarding/cinematic_intro_screen.dart';
import 'package:sinan_note/screens/onboarding/splash_screen.dart';
import 'package:sinan_note/screens/other/version_history_screen.dart';
import 'package:sinan_note/screens/other/widget_selection_screen.dart';
import 'package:sinan_note/screens/shared/settings_screen_responsive.dart';
import 'package:sinan_note/screens/sync/google_drive_screen_responsive.dart';
import 'package:sinan_note/services/app_update_service.dart';
import 'package:sinan_note/services/cloud/google_drive_auth.dart';
import 'package:sinan_note/services/intent_handler_service.dart';
import 'package:sinan_note/services/security/security_gate.dart';
import 'package:sinan_note/services/storage/sqlite_database_service.dart';
import 'package:sinan_note/services/widget_service.dart';
import 'package:sinan_note/widgets/home/note_card_utils.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// Global navigator key for error feedback
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Notifier لإعادة التبويب للرئيسية عند Back
final ValueNotifier<int> tabToHomeNotifier = ValueNotifier<int>(0);
// Notifier للتبويب الحالي
final ValueNotifier<int> currentTabIndexNotifier = ValueNotifier<int>(0);
// Notifier لحالة إخفاء الشريط السفلي عند السحب
final ValueNotifier<bool> bottomNavHiddenNotifier = ValueNotifier<bool>(false);

/// Pending intent data — يُحفظ هنا عند وصول intent خارجي (ملف / ويدجت / share)
/// ويُستهلك من MainLayoutScreen بعد اكتمال المصادقة وجاهزية الشاشة الرئيسية
final ValueNotifier<Map?> pendingIntentNotifier = ValueNotifier<Map?>(null);

/// يُعيَّن true عندما تُصبح MainLayoutScreen نشطة وجاهزة لاستقبال intents
bool isMainLayoutActive = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🖥️ Desktop: initialize sqflite FFI
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // 🔒 Initialize SecurityController IMMEDIATELY (lightweight)
  SecurityController().initialize(const SecurityConfig(
    lockEnabled: false,
    lockDelaySeconds: 0,
    privacyBlurEnabled: false,
  ));

  // ⚡ Start app immediately - Isar will initialize in SplashScreen
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => NotesProvider()),
        ChangeNotifierProvider(create: (_) => SelectedNoteProvider()),
        ChangeNotifierProvider(create: (_) => CategoriesProvider()),
        ChangeNotifierProvider(create: (_) => MasterWidthProvider()),
      ],
      child: const ApexNoteApp(),
    ),
  );
}

class ApexNoteApp extends StatefulWidget {
  const ApexNoteApp({super.key});

  @override
  State<ApexNoteApp> createState() => _ApexNoteAppState();
}

class _ApexNoteAppState extends State<ApexNoteApp> with WidgetsBindingObserver {
  static const platform = MethodChannel('com.apexflow.app.sinan/widget');
  static const _intentService = IntentHandlerService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (Platform.isAndroid || Platform.isIOS) {
      _handleWidgetIntent();
      platform.setMethodCallHandler(_handleMethodCall);

      // 🔄 الاستماع للضغط على الويدجت عندما يكون التطبيق في الخلفية
      WidgetService().initialize().then((_) {
        HomeWidget.widgetClicked.listen((Uri? uri) {
          if (uri != null) {
            final noteId =
                int.tryParse(uri.queryParameters['note_id'] ?? '0') ?? 0;
            if (noteId > 0) {
              if (isMainLayoutActive) {
                _openNoteById(noteId);
              } else {
                _storePendingIntent({
                  'action': 'com.apexflow.app.sinan.ACTION_VIEW_NOTE',
                  'note_id': noteId
                });
              }
            } else {
              navigatorKey.currentState?.pushNamed('/widget_selection');
            }
          }
        });
      });

      // ✅ الاستماع للـ pendingIntentNotifier — يُنفّذ الـ intent بعد جاهزية MainLayoutScreen
      pendingIntentNotifier.addListener(_onPendingIntent);
    }
  }

  Future<void> _handleWidgetIntent() async {
    try {
      final data = await platform.invokeMethod('getStartIntent');
      if (data != null && data is Map) {
        // ✅ حفظ الـ intent في الـ notifier بدل تنفيذه مباشرة
        // سيُستهلك من MainLayoutScreen بعد اكتمال المصادقة
        _storePendingIntent(data);
      }
    } catch (_) {}
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    if (call.method == 'onIntent' && call.arguments is Map) {
      // ✅ intents الواردة أثناء تشغيل التطبيق
      final data = call.arguments as Map;
      if (isMainLayoutActive) {
        // التطبيق جاهز — نفّذ مباشرة
        _executeIntent(data);
      } else {
        _storePendingIntent(data);
      }
    }
  }

  /// حفظ الـ intent للتنفيذ لاحقاً بعد جاهزية MainLayoutScreen
  void _storePendingIntent(Map data) {
    if (_intentService.hasValidContent(data)) {
      pendingIntentNotifier.value = Map.from(data);
    }
  }

  /// تنفيذ الـ intent (يُستدعى من MainLayoutScreen بعد الجاهزية)
  void _executeIntent(Map data) {
    final action = data['action'];
    final noteId = data['note_id'] ?? 0;
    final currentNoteId = data['current_note_id'] ?? 0;
    final widgetType = data['widget_type'] ?? 'note';
    final sharedText = data['shared_text'];

    if (sharedText != null && (sharedText as String).isNotEmpty) {
      _openEditorWithSharedText(sharedText);
    } else if (action == 'com.apexflow.app.sinan.ACTION_OPEN_SINAN_FILE') {
      final filePath = data['file_path'] as String?;
      if (filePath != null) _importSinanFile(filePath);
    } else if (action ==
            'com.apexflow.app.sinan.ACTION_SELECT_NOTE_FOR_WIDGET' ||
        (noteId == 0 && action == 'com.apexflow.app.sinan.ACTION_NEW_NOTE')) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => WidgetSelectionScreen(
            widgetType: widgetType,
            currentNoteId: currentNoteId,
          ),
        ),
      );
    } else if (action == 'com.apexflow.app.sinan.ACTION_VIEW_NOTE' &&
        noteId > 0) {
      _openNoteById(noteId);
    }
  }

  void _openEditorWithSharedText(String text) async {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    // ═══ كشف ملف .sinan مُمرر كـ shared_text بدل file_path ═══
    // يحدث عند الاستقبال عبر Apex File Share
    if (text.trimLeft().startsWith('{')) {
      try {
        final decoded = jsonDecode(text) as Map<String, dynamic>;
        if (decoded.containsKey('content') && decoded.containsKey('title')) {
          // هذا ملف .sinan — عالجه كاستيراد ملف
          await _importSinanFromText(decoded);
          return;
        }
      } catch (_) {
        // ليس JSON صالح — تابع كنص عادي
      }
    }

    final settings = Provider.of<SettingsProvider>(context, listen: false);

    // تنظيف النص القادم من المتصفح
    final cleaned = _intentService.cleanSharedText(text);
    final cleanText = cleaned['text'] as String;
    final sourceUrl = cleaned['url'];

    // إذا لم يبقَ نص بعد التنظيف (فقط رابط) → نعامله كـ Shared Link
    final isPureUrl = cleanText.isEmpty && sourceUrl != null;

    final isUrl = isPureUrl ||
        (sourceUrl == null && Uri.tryParse(text.trim())?.hasScheme == true);
    final finalText =
        isPureUrl ? sourceUrl : (cleanText.isNotEmpty ? cleanText : text);
    final mode =
        isUrl ? NoteMode.simple : _intentService.detectNoteMode(finalText);

    // بناء Delta في Isolate قبل فتح المحرر
    String content;
    if (!isUrl) {
      final delta = await buildDeltaInIsolate(finalText);
      content = jsonEncode(delta.toJson());
    } else {
      content = finalText;
    }

    if (!mounted) return;

    // إنشاء الملاحظة بدون حفظ — المستخدم يقرر عند الخروج
    final newNote = Note(
      title: isPureUrl
          ? 'Shared Link'
          : (cleanText.isNotEmpty
              ? _intentService.extractTitle(cleanText)
              : (isUrl ? 'Shared Link' : '')),
      content: content,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      colorIndex:
          settings.getDefaultColorIndex(_intentService.getModeString(mode)),
      noteType: mode.name,
      isProfessional: mode == NoteMode.code,
      isChecklist: mode == NoteMode.checklist,
    );

    if (!mounted) return;

    // فتح المحرر كمعاينة — بدون حفظ تلقائي
    AppNavigator.toEditorViaKey(
      navigatorKey,
      note: newNote,
      mode: mode,
      isSharedPreview: true,
    );
  }

  void _importSinanFile(String filePath) async {
    try {
      final context = navigatorKey.currentContext;
      if (context == null) return;

      if (!mounted) return;

      final note = await _intentService.parseSinanFile(filePath);
      if (!mounted || note == null) return;

      // فتح المحرر بدون حفظ — المستخدم يقرر عند الخروج
      AppNavigator.toEditorViaKey(
        navigatorKey,
        note: note,
        mode: NoteCardUtils.getNoteMode(note),
        isSharedPreview: true,
      );
    } catch (_) {}
  }

  /// استيراد ملف .sinan من نص JSON (عندما يصل كـ shared_text بدل file_path)
  Future<void> _importSinanFromText(Map<String, dynamic> json) async {
    try {
      final context = navigatorKey.currentContext;
      if (context == null) return;

      Note note;

      // الصيغة الكاملة (من toMap) — تحتوي 'updatedAt'
      if (json.containsKey('updatedAt')) {
        json.remove('id');
        note = Note.fromMap(json);
        note.createdAt = DateTime.now();
        note.updatedAt = DateTime.now();
      } else {
        // الصيغة القديمة
        note = Note(
          title: json['title'] as String? ?? '',
          content: json['content'] as String? ?? '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          colorIndex: json['colorIndex'] as int? ?? 0,
          noteType: json['noteType'] as String? ?? 'simple',
          isProfessional: json['noteType'] == 'code',
          isChecklist: json['noteType'] == 'checklist',
        );
      }

      if (!mounted) return;

      // فتح المحرر بدون حفظ — المستخدم يقرر عند الخروج
      AppNavigator.toEditorViaKey(
        navigatorKey,
        note: note,
        mode: NoteCardUtils.getNoteMode(note),
        isSharedPreview: true,
      );
    } catch (_) {}
  }

  void _openNoteById(int noteId) async {
    try {
      final dbService = SqliteDatabaseService();
      final note = await dbService.getNoteById(noteId);
      if (note != null) {
        AppNavigator.toEditorViaKey(
          navigatorKey,
          note: note,
          mode: NoteCardUtils.getNoteMode(note),
          readOnly: true,
        );
      } else {
        AppNavigator.toWidgetSelectionViaKey(navigatorKey);
      }
    } catch (e) {
      AppNavigator.toWidgetSelectionViaKey(navigatorKey);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    pendingIntentNotifier.removeListener(_onPendingIntent);
    super.dispose();
  }

  /// يُستدعى عند تغيير الـ pendingIntentNotifier — ينفذ الـ intent فقط إذا كانت MainLayoutScreen جاهزة
  void _onPendingIntent() {
    final data = pendingIntentNotifier.value;
    if (data == null) return;

    // تحقق أن MainLayoutScreen نشطة (أي اكتملت المصادقة وانتهى SplashScreen)
    if (!isMainLayoutActive) return;
    if (navigatorKey.currentContext == null) return;

    // امسح أولاً لمنع التنفيذ المزدوج
    pendingIntentNotifier.value = null;

    // نفّذ
    _executeIntent(data);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // عند العودة من الخلفية — نجدد الجلسة بصمت بدون dialog
      GoogleDriveAuth.refreshSessionIfNeeded();
      // تثبيت التحديث إذا كان جاهزاً
      AppUpdateService.completeIfDownloaded();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        // SettingsProvider automatically updates SecurityController via _updateSecurityController()
        // No need for manual initialization here - observer is already registered in main()

        return DynamicColorBuilder(
          builder: (lightDynamic, darkDynamic) {
            return MaterialApp(
              title: AppLocalizations.of(context)?.appName ?? 'Sinan Note',
              navigatorKey: navigatorKey,
              locale: settings.locale,
              supportedLocales: const [
                Locale('ar'),
                Locale('en'),
              ],
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              themeMode: settings.themeMode,
              theme: AppTheme.light(
                dynamicScheme: lightDynamic,
                fontFamily: settings.resolvedFontFamily,
              ),
              darkTheme: AppTheme.dark(
                dynamicScheme: darkDynamic,
                fontFamily: settings.resolvedFontFamily,
              ),
              home: const _AppHome(),
              scrollBehavior: const _AppScrollBehavior(),
              builder: (context, child) {
                final scheme = Theme.of(context).colorScheme;
                final isDark = scheme.brightness == Brightness.dark;
                return AnnotatedRegion<SystemUiOverlayStyle>(
                  value: SystemUiOverlayStyle(
                    systemNavigationBarColor: scheme.surface,
                    systemNavigationBarIconBrightness:
                        isDark ? Brightness.light : Brightness.dark,
                  ),
                  child: MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      textScaler: TextScaler.linear(settings.textScaleFactor),
                    ),
                    child: child ?? const SizedBox.shrink(),
                  ),
                );
              },
              routes: {
                '/settings': (context) => const SettingsScreenResponsive(),
                '/trash': (context) => const TrashScreenResponsive(),
                '/archive': (context) => const ArchiveScreenResponsive(),
                '/locked': (context) => const LockedNotesScreenResponsive(),
                '/widget_selection': (context) => const WidgetSelectionScreen(),
                '/drive': (context) => const GoogleDriveScreenResponsive(),
                '/history': (context) => const VersionHistoryScreen(),
              },
              debugShowCheckedModeBanner: false,
            );
          },
        );
      },
    );
  }
}

class _AppHome extends StatefulWidget {
  const _AppHome();

  @override
  State<_AppHome> createState() => _AppHomeState();
}

class _AppHomeState extends State<_AppHome> {
  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        if (!settings.isInitialized) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (settings.isFirstLaunch) return const CinematicIntroScreen();
        return const SplashScreen();
      },
    );
  }
}

// على Linux/Desktop: يمنع Scrollbar التلقائي من إيقاف الـ scroll عند السحب
class _AppScrollBehavior extends MaterialScrollBehavior {
  const _AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };

  @override
  Widget buildScrollbar(
      BuildContext context, Widget child, ScrollableDetails details) {
    switch (Theme.of(context).platform) {
      case TargetPlatform.linux:
      case TargetPlatform.windows:
      case TargetPlatform.macOS:
        return Scrollbar(
          controller: details.controller,
          thumbVisibility: false,
          trackVisibility: false,
          interactive: true,
          child: child,
        );
      default:
        return child;
    }
  }
}
