// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../services/cloud/google_drive_service.dart';
import '../controllers/settings/settings_provider.dart';
import 'google_drive/google_drive_widgets.dart';
import 'google_drive/google_drive_handlers.dart';

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
  }

  Future<void> _loadAutoSyncSetting() async {
    // TODO: Load from SharedPreferences
    setState(() {
      _autoSync = false;
    });
  }

  Future<void> _saveAutoSyncSetting(bool value) async {
    // TODO: Save to SharedPreferences
    setState(() {
      _autoSync = value;
    });
  }


  Future<void> _handleSignOut() async {
    setState(() => _isLoading = true);
    await GoogleDriveHandlers.handleSignOut(context);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _handleSync() async {
    setState(() => _isLoading = true);
    await GoogleDriveHandlers.handleSync(context);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _handleUpload() async {
    setState(() => _isLoading = true);
    await GoogleDriveHandlers.handleUpload(context);
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

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.googleDriveSync),
        centerTitle: true,
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
              padding: const EdgeInsets.all(16),
              children: [
                GoogleDriveWidgets.buildAccountSection(context, l10n, isDark, isSignedIn, userEmail, _handleSignOut),
                const SizedBox(height: 24),
                GoogleDriveWidgets.buildSyncStatusSection(context, l10n, isDark, lastSyncTimeStr, isSignedIn, _handleSync),
                const SizedBox(height: 24),
                GoogleDriveWidgets.buildSyncActionsSection(context, l10n, isDark, isSignedIn, _handleUpload, _handleDownload),
                const SizedBox(height: 24),
                GoogleDriveWidgets.buildAutoSyncSection(context, l10n, isDark, _autoSync, isSignedIn, _saveAutoSyncSetting),
              ],
            ),
    );
  }


}
