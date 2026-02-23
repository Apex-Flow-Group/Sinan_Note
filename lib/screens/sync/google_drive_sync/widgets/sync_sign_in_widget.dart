// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:io';

import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:apex_note/screens/sync/google_drive_sync/google_drive_sync_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SyncSignInWidget extends StatefulWidget {
  const SyncSignInWidget({super.key});

  @override
  State<SyncSignInWidget> createState() => _SyncSignInWidgetState();
}

class _SyncSignInWidgetState extends State<SyncSignInWidget> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isLinux = Platform.isLinux;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // أيقونة Google Drive
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.cloud,
                size: 64,
                color: theme.colorScheme.primary,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // العنوان
            Text(
              l10n.googleDriveSync,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // الوصف
            Text(
              isLinux
                  ? '🚧 Demo Mode (Linux)'
                  : l10n.syncTermsRegularNotes,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            // زر تسجيل الدخول
            _isLoading
                ? const CircularProgressIndicator()
                : FilledButton.icon(
                    onPressed: _handleSignIn,
                    icon: Icon(isLinux ? Icons.bug_report : Icons.login),
                    label: Text(isLinux ? 'Test Flow' : l10n.signIn),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.signInFailed),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
