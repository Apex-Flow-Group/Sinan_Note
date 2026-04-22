// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:async';
import 'dart:io';

import 'package:apex_note/controllers/categories/categories_provider.dart';
import 'package:apex_note/controllers/notes/notes_provider.dart';
import 'package:apex_note/controllers/settings/settings_provider.dart';
import 'package:apex_note/core/theme/app_theme.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:apex_note/models/note.dart';
import 'package:apex_note/models/note_mode.dart';
import 'package:apex_note/providers/selected_note_provider.dart';
import 'package:apex_note/screens/desktop/archive_screen_responsive.dart';
import 'package:apex_note/screens/desktop/locked_notes_screen_responsive.dart';
import 'package:apex_note/screens/desktop/trash_screen_responsive.dart';
import 'package:apex_note/screens/onboarding/cinematic_intro_screen.dart';
import 'package:apex_note/screens/onboarding/splash_screen.dart';
import 'package:apex_note/screens/other/version_history_screen.dart';
import 'package:apex_note/screens/other/widget_selection_screen.dart';
import 'package:apex_note/screens/shared/note_editor.dart';
import 'package:apex_note/screens/shared/note_view_screen.dart';
import 'package:apex_note/screens/shared/settings_screen_responsive.dart';
import 'package:apex_note/screens/sync/google_drive_screen_responsive.dart';
import 'package:apex_note/services/cloud/google_drive_auth.dart';
import 'package:apex_note/services/content_guard.dart';
import 'package:apex_note/services/security/security_gate.dart';
import 'package:apex_note/services/storage/isar_database_service.dart';
import 'package:apex_note/services/widget_service.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:home_widget/home_widget.dart';
import 'package:provider/provider.dart';

// Global navigator key for error feedback
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Notifier لإعادة التبويب للرئيسية عند Back
final ValueNotifier<int> tabToHomeNotifier = ValueNotifier<int>(0);
// Notifier للتبويب الحالي
final ValueNotifier<int> currentTabIndexNotifier = ValueNotifier<int>(0);
// Notifier لحالة إخفاء الشريط السفلي عند السحب
final ValueNotifier<bool> bottomNavHiddenNotifier = ValueNotifier<bool>(false);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
              _openNoteById(noteId);
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
        _processIntent(data);
      }
    } catch (e) {
      // Ignore: Widget intent errors are non-critical
    }
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    if (call.method == 'onIntent' && call.arguments is Map) {
      _processIntent(call.arguments);
    }
  }

  void _processIntent(Map data) async {
    final action = data['action'];
    final noteId = data['note_id'] ?? 0;
    final currentNoteId = data['current_note_id'] ?? 0;
    final widgetType = data['widget_type'] ?? 'note';
    final sharedText = data['shared_text'];

    if (sharedText != null && sharedText.isNotEmpty) {
      _openEditorWithSharedText(sharedText);
    } else if (action ==
        'com.apexflow.app.sinan.ACTION_SELECT_NOTE_FOR_WIDGET') {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => WidgetSelectionScreen(
            widgetType: widgetType,
            currentNoteId: currentNoteId,
          ),
        ),
      );
    } else if (noteId == 0 &&
        action == 'com.apexflow.app.sinan.ACTION_NEW_NOTE') {
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

    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final notesProvider = Provider.of<NotesProvider>(context, listen: false);

    // Wait for SplashScreen to finish and MainLayoutScreen to be active
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;

    // Keep waiting until settings are initialized (SplashScreen is done)
    while (!settings.isInitialized) {
      await Future.delayed(const Duration(milliseconds: 50));
      if (!mounted) return;
    }
    // Extra delay to ensure MainLayoutScreen has replaced SplashScreen
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    final isUrl = Uri.tryParse(text)?.hasScheme ?? false;
    final content = isUrl
        ? text
        : (text.length > kMaxSharedTextLength
            ? text.substring(0, kMaxSharedTextLength)
            : text);

    final mode = isUrl ? NoteMode.simple : _detectNoteMode(content);

    // Create and save note to database FIRST
    final newNote = Note(
      title: isUrl ? 'Shared Link' : '',
      content: content,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      colorIndex: settings.getDefaultColorIndex(_getModeString(mode)),
      noteType: mode.name,
      isProfessional: mode == NoteMode.code,
      isChecklist: mode == NoteMode.checklist,
    );

    // Save to database and get the ID
    final savedNoteId =
        await notesProvider.addOrUpdateNote(newNote, silent: true);

    // Get the saved note from database
    final dbService = IsarDatabaseService();
    final savedNote = await dbService.getNoteById(savedNoteId);
    if (!mounted) return;

    if (savedNote == null) return;

    // Open editor on top of MainLayoutScreen
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => NoteEditorImmersive(
          mode: mode,
          note: savedNote,
        ),
      ),
    );
  }

  NoteMode _detectNoteMode(String text) {
    // Checklist patterns
    final checklistPatterns = [
      RegExp(r'^\s*[-*]\s*\[[ xX]\]', multiLine: true),
      RegExp(r'^\s*\d+\.\s*\[[ xX]\]', multiLine: true),
    ];

    for (final pattern in checklistPatterns) {
      if (pattern.hasMatch(text)) {
        return NoteMode.checklist;
      }
    }

    // Code patterns
    final codePatterns = [
      RegExp(r'(function|const|let|var|class|import|export)\s'),
      RegExp(r'(def|class|import|from|if __name__)\s'),
      RegExp(r'(public|private|void|int|String)\s'),
      RegExp(r'[{};]\s*$', multiLine: true),
    ];

    for (final pattern in codePatterns) {
      if (pattern.hasMatch(text)) {
        return NoteMode.code;
      }
    }

    // Rich text patterns (HTML/Markdown)
    final richPatterns = [
      RegExp(r'<[^>]+>'),
      RegExp(r'\*\*[^*]+\*\*'),
      RegExp(r'__[^_]+__'),
      RegExp(r'^#{1,6}\s', multiLine: true),
    ];

    for (final pattern in richPatterns) {
      if (pattern.hasMatch(text)) {
        return NoteMode.rich;
      }
    }

    return NoteMode.simple;
  }

  String _getModeString(NoteMode mode) {
    switch (mode) {
      case NoteMode.code:
        return 'professional';
      case NoteMode.rich:
        return 'rich';
      case NoteMode.reminder:
        return 'reminder';
      case NoteMode.checklist:
        return 'checklist';
      default:
        return 'simple';
    }
  }

  void _openNoteById(int noteId) async {
    try {
      final dbService = IsarDatabaseService();
      final note = await dbService.getNoteById(noteId);
      if (note != null) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) =>
                NoteViewScreen(note: note, showRestore: false),
          ),
        );
      } else {
        navigatorKey.currentState?.pushNamed('/widget_selection');
      }
    } catch (e) {
      navigatorKey.currentState?.pushNamed('/widget_selection');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // عند العودة من الخلفية — نجدد الجلسة بصمت بدون dialog
      GoogleDriveAuth.refreshSessionIfNeeded();
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
                    systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
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
        if (settings.isFirstLaunch) return CinematicIntroScreen();
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
