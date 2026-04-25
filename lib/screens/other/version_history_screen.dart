// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/controllers/settings/settings_provider.dart';
import 'package:apex_note/core/utils/adaptive_color.dart';
import 'package:apex_note/core/utils/note_content_utils.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:apex_note/models/note.dart';
import 'package:apex_note/models/note_version.dart';
import 'package:apex_note/services/version_history_service.dart';
import 'package:apex_note/widgets/common/searchable_header.dart';
import 'package:apex_note/widgets/editor/versions_bottom_sheet.dart';
import 'package:apex_note/widgets/home/home_drawer_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class VersionHistoryScreen extends StatefulWidget {
  const VersionHistoryScreen({super.key});

  @override
  State<VersionHistoryScreen> createState() => _VersionHistoryScreenState();
}

class _VersionHistoryScreenState extends State<VersionHistoryScreen> {
  final _versionService = VersionHistoryService();
  List<Note> _notesWithHistory = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;
  String _sortBy = 'date';

  @override
  void initState() {
    super.initState();
    _loadNotesWithHistory();
    _searchController.addListener(() =>
        setState(() => _searchQuery = _searchController.text.toLowerCase()));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Note> _filterAndSortNotes() {
    var notes = _notesWithHistory;
    if (_searchQuery.trim().isNotEmpty) {
      notes = notes
          .where((n) =>
              n.title.toLowerCase().contains(_searchQuery) ||
              n.content.toLowerCase().contains(_searchQuery))
          .toList();
    }
    if (_sortBy == 'title') {
      notes.sort((a, b) => a.title.compareTo(b.title));
    } else {
      notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    }
    return notes;
  }

  Future<void> _loadNotesWithHistory() async {
    setState(() => _isLoading = true);
    final notes = await _versionService.getNotesWithHistory();
    setState(() {
      _notesWithHistory = notes.where((n) => !n.isLocked).toList();
      _isLoading = false;
    });
  }

  Future<void> _onRestoreVersion(NoteVersion version, Note note) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.confirmRestore),
        content: Text(l10n.restoreWarning),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel)),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.restore)),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    await _versionService.restoreVersion(note.id!, version);
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(l10n.noteRestored),
      backgroundColor: Colors.green,
    ));
    _loadNotesWithHistory();
  }

  Future<void> _showVersionsDialog(Note note) async {
    final versions = await _versionService.getNoteVersions(note.id!);
    final versionCount = await _versionService.getVersionCount(note.id!);
    if (!mounted) return;

    final isDesktop = MediaQuery.of(context).size.width >= 600;
    if (isDesktop) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: SizedBox(
            width: 560,
            height: 600,
            child: VersionsBottomSheet(
              note: note,
              versions: versions,
              totalVersions: versionCount,
              scrollController: ScrollController(),
              onRestore: (v) => _onRestoreVersion(v, note),
              isDesktop: true,
            ),
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (context) => DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => VersionsBottomSheet(
            note: note,
            versions: versions,
            totalVersions: versionCount,
            scrollController: scrollController,
            onRestore: (v) => _onRestoreVersion(v, note),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    Provider.of<SettingsProvider>(context);
    final filteredNotes = _filterAndSortNotes();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) Navigator.of(context).popUntil((r) => r.isFirst);
      },
      child: Scaffold(
        drawer: HomeDrawerWidget(onBackupTap: () {}, onNotesChanged: () {}),
        body: Column(
          children: [
            Builder(builder: (ctx) {
              return SearchableHeader(
                title: l10n.noteHistory,
                icon: Icons.history_rounded,
                isSearching: _isSearching,
                searchController: _searchController,
                onSearchChange: (q) => setState(() => _searchQuery = q.toLowerCase()),
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
                trailing: PopupMenuButton<String>(
                  icon: const Icon(Icons.sort),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onSelected: (v) => setState(() => _sortBy = v),
                  itemBuilder: (context) => [
                    _sortMenuItem(context, 'date', Icons.access_time, l10n.sortByDate),
                    _sortMenuItem(context, 'title', Icons.sort_by_alpha, l10n.sortByTitle),
                  ],
                ),
              );
            }),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredNotes.isEmpty
                      ? Center(
                          child: Text(
                            _searchQuery.isEmpty ? l10n.noHistoryYet : l10n.noResults,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        )
                      : Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 800),
                            child: ListView.builder(
                              padding: EdgeInsets.only(
                                left: 16,
                                right: 16,
                                top: 16,
                                bottom: MediaQuery.of(context).padding.bottom + 80,
                              ),
                              itemCount: filteredNotes.length,
                              itemBuilder: (context, index) =>
                                  _buildNoteCard(context, filteredNotes[index], l10n),
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _sortMenuItem(
      BuildContext context, String value, IconData icon, String label) {
    final isSelected = _sortBy == value;
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

  String _toPlainText(String content) =>
      NoteContentUtils.toDisplayText(content);

  Widget _buildNoteCard(
      BuildContext context, Note note, AppLocalizations l10n) {
    final displayContent = _toPlainText(note.content);
    final preview = displayContent.length > 100
        ? '${displayContent.substring(0, 100)}...'
        : displayContent;

    final brightness = Theme.of(context).brightness;
    final noteColor =
        AppColorPalette.palette[note.colorIndex].getColor(brightness);
    final isLight = noteColor.computeLuminance() > 0.5;
    final titleColor = isLight ? Colors.black87 : Colors.white;
    final contentColor = isLight ? Colors.grey[700]! : Colors.grey[300]!;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: noteColor,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          note.title.isEmpty ? l10n.untitled : note.title,
          style: TextStyle(fontWeight: FontWeight.bold, color: titleColor),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(preview,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: contentColor)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FutureBuilder<int>(
              future: _versionService.getVersionCount(note.id!),
              builder: (context, snapshot) => snapshot.hasData
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('${snapshot.data}',
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold)),
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.history),
              onPressed: () => _showVersionsDialog(note),
            ),
          ],
        ),
      ),
    );
  }
}
