// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:async';
import 'dart:io';

import 'package:apex_note/controllers/notes/notes_provider.dart';
import 'package:apex_note/controllers/settings/settings_provider.dart';
import 'package:apex_note/core/utils/logger.dart';
import 'package:apex_note/main.dart' show navigatorKey;
import 'package:apex_note/screens/onboarding/whats_new_dialog.dart';
import 'package:apex_note/screens/shared/main_layout_screen.dart';
import 'package:apex_note/services/cloud/google_drive_service.dart';
import 'package:apex_note/services/diagnostics/apex_diagnostics_engine.dart';
import 'package:apex_note/services/diagnostics/apex_error_manager.dart';
import 'package:apex_note/services/notification_service.dart';
import 'package:apex_note/services/security/biometric_service.dart';
import 'package:apex_note/services/storage/isar_database_service.dart';
import 'package:apex_note/services/storage/native_db_migration_service.dart';
import 'package:apex_note/services/widget_service.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _statusMessage = '';
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    // Set navigator key immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ApexErrorManager.setNavigatorKey(navigatorKey);
      _initApp();
    });
  }

  void _updateStatus(String message, double progress) {
    if (mounted) {
      setState(() {
        _statusMessage = message;
        _progress = progress;
      });
    }
  }

  Future<void> _initApp() async {
    if (!mounted) return;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    try {
      // Step 1: Initialize Isar Database (20%)
      _updateStatus(
          isArabic ? 'تهيئة قاعدة البيانات...' : 'Initializing database...',
          0.2);
      await IsarDatabaseService.initialize();

      // Step 2: Migration to Native SQLite — مرة واحدة فقط (50%)
      _updateStatus(
          isArabic ? 'ترحيل البيانات...' : 'Migrating data...',
          0.5);
      await NativeDbMigrationService.runIfNeeded();

      // Step 2: Background services (60%)
      _updateStatus(isArabic ? 'تحميل الخدمات...' : 'Loading services...', 0.6);
      await _initBackgroundServices();

      // Step 3: Wait for settings (80%)
      _updateStatus(
          isArabic ? 'تحميل الإعدادات...' : 'Loading settings...', 0.8);
      if (!mounted) return;
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      while (!settings.isInitialized) {
        await Future.delayed(const Duration(milliseconds: 50));
        if (!mounted) return;
      }

      // Initialize Google Sign-In + smart sync in background
      await GoogleDriveService.initializeSignIn();
      if (GoogleDriveService.isSignedIn) {
        unawaited(GoogleDriveService.smartSyncOnStartup().then((_) async {
          if (!mounted) return;
          await Provider.of<NotesProvider>(context, listen: false).loadNotes();
        }));
      }

      if (!mounted) return;

      // Step 4: Authentication check (90%)
      _updateStatus(
          isArabic ? 'التحقق من الأمان...' : 'Security check...', 0.9);
      if (settings.isAppLockEnabled) {
        final authenticated = await BiometricService.authenticate();
        if (!authenticated) return;
      }

      if (!mounted) return;

      // Step 5: Load notes (100%)
      _updateStatus(isArabic ? 'تحميل الملاحظات...' : 'Loading notes...', 1.0);
      final notesProvider = Provider.of<NotesProvider>(context, listen: false);
      // ✅ Load notes in background (non-blocking)
      notesProvider.loadNotes();

      // Navigate immediately without waiting
      if (!mounted) return;

      // Navigate
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const MainLayoutScreen(),
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: Duration.zero,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );

      // TODO: أعد تفعيل هذا السطر في الإصدار القادم الذي يتضمن تغييرات في قاعدة البيانات
      // if (mounted) _checkAndShowWhatsNew(); // معطّل مؤقتاً
    } catch (e) {
      AppLogger.error('Splash initialization error', 'SplashScreen', e);
      _updateStatus(isArabic ? 'حدث خطأ...' : 'Error occurred...', 0.0);
    }
  }

  Future<void> _initBackgroundServices() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      ApexDiagnosticsEngine().init(appDir.path);

      if (Platform.isAndroid || Platform.isIOS) {
        await NotificationService().initialize();
        if (Platform.isAndroid) {
          await WidgetService().initialize();
        }
      }
    } catch (e) {
      AppLogger.error('Background services init error', 'SplashScreen', e);
    }
  }

  // ignore: unused_element
  Future<void> _checkAndShowWhatsNew() async {
    final prefs = await SharedPreferences.getInstance();
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = int.tryParse(packageInfo.buildNumber) ?? 0;
    final lastSeenVersion = prefs.getInt('last_seen_version') ?? 0;

    if (currentVersion > lastSeenVersion) {
      await prefs.setInt('last_seen_version', currentVersion);
      if (!mounted) return;
      _showWhatsNewDialog();
    }
  }

  void _showWhatsNewDialog() {
    WhatsNewDialog.show(context);
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Icon with animation
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.note_alt_outlined,
                      size: 60,
                      color: Colors.blue,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // App Name
            const Text(
              'Sinan Note',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 48),

            // Progress Bar
            SizedBox(
              width: 200,
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: _progress,
                      minHeight: 6,
                      backgroundColor: Colors.grey.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Status Message
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      _statusMessage.isEmpty
                          ? (isArabic ? 'جاري التحميل...' : 'Loading...')
                          : _statusMessage,
                      key: ValueKey(_statusMessage),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
