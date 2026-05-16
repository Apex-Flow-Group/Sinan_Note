// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/controllers/notes/notes_provider.dart';
import 'package:apex_note/controllers/settings/settings_provider.dart';
import 'package:apex_note/core/utils/adaptive_color.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:apex_note/models/note.dart';
import 'package:apex_note/models/note_version.dart';
import 'package:apex_note/screens/mobile/home_screen.dart' show ViewType;
import 'package:apex_note/screens/other/version_history/panels/diff_panel.dart';
import 'package:apex_note/screens/other/version_history/panels/notes_panel.dart';
import 'package:apex_note/screens/other/version_history/panels/versions_panel.dart';
import 'package:apex_note/screens/other/version_history/version_history_controller.dart';
import 'package:apex_note/screens/other/version_history/widgets/resizable_divider.dart';
import 'package:apex_note/services/unified_notification_service.dart';
import 'package:apex_note/widgets/common/searchable_header.dart';
import 'package:apex_note/widgets/home/home_drawer_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kPrefNotesWidth = 'vh_notes_col_width';
const String _kPrefVersionsWidth = 'vh_versions_col_width';

class VersionHistoryScreen extends StatefulWidget {
  const VersionHistoryScreen({super.key});

  @override
  State<VersionHistoryScreen> createState() => _VersionHistoryScreenState();
}

class _VersionHistoryScreenState extends State<VersionHistoryScreen> {
  final _ctrl = VersionHistoryController();
  final _searchController = TextEditingController();
  final _pageController = PageController();

  ViewType _viewType = ViewType.listExpanded;
  bool _isSearching = false;

