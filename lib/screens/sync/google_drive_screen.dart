// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sinan_note/controllers/categories/categories_provider.dart';
import 'package:sinan_note/controllers/notes/notes_provider.dart';
import 'package:sinan_note/controllers/settings/settings_provider.dart';
import 'package:sinan_note/core/theme/app_theme.dart';
import 'package:sinan_note/core/utils/app_navigator.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';
import 'package:sinan_note/main.dart' show currentTabIndexNotifier;
import 'package:sinan_note/screens/sync/google_drive/google_drive_handlers.dart';
import 'package:sinan_note/screens/sync/google_drive/google_drive_widgets.dart';
import 'package:sinan_note/services/sync/cloud_sync_gateway.dart';
import 'package:sinan_note/services/unified_notification_service.dart';
import 'package:sinan_note/widgets/home/home_drawer_widget.dart';

class GoogleDriveScreen extends StatefulWidget {
  final bool isDesktopLayout;

  const GoogleDriveScreen({super.key, this.isDesktopLayout = false});

  @override
  State<GoogleDriveScreen> createState() => _GoogleDriveScreenState();
}

class _GoogleDriveScreenState extends State<GoogleDriveScreen> {
  bool _isLoading = false;
  bool _autoSync = false;
  bool _pullToRefresh = false;

  @override
  void initState() {
    super.initState();
    _loadAutoSyncSetting();
    _restoreSignInState();
  }

  Future<void> _restoreSignInState() async {
    await CloudSyncGateway.initializeSignIn();
    if (mounted) setState(() {});
  }

