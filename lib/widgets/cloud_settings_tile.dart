// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import '../services/google_drive_service.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'apex_snackbar.dart';

class CloudSettingsTile extends StatefulWidget {
  const CloudSettingsTile({super.key});

  @override
  State<CloudSettingsTile> createState() => _CloudSettingsTileState();
}

class _CloudSettingsTileState extends State<CloudSettingsTile> {
  final GoogleDriveService _driveService = GoogleDriveService();
  bool _isLoading = false;
  DateTime? _lastSync;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.cloud, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Google Drive',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      if (_driveService.isSignedIn)
                        Text(
                          _driveService.userEmail ?? '',
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                    ],
                  ),
                ),
                if (_driveService.isSignedIn)
                  IconButton(
                    icon: const Icon(Icons.logout),
                    onPressed: _signOut,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (!_driveService.isSignedIn)
              ElevatedButton.icon(
                icon: const Icon(Icons.login),
                label: Text(l10n.signIn),
                onPressed: _signIn,
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48)),
              )
            else ...[
              ElevatedButton.icon(
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.sync),
                label: Text(l10n.syncNow),
                onPressed: _isLoading ? null : _syncNow,
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48)),
              ),
              if (_lastSync != null) ...[
                const SizedBox(height: 8),
                Text(
                  'آخر مزامنة: ${_formatTime(_lastSync!)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _signIn() async {
    final l10n = AppLocalizations.of(context)!;

    setState(() => _isLoading = true);
    try {
      final success = await _driveService.signIn();
      if (success) {
        ApexSnackBar.show(
          context,
          l10n.signInSuccess,
          type: SnackBarType.success,
        );
      }
    } catch (e) {
      ApexSnackBar.show(
        context,
        '${l10n.signInFailed} $e',
        type: SnackBarType.error,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    await _driveService.signOut();
    setState(() => _lastSync = null);
  }

  Future<void> _syncNow() async {
    final l10n = AppLocalizations.of(context)!;

    setState(() => _isLoading = true);
    try {
      await _driveService.uploadDatabase();
      setState(() => _lastSync = DateTime.now());
      ApexSnackBar.show(
        context,
        l10n.syncSuccess,
        type: SnackBarType.success,
      );
    } catch (e) {
      ApexSnackBar.show(
        context,
        '${l10n.syncFailed} $e',
        type: SnackBarType.error,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    return 'منذ ${diff.inDays} يوم';
  }
}
