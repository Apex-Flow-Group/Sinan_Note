// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sinan_note/domain/logger.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';
import 'package:sinan_note/ui/core/theme/app_colors.dart';
import 'package:sinan_note/ui/features/auth/pin_lock_screen.dart';
import 'package:sinan_note/ui/features/auth/view_models/app_lock.dart';
import 'package:sinan_note/ui/features/layout/main_layout_screen.dart';
import 'package:sinan_note/ui/features/notes/view_models/notes_provider.dart';
import 'package:sinan_note/ui/features/onboarding/view_models/app_startup.dart';
import 'package:sinan_note/ui/features/onboarding/whats_new_dialog.dart';
import 'package:sinan_note/ui/features/settings/view_models/settings_provider.dart';
import 'package:sinan_note/ui/features/sync/view_models/sync_view_model.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late final AppLock _lock = context.read<AppLock>();
  late final AppStartup _startup = context.read<AppStartup>();

  String _statusMessage = '';
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startup.trace.mark('first frame');
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
    final l10n = AppLocalizations.of(context)!;

    // ما يسبق الرئيسية: الإعدادات، ثم القفل. كل ما عداه في الخلفية بعدها.
    try {
      _updateStatus(l10n.splashLoadingSettings, 0.5);
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      final sync = context.read<SyncViewModel>();
      await settings.ready;
      _startup.trace.mark('settings');
      if (!mounted) return;

      _updateStatus(l10n.splashSecurityCheck, 0.8);
      AppLogger.debug(
          '[Splash] isAppLockEnabled: ${settings.isAppLockEnabled}');
      if (settings.isAppLockEnabled) {
        AppLogger.debug(
            '[Splash] Calling UnifiedLockService.authenticate()...');
        final lockType = await _lock.getLockType();
        AppLogger.debug('[Splash] LockType: $lockType');

        if (lockType == LockType.pin) {
          // PIN: عرض شاشة PIN وانتظار النتيجة
          if (!mounted) return;
          final hasPinAlready = await _lock.hasPinSet();
          if (!mounted) return;
          final pinCompleter = Completer<bool>();
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PinLockScreen(
                isSetup: !hasPinAlready,
                isAppLock: true,
                autoBiometric: settings.biometricLockEnabled,
                onSuccess: () {
                  Navigator.of(context).pop();
                  pinCompleter.complete(true);
                },
              ),
            ),
          );
          if (!pinCompleter.isCompleted) pinCompleter.complete(false);
          final pinResult = await pinCompleter.future;
          if (!pinResult) {
            AppLogger.debug('[Splash] PIN auth failed — stopping');
            return;
          }
        } else {
          final result = await _lock.authenticate(
            context: 'app_lock',
            biometricEnabled: settings.biometricLockEnabled,
          );
          AppLogger.debug('[Splash] authenticate() returned: $result');
          if (!result) {
            AppLogger.debug('[Splash] User refused authentication — stopping');
            return;
          }
        }
      }
      AppLogger.debug('[Splash] Security check passed');
      _startup.trace.mark('lock');

      if (!mounted) return;

      // Step 5: Load notes (100%)
      _updateStatus(l10n.splashLoadingNotes, 1.0);
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
          settings: const RouteSettings(name: '/main'),
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: Duration.zero,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );

      _startup.trace.mark('home shown');

      // في الخلفية بعد ظهور الرئيسية. جلسة Google لا تُنتظر: حالة الحساب
      // تتحدث حين تكتمل، ثم المزامنة التلقائية إن كانت مفعّلة.
      unawaited(_startup.initServices());
      unawaited(_startup.trace.background('drive session, sync', () async {
        await sync.restoreSession();
        await sync.syncIfEnabled();
      }));
      unawaited(Future.delayed(
        const Duration(seconds: 3),
        _startup.checkForUpdate,
      ));

      // تشويق النسخة النهائية
      if (mounted) _checkAndShowWhatsNew();
    } catch (e) {
      AppLogger.error('Splash initialization error', 'SplashScreen', e);
      _updateStatus(l10n.splashError, 0.0);
    }
  }

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
    final l10n = AppLocalizations.of(context)!;

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
                      color: context.scheme.primary.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.note_alt_outlined,
                      size: 60,
                      color: context.scheme.primary,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // App Name
            Text(
              l10n.appName,
              style: context.text.headlineLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
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
                      backgroundColor: context.scheme.surfaceContainerHighest,
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
                          ? l10n.splashLoading
                          : _statusMessage,
                      key: ValueKey(_statusMessage),
                      style: context.text.bodyMedium
                          ?.copyWith(color: context.colors.muted),
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
