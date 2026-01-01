// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/settings_provider.dart';
import '../services/notes_provider.dart';
import '../services/biometric_service.dart';
import 'main_layout_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    await settings.ensureInitialized();

    if (!mounted) return;

    // If lock is enabled, request biometric authentication
    if (settings.isAppLockEnabled) {
      final authenticated = await BiometricService.authenticate();
      if (!authenticated) {
        // User cancelled or failed - exit app
        return;
      }
    }

    if (!mounted) return;

    // Load data AFTER authentication, BEFORE navigation
    final notesProvider = Provider.of<NotesProvider>(context, listen: false);
    await notesProvider.loadNotes();

    if (!mounted) return;

    // Navigate to MainLayoutScreen
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const MainLayoutScreen(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );

    // Show "What's New" dialog after navigation
    if (mounted) {
      _checkAndShowWhatsNew();
    }
  }

  Future<void> _checkAndShowWhatsNew() async {
    final prefs = await SharedPreferences.getInstance();
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = int.tryParse(packageInfo.buildNumber) ?? 0;
    final lastSeenVersion = prefs.getInt('last_seen_version') ?? 0;

    if (currentVersion > lastSeenVersion) {
      await prefs.setInt('last_seen_version', currentVersion);
      if (mounted) {
        _showWhatsNewDialog();
      }
    }
  }

  void _showWhatsNewDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.new_releases, color: Colors.blue),
            SizedBox(width: 8),
            Text('What\'s New'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Version 2.1.1',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 12),
              Text('🔔 Improved Reminders'),
              SizedBox(height: 4),
              Text(
                'Reminders now work reliably in the background. '
                'The app will request necessary permissions to ensure '
                'your reminders trigger on time.',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 12),
              Text('✨ Bug Fixes & Performance'),
              SizedBox(height: 4),
              Text(
                'Various improvements for a smoother experience.',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
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
            const SizedBox(height: 24),
            const Text(
              'Sinan Note',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 48),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ),
      ),
    );
  }
}
