// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:io';import 'package:flutter/material.dart';import 'package:provider/provider.dart'; import 'package:sinan_note/generated/l10n/app_localizations.dart'; import 'package:sinan_note/screens/sync/google_drive_sync/google_drive_sync_controller.dart'; import 'package:sinan_note/services/unified_notification_service.dart';
class SyncSignInWidget extends StatefulWidget {
  const SyncSignInWidget({super.key});

  @override
  State<SyncSignInWidget> createState() => _SyncSignInWidgetState();
}

class _SyncSignInWidgetState extends State<SyncSignInWidget> {
  bool _isLoading = false;

  bool get _isUnsupportedPlatform => Platform.isLinux || Platform.isWindows;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _isUnsupportedPlatform
                    ? theme.colorScheme.errorContainer
                    : theme.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isUnsupportedPlatform
                    ? Icons.construction_rounded
                    : Icons.cloud,
                size: 64,
                color: _isUnsupportedPlatform
                    ? theme.colorScheme.error
                    : theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.googleDriveSync,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isUnsupportedPlatform
                  ? 'المزامنة مع Google Drive غير متاحة حالياً على هذا النظام\nقيد التطوير'
                  : l10n.syncTermsRegularNotes,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: _isUnsupportedPlatform
                    ? theme.colorScheme.error
                    : theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (_isUnsupportedPlatform)
              FilledButton.icon(
                onPressed: null,
                icon: const Icon(Icons.lock_clock_rounded),
                label: const Text('قريباً'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              )
            else
              _isLoading
                  ? const CircularProgressIndicator()
                  : FilledButton.icon(
                      onPressed: _handleSignIn,
                      icon: const Icon(Icons.login),
                      label: Text(l10n.signIn),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                    ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSignIn() async {
    setState(() => _isLoading = true);

    final controller = context.read<GoogleDriveSyncController>();
    final success = await controller.signIn();

    if (mounted) {
      setState(() => _isLoading = false);

      if (!success) {
        final l10n = AppLocalizations.of(context)!;
        UnifiedNotificationService().show(
          context: context,
          message: l10n.signInFailed,
          type: NotificationType.error,
        );
      }
    }
  }
}

