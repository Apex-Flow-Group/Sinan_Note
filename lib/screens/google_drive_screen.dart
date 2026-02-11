// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/cloud/google_drive_service.dart';
import '../services/storage/isar_database_service.dart';
import '../controllers/settings/settings_provider.dart';
import '../widgets/home/home_drawer_widget.dart';
import 'google_drive/google_drive_widgets.dart';
import 'google_drive/google_drive_handlers.dart';
import 'google_drive/google_drive_vault_warning_dialog.dart';

class GoogleDriveScreen extends StatefulWidget {
  const GoogleDriveScreen({super.key});

  @override
  State<GoogleDriveScreen> createState() => _GoogleDriveScreenState();
}

class _GoogleDriveScreenState extends State<GoogleDriveScreen> {
  bool _isLoading = false;
  bool _autoSync = false;

  @override
  void initState() {
    super.initState();
    _loadAutoSyncSetting();
    _restoreSignInState();
  }

  Future<void> _restoreSignInState() async {
    await GoogleDriveService.initializeSignIn();
    if (mounted) setState(() {});
  }

  Future<void> _loadAutoSyncSetting() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _autoSync = prefs.getBool('google_drive_auto_sync') ?? false;
    });
  }

  Future<void> _saveAutoSyncSetting(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('google_drive_auto_sync', value);
    setState(() {
      _autoSync = value;
    });
  }


  Future<void> _handleSignOut() async {
    setState(() => _isLoading = true);
    await GoogleDriveHandlers.handleSignOut(context);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _handleSignIn() async {
    try {
      final success = await GoogleDriveService.signIn();
      if (mounted && success) {
        final l10n = AppLocalizations.of(context)!;
        
        // Check if there are locked notes and show warning BEFORE showing loading
        bool shouldContinue = true;
        
        try {
          final dbService = IsarDatabaseService();
          final lockedNotes = await dbService.getLockedNotes();
          
          if (lockedNotes.isNotEmpty) {
            // Show vault warning if needed
            final shouldShowWarning = await GoogleDriveVaultWarningDialog.shouldShow();
            
            if (shouldShowWarning && mounted) {
              final agreed = await showDialog<bool>(
                context: context,
                barrierDismissible: false,
                builder: (ctx) => const GoogleDriveVaultWarningDialog(),
              );
              
              if (agreed != true) {
                shouldContinue = false;
              }
            }
          }
        } catch (e) {
          // Continue even if check fails
        }
        
        if (!shouldContinue) {
          // User cancelled, sign out
          await GoogleDriveService.signOut();
          return;
        }
        
        // Now show loading and start the sync
        if (mounted) setState(() => _isLoading = true);
        
        await GoogleDriveService.mergeWithDrive(
          context,
          uploadMasterKey: false,
          uploadVault: false,
        );
        
        // Enable auto sync
        await _saveAutoSyncSetting(true);
        
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.signInSuccess),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.signInFailed),
            backgroundColor: Colors.red,
          ),
        );
      }
    } on MissingPluginException {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google Sign In is not supported on ${Platform.operatingSystem}. Use Android/iOS/Web.'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.signInFailed}: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSync() async {
    setState(() => _isLoading = true);
    await GoogleDriveHandlers.handleSync(context);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _handleUpload() async {
    final l10n = AppLocalizations.of(context)!;
    
    // عرض dialog لاختيار نوع الرفع
    final result = await showDialog<Map<String, bool>>(
      context: context,
      builder: (context) => _UploadOptionsDialog(),
    );
    
    if (result == null) return; // المستخدم ألغى
    
    setState(() => _isLoading = true);
    await GoogleDriveHandlers.handleUpload(
      context,
      uploadMasterKey: result['uploadMasterKey'] ?? false,
      uploadVault: result['uploadVault'] ?? false,
    );
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _handleDownload() async {
    setState(() => _isLoading = true);
    await GoogleDriveHandlers.handleDownload(context);
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final isDark = settingsProvider.themeMode == ThemeMode.dark || 
        (settingsProvider.themeMode == ThemeMode.system && 
         MediaQuery.of(context).platformBrightness == Brightness.dark);
    final isSignedIn = GoogleDriveService.isSignedIn;
    final userEmail = GoogleDriveService.currentUserEmail;
    final lastSyncTime = GoogleDriveService.lastSyncTime;
    final lastSyncTimeStr = lastSyncTime != null
        ? GoogleDriveHandlers.formatDateTime(context, lastSyncTime)
        : l10n.never;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.googleDriveSync),
          centerTitle: true,
        ),
        drawer: HomeDrawerWidget(
          onBackupTap: () {},
          onNotesChanged: () {},
        ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    l10n.syncing,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              children: [
                GoogleDriveWidgets.buildAccountSection(context, l10n, isDark, isSignedIn, userEmail, _handleSignOut, _handleSignIn),
                const SizedBox(height: 24),
                GoogleDriveWidgets.buildSyncStatusSection(context, l10n, isDark, lastSyncTimeStr, isSignedIn, _handleSync),
                const SizedBox(height: 24),
                GoogleDriveWidgets.buildSyncActionsSection(context, l10n, isDark, isSignedIn, _handleUpload, _handleDownload),
                const SizedBox(height: 24),
                GoogleDriveWidgets.buildAutoSyncSection(context, l10n, isDark, _autoSync, isSignedIn, _saveAutoSyncSetting),
              ],
            ),
      ),
    );
  }


}

class _UploadOptionsDialog extends StatefulWidget {
  @override
  State<_UploadOptionsDialog> createState() => _UploadOptionsDialogState();
}

class _UploadOptionsDialogState extends State<_UploadOptionsDialog> {
  bool _uploadMasterKey = false;
  bool _uploadVault = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      title: Text(l10n.uploadOptions),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.uploadOptionsDesc,
              style: TextStyle(fontSize: 14, color: isDark ? Colors.grey[400] : Colors.grey[700]),
            ),
            const SizedBox(height: 20),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.uploadMasterKey),
              subtitle: Text(l10n.uploadMasterKeyDesc, style: const TextStyle(fontSize: 12)),
              value: _uploadMasterKey,
              onChanged: (val) => setState(() => _uploadMasterKey = val ?? false),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.uploadVault),
              subtitle: Text(l10n.uploadVaultDesc, style: const TextStyle(fontSize: 12)),
              value: _uploadVault,
              onChanged: (val) => setState(() => _uploadVault = val ?? false),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.uploadWarning,
                      style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[300] : Colors.grey[800]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, {
            'uploadMasterKey': _uploadMasterKey,
            'uploadVault': _uploadVault,
          }),
          child: Text(l10n.upload),
        ),
      ],
    );
  }
}
