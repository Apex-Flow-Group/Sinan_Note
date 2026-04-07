// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:io';

import 'package:apex_note/controllers/notes/notes_provider.dart';
import 'package:apex_note/controllers/settings/settings_provider.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:apex_note/screens/sync/google_drive/google_drive_handlers.dart';
import 'package:apex_note/screens/sync/google_drive/google_drive_widgets.dart';
import 'package:apex_note/screens/sync/google_drive_sync/google_drive_sync_page.dart';
import 'package:apex_note/services/cloud/google_drive_service.dart';
import 'package:apex_note/widgets/home/home_drawer_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GoogleDriveScreen extends StatefulWidget {
  final bool isDesktopLayout;

  const GoogleDriveScreen({super.key, this.isDesktopLayout = false});

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
    if (!mounted) return;
    setState(() {
      _autoSync = prefs.getBool('google_drive_auto_sync') ?? false;
    });
  }

  Future<void> _saveAutoSyncSetting(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('google_drive_auto_sync', value);
    if (!mounted) return;
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
        if (mounted) setState(() => _isLoading = true);
        if (!mounted) return;
        await GoogleDriveService.mergeWithDrive(context);
        await _saveAutoSyncSetting(true);
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.signInSuccess), backgroundColor: Colors.green),
          );
        }
      } else if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.signInFailed), backgroundColor: Colors.red),
        );
      }
    } on MissingPluginException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google Sign In is not supported on ${Platform.operatingSystem}.'),
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
            : widget.isDesktopLayout
                ? _buildDesktopLayout(context, l10n, isDark, isSignedIn,
                    userEmail, lastSyncTimeStr)
                : _buildMobileLayout(context, l10n, isDark, isSignedIn,
                    userEmail, lastSyncTimeStr),
      ),
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    AppLocalizations l10n,
    bool isDark,
    bool isSignedIn,
    String? userEmail,
    String lastSyncTimeStr,
  ) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: [
        // Account Section with New Sync Button
        _buildAccountSectionWithNewSync(context, l10n, isDark, isSignedIn, userEmail),
        const SizedBox(height: 24),
        GoogleDriveWidgets.buildSyncStatusSection(
            context, l10n, isDark, lastSyncTimeStr, isSignedIn, _handleSync),
        const SizedBox(height: 24),
        GoogleDriveWidgets.buildSyncActionsSection(
            context, l10n, isDark, isSignedIn, _handleUpload, _handleDownload),
        const SizedBox(height: 24),
        GoogleDriveWidgets.buildAutoSyncSection(
            context, l10n, isDark, _autoSync, isSignedIn, _saveAutoSyncSetting),
      ],
    );
  }

  Widget _buildAccountSectionWithNewSync(
    BuildContext context,
    AppLocalizations l10n,
    bool isDark,
    bool isSignedIn,
    String? userEmail,
  ) {
    if (isSignedIn) {
      // Show account info with sign out
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_circle,
                    size: 24, color: isDark ? Colors.white70 : Colors.black87),
                const SizedBox(width: 12),
                Text(
                  l10n.account,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.signedInAs,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        userEmail ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _handleSignOut,
                  child: Text(l10n.signOut),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Not signed in - show new sync button
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade400, Colors.purple.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud, color: Colors.white, size: 48),
          const SizedBox(height: 12),
          Text(
            l10n.googleDriveSync,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            Localizations.localeOf(context).languageCode == 'ar'
                ? 'واجهة مبسطة وسهلة'
                : 'Simple & Easy Interface',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final notesProvider = Provider.of<NotesProvider>(context, listen: false);
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (context) => const GoogleDriveSyncPage(),
                ),
              );
              if (result == true && mounted) {
                // ✅ Reload notes from database
                await notesProvider.loadNotes();
                setState(() {});
                if (!mounted) return;
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(l10n.syncSuccess),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            icon: const Icon(Icons.login),
            label: Text(l10n.signIn),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.blue.shade700,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    AppLocalizations l10n,
    bool isDark,
    bool isSignedIn,
    String? userEmail,
    String lastSyncTimeStr,
  ) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: GridView.count(
          crossAxisCount: 2,
          padding: const EdgeInsets.all(24),
          mainAxisSpacing: 24,
          crossAxisSpacing: 24,
          childAspectRatio: 1.5,
          children: [
            GoogleDriveWidgets.buildAccountSection(context, l10n, isDark,
                isSignedIn, userEmail, _handleSignOut, _handleSignIn),
            GoogleDriveWidgets.buildSyncStatusSection(context, l10n, isDark,
                lastSyncTimeStr, isSignedIn, _handleSync),
            GoogleDriveWidgets.buildSyncActionsSection(context, l10n, isDark,
                isSignedIn, _handleUpload, _handleDownload),
            GoogleDriveWidgets.buildAutoSyncSection(context, l10n, isDark,
                _autoSync, isSignedIn, _saveAutoSyncSetting),
          ],
        ),
      ),
    );
  }
}
