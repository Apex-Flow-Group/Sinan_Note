// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../controllers/settings/settings_provider.dart';
import '../controllers/notes/notes_provider.dart';
import '../services/security/biometric_service.dart';
import '../services/cloud/google_drive_service.dart';
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

    // Initialize Google Sign-In silently
    await GoogleDriveService.initializeSignIn();

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
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.celebration, color: Colors.blue),
            const SizedBox(width: 8),
            Text(isArabic ? 'ما الجديد؟' : 'What\'s New?'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Version Header
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.rocket_launch, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        isArabic ? 'الإصدار 2.2.0' : 'Version 2.2.0',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Feature 1: Google Drive
                _buildFeature(
                  icon: Icons.cloud_done,
                  color: Colors.blue,
                  title: isArabic ? '☁️ مزامنة Google Drive' : '☁️ Google Drive Sync',
                  description: isArabic
                      ? 'تم تفعيل المزامنة مع Google Drive! احفظ ملاحظاتك في السحابة واستعدها على أي جهاز.'
                      : 'Google Drive sync is now active! Save your notes to the cloud and restore them on any device.',
                ),
                
                // Feature 2: Version History
                _buildFeature(
                  icon: Icons.history,
                  color: Colors.orange,
                  title: isArabic ? '📜 سجل التغييرات المحسّن' : '📜 Improved Version History',
                  description: isArabic
                      ? 'نظام سجل التغييرات أصبح أكثر استقراراً وذكاءً. يحفظ فقط التغييرات المهمة ويتجاهل التعديلات الطفيفة.'
                      : 'Version history system is now more stable and smart. Saves only important changes and ignores minor edits.',
                ),
                
                // Feature 3: Better UI
                _buildFeature(
                  icon: Icons.auto_awesome,
                  color: Colors.purple,
                  title: isArabic ? '✨ واجهة محسّنة' : '✨ Enhanced Interface',
                  description: isArabic
                      ? 'تحسينات إضافية على الواجهة والأداء لتجربة أفضل وأسرع.'
                      : 'Additional improvements to interface and performance for better and faster experience.',
                ),
                
                const SizedBox(height: 16),
                
                // Footer
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.favorite, color: Colors.red, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isArabic
                              ? 'شكراً لاستخدامك سنان نوت! نحن نعمل باستمرار لتحسين تجربتك.'
                              : 'Thank you for using Sinan Note! We\'re constantly working to improve your experience.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isArabic ? 'حسناً' : 'Got it'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFeature({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
              ],
            ),
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
