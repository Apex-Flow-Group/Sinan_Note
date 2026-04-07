// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GoogleDriveSyncTermsScreen extends StatefulWidget {
  const GoogleDriveSyncTermsScreen({super.key});

  @override
  State<GoogleDriveSyncTermsScreen> createState() => _GoogleDriveSyncTermsScreenState();
}

class _GoogleDriveSyncTermsScreenState extends State<GoogleDriveSyncTermsScreen> {
  bool _agreedToTerms = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(l10n.googleDriveSyncTerms),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Warning icon
                    Center(
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.cloud_sync,
                          size: 50,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Title
                    Text(
                      l10n.syncTermsTitle,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Regular notes info
                    _buildInfoCard(
                      icon: Icons.note,
                      title: l10n.syncTermsRegularNotes,
                      color: Colors.blue,
                      isDark: isDark,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Vault notes info — الخزنة محلية دائماً
                    _buildInfoCard(
                      icon: Icons.lock,
                      title: Localizations.localeOf(context).languageCode == 'ar'
                          ? 'الخزنة المشفرة: محلية بالكامل — لا تُرفع أبداً'
                          : 'Encrypted Vault: fully local — never uploaded',
                      color: Colors.orange,
                      isDark: isDark,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Important notes
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange, width: 2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.syncTermsGoogleAccess,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            l10n.syncTermsRecommendation,
                            style: const TextStyle(fontSize: 14, height: 1.5),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.syncTermsGoogleTOS,
                            style: const TextStyle(fontSize: 14, height: 1.5),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Compression info
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.compress, color: Colors.blue, size: 30),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              l10n.compressionEnabled,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Privacy policy link
                    Center(
                      child: TextButton.icon(
                        onPressed: () async {
                          final isArabic = Localizations.localeOf(context).languageCode == 'ar';
                          final url = isArabic
                              ? 'https://apexflow.now/ar/projects/sinan-note/privacy'
                              : 'https://apexflow.now/en/projects/sinan-note/privacy';
                          await const MethodChannel('com.apexflow.app.sinan/launcher')
                              .invokeMethod('launch', url);
                        },
                        icon: const Icon(Icons.privacy_tip),
                        label: Text(l10n.readPrivacyPolicyLink),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Bottom agreement section
            Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : Colors.grey[100],
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CheckboxListTile(
                    value: _agreedToTerms,
                    onChanged: (val) => setState(() => _agreedToTerms = val ?? false),
                    title: Text(l10n.agreeToTerms),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _agreedToTerms
                          ? () => Navigator.pop(context, {'agreed': true})
                          : null,
                      icon: const Icon(Icons.check_circle),
                      label: Text(
                        l10n.agreeAndEnable,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
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

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 2),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