  Future<void> _loadAutoSyncSetting() async {
    await CloudSyncGateway.loadAutoSyncState();
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _autoSync = CloudSyncGateway.autoSyncEnabled.value;
      _pullToRefresh = prefs.getBool('google_drive_pull_to_refresh') ?? false;
    });
  }

  Future<void> _saveAutoSyncSetting(bool value) async {
    await CloudSyncGateway.setAutoSync(value);
    if (!mounted) return;
    setState(() => _autoSync = value);
    if (value && CloudSyncGateway.isSignedIn) {
      await _handleSync();
    }
  }

  Future<void> _savePullToRefreshSetting(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('google_drive_pull_to_refresh', value);
    if (!mounted) return;
    setState(() => _pullToRefresh = value);
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
    if (mounted) {
      await _refreshUI();
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleDownload() async {
    setState(() => _isLoading = true);
    await GoogleDriveHandlers.handleDownload(context);
    if (mounted) {
      await _refreshUI();
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleMerge() async {
    setState(() => _isLoading = true);
    await GoogleDriveHandlers.handleMerge(context);
    if (mounted) {
      await _refreshUI();
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshUI() async {
    if (!mounted) return;
    await Provider.of<NotesProvider>(context, listen: false)
        .refreshAllNotes(force: true);
    if (!mounted) return;
    await Provider.of<CategoriesProvider>(context, listen: false)
        .refreshCategories();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final isDark = settingsProvider.themeMode == ThemeMode.dark ||
        (settingsProvider.themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);
    final isSignedIn = CloudSyncGateway.isSignedIn;
    final userEmail = CloudSyncGateway.currentUserEmail;
    final lastSyncTime = CloudSyncGateway.lastSyncTime;
    final lastSyncTimeStr = lastSyncTime != null
        ? GoogleDriveHandlers.formatDateTime(context, lastSyncTime)
        : l10n.never;

    return PopScope(
      canPop: true,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.googleDriveSync),
          centerTitle: true,
        ),
        drawer: HomeDrawerWidget(
          onBackupTap: () {},
          onNotesChanged: () {},
          onTabSelected: (index) {
            Navigator.of(context, rootNavigator: true)
                .popUntil((r) => r.settings.name == '/main' || r.isFirst);
            currentTabIndexNotifier.value = index;
          },
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

  Future<void> _handleRefresh() async {
    await _restoreSignInState();
    if (mounted && CloudSyncGateway.isSignedIn) {
      setState(() => _isLoading = true);
      await GoogleDriveHandlers.handleSync(context);
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildMobileLayout(
    BuildContext context,
    AppLocalizations l10n,
    bool isDark,
    bool isSignedIn,
    String? userEmail,
    String lastSyncTimeStr,
  ) {
    return RefreshIndicator(
      onRefresh: _pullToRefresh ? _handleRefresh : () async {},
      semanticsLabel: l10n.pullToRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
        children: [
          // Account Section with New Sync Button
          _buildAccountSectionWithNewSync(
              context, l10n, isDark, isSignedIn, userEmail),
          const SizedBox(height: 24),
          GoogleDriveWidgets.buildSyncStatusSection(
              context, l10n, isDark, lastSyncTimeStr, isSignedIn, _handleSync),
          const SizedBox(height: 24),
          GoogleDriveWidgets.buildSyncActionsSection(context, l10n, isDark,
              isSignedIn, _handleUpload, _handleDownload, _handleMerge),
          const SizedBox(height: 24),
          GoogleDriveWidgets.buildAutoSyncSection(context, l10n, isDark,
              _autoSync, isSignedIn, _saveAutoSyncSetting,
              pullToRefresh: _pullToRefresh,
              onPullToRefreshChanged: _savePullToRefreshSetting),
        ],
      ),
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
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade600, Colors.blue.shade900],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.cloud_done, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.account,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                              color: Color(0xFF69F0AE),
                              shape: BoxShape.circle)),
                      const SizedBox(width: 5),
                      const Text('Connected',
                          style:
                              TextStyle(fontSize: 11, color: Colors.white70)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.email_outlined,
                    color: Colors.white70, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    userEmail ?? '',
                    style: const TextStyle(fontSize: 13, color: Colors.white70),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: _handleSignOut,
                  child: Text(l10n.signOut,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 13)),
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
              final notesProvider =
                  Provider.of<NotesProvider>(context, listen: false);
              final categoriesProvider =
                  Provider.of<CategoriesProvider>(context, listen: false);
              final syncSuccessMsg = l10n.syncSuccess;
              final result = await AppNavigator.toGoogleDriveSync(context);
              if (result == true && mounted) {
                await notesProvider.refreshAllNotes(force: true);
                if (!mounted) return;
                await categoriesProvider.refreshCategories();
                if (!mounted) return;
                setState(() {});
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  UnifiedNotificationService().show(
                    context: context,
                    message: syncSuccessMsg,
                    type: NotificationType.success,
                  );
                });
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
    final colorScheme = Theme.of(context).colorScheme;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    final sections = [
      (
        icon: Icons.account_circle_outlined,
        label: isAr ? 'الحساب والمزامنة' : 'Account & Sync'
      ),
      (icon: Icons.settings_outlined, label: isAr ? 'الإعدادات' : 'Settings'),
    ];

    return _GoogleDriveDesktopMasterDetails(
      sections: sections,
      colorScheme: colorScheme,
      buildContent: (index) => switch (index) {
        0 => ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _buildAccountSectionWithNewSync(
                  context, l10n, isDark, isSignedIn, userEmail),
              const SizedBox(height: 24),
              GoogleDriveWidgets.buildSyncStatusSection(context, l10n, isDark,
                  lastSyncTimeStr, isSignedIn, _handleSync),
              const SizedBox(height: 24),
              GoogleDriveWidgets.buildSyncActionsSection(context, l10n, isDark,
                  isSignedIn, _handleUpload, _handleDownload, _handleMerge),
            ],
          ),
        1 => ListView(
            padding: const EdgeInsets.all(24),
            children: [
              GoogleDriveWidgets.buildAutoSyncSection(context, l10n, isDark,
                  _autoSync, isSignedIn, _saveAutoSyncSetting,
                  pullToRefresh: _pullToRefresh,
                  onPullToRefreshChanged: _savePullToRefreshSetting),
            ],
          ),
        _ => const SizedBox(),
      },
    );
  }
}

class _GoogleDriveDesktopMasterDetails extends StatefulWidget {
  final List<({IconData icon, String label})> sections;
  final ColorScheme colorScheme;
  final Widget Function(int index) buildContent;

  const _GoogleDriveDesktopMasterDetails({
    required this.sections,
    required this.colorScheme,
    required this.buildContent,
  });

  @override
  State<_GoogleDriveDesktopMasterDetails> createState() =>
      _GoogleDriveDesktopMasterDetailsState();
}

class _GoogleDriveDesktopMasterDetailsState
    extends State<_GoogleDriveDesktopMasterDetails> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = widget.colorScheme;

    return SafeArea(
      top: false, // AppBar يتعامل مع الأعلى
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Master — قائمة الأقسام (نفس شكل الإعدادات)
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 220,
                color: AppTheme.sidebarBackground(colorScheme),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  itemCount: widget.sections.length,
                  itemBuilder: (_, i) {
                    final selected = i == _selectedIndex;
                    return ListTile(
                      leading: Icon(
                        widget.sections[i].icon,
                        color: selected ? colorScheme.primary : null,
                      ),
                      title: Text(
                        widget.sections[i].label,
                        style: TextStyle(
                          color: selected ? colorScheme.primary : null,
                          fontWeight: selected ? FontWeight.w600 : null,
                        ),
                      ),
                      selected: selected,
                      selectedTileColor:
                          colorScheme.primaryContainer.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      onTap: () => setState(() => _selectedIndex = i),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Details — محتوى القسم
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: KeyedSubtree(
                  key: ValueKey(_selectedIndex),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: widget.buildContent(_selectedIndex),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
