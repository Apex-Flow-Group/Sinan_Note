// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sinan_note/controllers/settings/settings_provider.dart';
import 'package:sinan_note/core/utils/app_navigator.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';
import 'package:sinan_note/screens/sync/google_drive/google_drive_handlers.dart';
import 'package:sinan_note/screens/sync/google_drive/google_drive_widgets.dart';
import 'package:sinan_note/ui/core/navigation/app_navigation.dart';
import 'package:sinan_note/ui/core/theme/app_colors.dart';
import 'package:sinan_note/ui/core/theme/app_theme.dart';
import 'package:sinan_note/ui/features/sync/view_models/sync_view_model.dart';
import 'package:sinan_note/widgets/common/unified_notification_service.dart';
import 'package:sinan_note/widgets/home/home_drawer_widget.dart';

class GoogleDriveScreen extends StatefulWidget {
  final bool isDesktopLayout;

  const GoogleDriveScreen({super.key, this.isDesktopLayout = false});

  @override
  State<GoogleDriveScreen> createState() => _GoogleDriveScreenState();
}

class _GoogleDriveScreenState extends State<GoogleDriveScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    context.read<SyncViewModel>().restoreSession();
  }

  Future<void> _saveAutoSyncSetting(bool value) async {
    final sync = context.read<SyncViewModel>();
    await sync.setAutoSync(value);
    if (value && sync.isSignedIn && mounted) await _handleSync();
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

  Future<void> _handleMerge() async {
    setState(() => _isLoading = true);
    await GoogleDriveHandlers.handleMerge(context);
    if (mounted) setState(() => _isLoading = false);
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
    final sync = context.watch<SyncViewModel>();
    final isSignedIn = sync.isSignedIn;
    final userEmail = sync.accountEmail;
    final lastSyncTime = sync.lastSyncedAt?.toLocal();
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
            context.read<AppNavigation>().tab.value = index;
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

  Widget _buildMobileLayout(
    BuildContext context,
    AppLocalizations l10n,
    bool isDark,
    bool isSignedIn,
    String? userEmail,
    String lastSyncTimeStr,
  ) {
    return ListView(
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
          GoogleDriveWidgets.buildAutoSyncSection(
              context, l10n, isDark, context.read<SyncViewModel>().autoSync, isSignedIn,
              _saveAutoSyncSetting),
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
    final scheme = context.scheme;
    final onCard = scheme.onPrimary;
    final onCardDim = onCard.withValues(alpha: 0.7);

    if (isSignedIn) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [scheme.primary, scheme.onPrimaryContainer],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.cloud_done, color: onCard, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.account,
                    style: context.text.titleLarge?.copyWith(
                      color: onCard,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: onCard.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                              color: context.colors.success,
                              shape: BoxShape.circle)),
                      const SizedBox(width: 5),
                      Text(l10n.driveConnected,
                          style: context.text.labelSmall
                              ?.copyWith(color: onCardDim)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.email_outlined, color: onCardDim, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    userEmail ?? '',
                    style: context.text.bodySmall?.copyWith(color: onCardDim),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: _handleSignOut,
                  child: Text(l10n.signOut,
                      style:
                          context.text.bodySmall?.copyWith(color: onCardDim)),
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
          colors: [scheme.primary, scheme.tertiary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.cloud, color: onCard, size: 48),
          const SizedBox(height: 12),
          Text(
            l10n.googleDriveSync,
            style: context.text.headlineSmall?.copyWith(
              color: onCard,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.simpleEasyInterface,
            style: context.text.bodyMedium?.copyWith(color: onCardDim),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () async {
              final syncSuccessMsg = l10n.syncSuccess;
              final result = await AppNavigator.toGoogleDriveSync(context);
              if (result == true && mounted) {
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
              backgroundColor: onCard,
              foregroundColor: scheme.primary,
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
    final sections = [
      (icon: Icons.account_circle_outlined, label: l10n.accountAndSync),
      (icon: Icons.settings_outlined, label: l10n.settings),
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
                  context.read<SyncViewModel>().autoSync, isSignedIn,
              _saveAutoSyncSetting),
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
