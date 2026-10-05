// Copyright © 2025 Apex Flow Group. All rights reserved.


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';
import 'package:sinan_note/ui/core/theme/app_colors.dart';

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
    final scheme = context.scheme;
    final colors = context.colors;

    return Scaffold(
      backgroundColor: scheme.surface,
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
                          color: colors.warning.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.cloud_sync,
                          size: 50,
                          color: colors.warning,
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Title
                    Text(
                      l10n.syncTermsTitle,
                      style: context.text.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 32),

                    // Regular notes info
                    _buildInfoCard(
                      icon: Icons.note,
                      title: l10n.syncTermsRegularNotes,
                      color: colors.info,
                    ),

                    const SizedBox(height: 16),

                    // Vault notes info — الخزنة محلية دائماً
                    _buildInfoCard(
                      icon: Icons.lock,
                      title: l10n.syncTermsVaultLocalOnly,
                      color: colors.vault,
                    ),

                    const SizedBox(height: 24),

                    // Important notes
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colors.warning, width: 2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.syncTermsGoogleAccess,
                            style: context.text.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            l10n.syncTermsRecommendation,
                            style: context.text.bodyMedium?.copyWith(height: 1.5),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.syncTermsGoogleTOS,
                            style: context.text.bodyMedium?.copyWith(height: 1.5),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Compression info
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colors.info.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.compress, color: colors.info, size: 30),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              l10n.compressionEnabled,
                              style: context.text.bodyMedium,
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
                          await const MethodChannel('com.apexflow.app.sinan/launcher')
                              .invokeMethod('launch', l10n.privacyPolicyUrl);
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
                color: scheme.surfaceContainer,
                boxShadow: [
                  BoxShadow(
                    color: colors.shadow,
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
                        style: context.text.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.success,
                        foregroundColor: scheme.surface,
                        disabledBackgroundColor: scheme.surfaceContainerHighest,
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
              style: context.text.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: context.scheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

