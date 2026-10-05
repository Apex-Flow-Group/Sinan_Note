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
import 'package:sinan_note/data/repositories/backup_repository.dart';
import 'package:sinan_note/data/repositories/categories_repository.dart';
import 'package:sinan_note/data/repositories/notes_repository.dart';
import 'package:sinan_note/data/repositories/sync_repository.dart';
import 'package:sinan_note/data/repositories/vault_repository.dart';
import 'package:sinan_note/data/services/app_strings.dart';
import 'package:sinan_note/data/services/app_update_service.dart';
import 'package:sinan_note/data/services/database/app_database.dart';
import 'package:sinan_note/data/services/database/note_mapper.dart';
import 'package:sinan_note/data/services/diagnostics/apex_error_manager.dart';
import 'package:sinan_note/data/services/intent_handler_service.dart';
import 'package:sinan_note/data/services/key_value_store.dart';
import 'package:sinan_note/data/services/legacy_cleanup.dart';
import 'package:sinan_note/data/services/note_side_effects.dart';
import 'package:sinan_note/data/services/notification_service.dart';
import 'package:sinan_note/data/services/sync/drive_sync_remote.dart';
import 'package:sinan_note/data/services/sync/tombstone_store.dart';
import 'package:sinan_note/data/services/sync_scheduler.dart';
import 'package:sinan_note/data/services/widget_service.dart';
import 'package:sinan_note/domain/models/note.dart';
import 'package:sinan_note/domain/models/note_mode.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';
import 'package:sinan_note/ui/core/input/paste_handler.dart';
import 'package:sinan_note/ui/core/keyboard/editor_command_bus.dart';
import 'package:sinan_note/ui/core/navigation/app_navigation.dart';
import 'package:sinan_note/ui/core/navigation/app_navigator.dart';
import 'package:sinan_note/ui/core/theme/app_theme.dart';
import 'package:sinan_note/ui/features/archive/archive_screen_responsive.dart';
import 'package:sinan_note/ui/features/auth/view_models/app_lock.dart';
import 'package:sinan_note/ui/features/auth/view_models/security_controller.dart';
import 'package:sinan_note/ui/features/backup/view_models/backup_view_model.dart';
import 'package:sinan_note/ui/features/categories/view_models/categories_provider.dart';
import 'package:sinan_note/ui/features/diagnostics/unexpected_error_snack_bar.dart';
import 'package:sinan_note/ui/features/diagnostics/view_models/diagnostics.dart';
import 'package:sinan_note/ui/features/editor/view_models/code_tools.dart';
import 'package:sinan_note/ui/features/editor/view_models/editor_view_model.dart';
import 'package:sinan_note/ui/features/home/widgets/note_card_utils.dart';
import 'package:sinan_note/ui/features/layout/view_models/master_width_provider.dart';
import 'package:sinan_note/ui/features/layout/view_models/selected_note_provider.dart';
import 'package:sinan_note/ui/features/notes/view_models/notes_provider.dart';
import 'package:sinan_note/ui/features/onboarding/cinematic_intro_screen.dart';
import 'package:sinan_note/ui/features/onboarding/splash_screen.dart';
import 'package:sinan_note/ui/features/onboarding/view_models/app_startup.dart';
import 'package:sinan_note/ui/features/reminders/view_models/reminder_permissions.dart';
import 'package:sinan_note/ui/features/settings/settings_screen_responsive.dart';
import 'package:sinan_note/ui/features/settings/view_models/settings_provider.dart';
import 'package:sinan_note/ui/features/share/view_models/apex_share.dart';
import 'package:sinan_note/ui/features/sync/google_drive_screen_responsive.dart';
import 'package:sinan_note/ui/features/sync/view_models/sync_view_model.dart';
import 'package:sinan_note/ui/features/trash/trash_screen_responsive.dart';
import 'package:sinan_note/ui/features/vault/locked_notes_screen_responsive.dart';
import 'package:sinan_note/ui/features/vault/view_models/vault_view_model.dart';
import 'package:sinan_note/ui/features/version_history/version_history_screen.dart';
import 'package:sinan_note/ui/features/version_history/view_models/version_history_controller.dart';
import 'package:sinan_note/ui/features/widgets/view_models/home_widgets.dart';
import 'package:sinan_note/ui/features/widgets/widget_selection_screen.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// Global navigator key for error feedback
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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

  // ── نقطة التركيب: البيانات تُنشأ مرة واحدة وتُحقن ─────────────────────
  final database = await AppDatabase.open();
  final store = PreferencesStore();
  final tombstones = TombstoneStore(store);
  final vault = VaultRepository();
  await vault.initialize();
  final notes = NotesRepository(
    db: database,
    vault: vault,
    sideEffects: PlatformNoteSideEffects(),
    deletionLog: tombstones,
  );
  final categories = CategoriesRepository(
      db: database, notes: notes, deletionLog: tombstones, store: store);
  await categories.load();
  final backups =
      BackupRepository(db: database, notes: notes, categories: categories);
  final sync = SyncRepository(
    notes: notes,
    categories: categories,
    tombstones: tombstones,
    remote: DriveSyncRemote(),
    legacy: DriveSyncRemote(fileName: DriveSyncRemote.legacyFileName),
    store: store,
  );
  await sync.initialize();
  SyncScheduler(
      sync: sync, localWrites: [notes.localWrites, categories.localWrites]);
  unawaited(LegacyCleanup.run());
  // الخطأ غير المتوقع في خدمة: رسالة للمستخدم من الواجهة
  ApexErrorManager.onUnexpected = (operation) {
    final context = navigatorKey.currentContext;
    if (context != null) showUnexpectedError(context, operation);
  };
  // خارج شجرة الويدجت (ويدجت الشاشة الرئيسية، نافذة البصمة) بلغة التطبيق
  AppStrings.configure(() {
    final context = navigatorKey.currentContext;
    return (context == null ? null : AppLocalizations.of(context)) ??
        AppStrings.deviceLanguage();
  });

  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: notes),
        Provider.value(value: vault),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(
            create: (_) => NotesProvider(notes: notes, vault: vault)),
        ChangeNotifierProvider(
            create: (_) => VaultViewModel(vault: vault, notes: notes)),
        Provider(create: (_) => BackupViewModel(backups: backups)),
        Provider(create: (_) => EditorSessions(notes: notes)),
        Provider(create: (_) => ReminderPermissions()),
        Provider(create: (_) => AppLock()),
        Provider(create: (_) => HomeWidgets()),
        Provider(create: (_) => Diagnostics()),
        Provider(create: (_) => AppStartup()),
        Provider(create: (_) => CodeTools()),
        Provider(create: (_) => ApexShare()),
        Provider(
            create: (_) => AppNavigation(), dispose: (_, nav) => nav.dispose()),
        ChangeNotifierProvider(create: (_) => SelectedNoteProvider()),
        ChangeNotifierProvider(
            create: (_) => CategoriesProvider(categories: categories)),
        ChangeNotifierProvider(
            create: (_) => SyncViewModel(sync: sync, notes: notes)),
        ChangeNotifierProvider(create: (_) => MasterWidthProvider()),
        ChangeNotifierProvider(create: (_) => EditorCommandBus()),
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
  late final IntentInbox _intents = context.read<AppNavigation>().intents;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _intents.execute = _executeIntent;
    NotificationService.onNoteTapped = (noteId) => _storePendingIntent({
          'action': 'com.apexflow.app.sinan.ACTION_VIEW_NOTE',
          'note_id': noteId,
        });
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
              _storePendingIntent({
                'action': 'com.apexflow.app.sinan.ACTION_VIEW_NOTE',
                'note_id': noteId
              });
            } else {
              navigatorKey.currentState?.pushNamed('/widget_selection');
            }
          }
        });
      });
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
      _storePendingIntent(call.arguments as Map);
    }
  }

  /// يُنفَّذ فوراً إن كانت الشاشة الرئيسية جاهزة، وإلا بعد المصادقة.
  void _storePendingIntent(Map data) {
    if (_intentService.hasValidContent(data)) _intents.deliver(data);
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
        note = NoteMapper.fromMap(json).asNew();
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

  /// من الويدجت أو الإشعار. الملاحظات غير المقفلة فقط — رابط خارجي لا يفتح
  /// ملاحظة مقفلة أبداً.
  void _openNoteById(int noteId) async {
    try {
      final context = navigatorKey.currentContext;
      final note = context?.read<NotesProvider>().cachedNote(noteId);
      if (note != null && !note.isTrashed) {
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
    _intents.execute = null;
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // عند العودة من الخلفية — نجدد الجلسة بصمت بدون dialog
      context.read<SyncViewModel>().restoreSession();
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
                '/history': (context) => ChangeNotifierProvider(
                      create: (_) => VersionHistoryController(
                          notes: context.read<NotesRepository>()),
                      child: const VersionHistoryScreen(),
                    ),
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