  double _notesColWidth = kColDefaultNotes;
  double _versionsColWidth = kColDefaultVersions;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() {
      if (mounted) setState(() {});
    });
    _ctrl.loadNotes();
    _loadColWidths();
    _searchController.addListener(() {
      _ctrl.searchQuery = _searchController.text;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _searchController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadColWidths() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notesColWidth = (prefs.getDouble(_kPrefNotesWidth) ?? kColDefaultNotes)
          .clamp(kColMin, kColMax);
      _versionsColWidth =
          (prefs.getDouble(_kPrefVersionsWidth) ?? kColDefaultVersions)
              .clamp(kColMin, kColMax);
    });
  }

  Future<void> _saveColWidths() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kPrefNotesWidth, _notesColWidth);
    await prefs.setDouble(_kPrefVersionsWidth, _versionsColWidth);
  }

  void _animateToPage(int page) {
    _pageController.animateToPage(page,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic);
  }

  Future<void> _onRestoreVersion(NoteVersion version, Note note) async {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? scheme.surfaceContainerLow : scheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(
          24,
          16,
          24,
          24 + MediaQuery.of(ctx).padding.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.restore_rounded,
                  color: Colors.orange, size: 32),
            ),
            const SizedBox(height: 16),
            // Title
            Text(
              l10n.confirmRestore,
              style: Theme.of(ctx)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            // Version info
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.history_rounded,
                      size: 16, color: Colors.orange),
                  const SizedBox(width: 6),
                  Text(
                    version.title.isEmpty ? l10n.untitled : version.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Warning text
            Text(
              l10n.restoreWarning,
              style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(l10n.cancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => Navigator.pop(ctx, true),
                    icon: const Icon(Icons.restore_rounded, size: 18),
                    label: Text(l10n.restore),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (!mounted || confirmed != true) return;
    await _ctrl.restoreVersion(
      version,
      note,
      Provider.of<NotesProvider>(context, listen: false),
    );
    if (!mounted) return;
    UnifiedNotificationService().show(
      context: context,
      message: l10n.noteRestored,
      type: NotificationType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    Provider.of<SettingsProvider>(context);
    final isWide = MediaQuery.of(context).size.width >= 700;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final wide = MediaQuery.of(context).size.width >= 700;
        if (_ctrl.selectedVersion != null) {
          _ctrl.clearVersion();
          if (!wide) _animateToPage(1);
        } else if (_ctrl.selectedNote != null && !wide) {
          _ctrl.clearNote();
          _animateToPage(0);
        } else {
          Navigator.of(context).popUntil((r) => r.isFirst);
        }
      },
      child: Scaffold(
        drawer: HomeDrawerWidget(onBackupTap: () {}, onNotesChanged: () {}),
        body: Column(
          children: [
            Builder(
                builder: (ctx) => SearchableHeader(
                      title: l10n.noteHistory,
                      icon: Icons.history_rounded,
                      isSearching: _isSearching,
                      searchController: _searchController,
                      onSearchChange: (q) =>
                          setState(() => _ctrl.searchQuery = q),
                      onToggleSearch: () => setState(() {
                        _isSearching = !_isSearching;
                        if (!_isSearching) _searchController.clear();
                      }),
                      leading: Builder(
                        builder: (ctx) => IconButton(
                          icon: const Icon(Icons.menu),
                          onPressed: () => Scaffold.of(ctx).openDrawer(),
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                                _viewType == ViewType.listExpanded
                                    ? Icons.view_headline
                                    : Icons.view_agenda_outlined,
                                size: 22),
                            onPressed: () => setState(() {
                              _viewType = _viewType == ViewType.listExpanded
                                  ? ViewType.listCompact
                                  : ViewType.listExpanded;
                            }),
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.sort),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            onSelected: (v) => setState(() => _ctrl.sortBy = v),
                            itemBuilder: (_) => [
                              _sortMenuItem(context, 'date', Icons.access_time,
                                  l10n.sortByDate),
                              _sortMenuItem(context, 'title',
                                  Icons.sort_by_alpha, l10n.sortByTitle),
                            ],
                          ),
                        ],
                      ),
                    )),
            Expanded(
              child: _ctrl.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : isWide
                      ? _buildWideLayout(context)
                      : _buildNarrowLayout(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWideLayout(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final panelColor = isDark
        ? Theme.of(context).colorScheme.surfaceContainerLow
        : Theme.of(context).colorScheme.surfaceContainerLowest;
    final diffPanelColor = _ctrl.selectedNote != null
        ? AppColorPalette.palette[_ctrl.selectedNote!.colorIndex]
            .getColor(Theme.of(context).brightness)
        : panelColor;

    BoxDecoration panelDeco(Color color) => BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            )
          ],
        );

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: _notesColWidth,
              decoration: panelDeco(panelColor),
              child: _buildNotesPanel(isWide: true),
            ),
          ),
          ResizableDivider(
            onDrag: (dx) => setState(() =>
                _notesColWidth = (_notesColWidth + dx).clamp(kColMin, kColMax)),
            onDragEnd: _saveColWidths,
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            child: _ctrl.selectedNote != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: _versionsColWidth,
                      decoration: panelDeco(panelColor),
                      child: _buildVersionsPanel(isWide: true),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          if (_ctrl.selectedNote != null)
            ResizableDivider(
              onDrag: (dx) => setState(() => _versionsColWidth =
                  (_versionsColWidth + dx).clamp(kColMin, kColMax)),
              onDragEnd: _saveColWidths,
            ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: ClipRRect(
                key: ValueKey(_ctrl.selectedVersion != null
                    ? 'diff_${_ctrl.selectedVersion?.id}'
                    : 'hint_${_ctrl.selectedNote != null}'),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: panelDeco(_ctrl.selectedVersion != null
                      ? diffPanelColor
                      : panelColor),
                  child: _ctrl.selectedVersion != null
                      ? _buildDiffPanel(isWide: true)
                      : _buildEmptyHint(
                          context,
                          _ctrl.selectedNote != null
                              ? Icons.compare_arrows_outlined
                              : Icons.touch_app_outlined,
                          _ctrl.selectedNote != null
                              ? AppLocalizations.of(context)!
                                  .selectVersionToViewDiff
                              : AppLocalizations.of(context)!
                                  .selectNoteToViewHistory),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNarrowLayout(BuildContext context) {
    return PageView(
      controller: _pageController,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildNotesPanel(isWide: false),
        _ctrl.selectedNote != null
            ? _buildVersionsPanel(isWide: false)
            : const SizedBox.shrink(),
        _ctrl.selectedNote != null && _ctrl.selectedVersion != null
            ? _buildDiffPanel(isWide: false)
            : const SizedBox.shrink(),
      ],
    );
  }

  Widget _buildNotesPanel({required bool isWide}) => NotesPanel(
        notes: _ctrl.filteredNotes,
        selectedNote: _ctrl.selectedNote,
        viewType: _viewType,
        searchQuery: _ctrl.searchQuery,
        getVersionCount: _ctrl.getVersionCount,
        onSelectNote: (note) async {
          await _ctrl.selectNote(note);
          if (!isWide) _animateToPage(1);
        },
      );

  Widget _buildVersionsPanel({required bool isWide}) => VersionsPanel(
        selectedNote: _ctrl.selectedNote!,
        versions: _ctrl.selectedNoteVersions,
        loading: _ctrl.loadingVersions,
        selectedVersion: _ctrl.selectedVersion,
        isWide: isWide,
        onSelectVersion: (v) {
          _ctrl.selectVersion(v);
          if (!isWide) _animateToPage(2);
        },
        onBack: () {
          _ctrl.clearNote();
          _animateToPage(0);
        },
      );

  Widget _buildDiffPanel({required bool isWide}) => DiffPanel(
        version: _ctrl.selectedVersion!,
        note: _ctrl.selectedNote!,
        allVersions: _ctrl.selectedNoteVersions,
        isWide: isWide,
        onRestore: _onRestoreVersion,
        onBack: () {
          _ctrl.clearVersion();
          _animateToPage(1);
        },
      );

  Widget _buildEmptyHint(BuildContext context, IconData icon, String message) =>
      Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[500], fontSize: 15)),
          ],
        ),
      );

  PopupMenuItem<String> _sortMenuItem(
      BuildContext context, String value, IconData icon, String label) {
    final isSelected = _ctrl.sortBy == value;
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon,
              size: 20,
              color: isSelected ? Theme.of(context).colorScheme.primary : null),
          const SizedBox(width: 12),
          Text(label),
          if (isSelected) ...[
            const Spacer(),
            Icon(Icons.check,
                size: 20, color: Theme.of(context).colorScheme.primary),
          ],
        ],
      ),
    );
  }
}
