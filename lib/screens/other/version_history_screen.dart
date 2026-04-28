// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/controllers/settings/settings_provider.dart';
import 'package:apex_note/core/utils/adaptive_color.dart';
import 'package:apex_note/core/utils/note_content_utils.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:apex_note/models/note.dart';
import 'package:apex_note/models/note_version.dart';
import 'package:apex_note/services/version_history_service.dart';
import 'package:apex_note/widgets/common/searchable_header.dart';
import 'package:apex_note/widgets/editor/diff_view.dart';
import 'package:apex_note/widgets/home/home_drawer_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Column width constraints ──────────────────────────────────────────────
const double _kColMin = 160.0;
const double _kColMax = 420.0;
const double _kColDefaultNotes = 220.0;
const double _kColDefaultVersions = 200.0;
const String _kPrefNotesWidth = 'vh_notes_col_width';
const String _kPrefVersionsWidth = 'vh_versions_col_width';

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

  Note? _selectedNote;
  List<NoteVersion> _selectedNoteVersions = [];
  bool _loadingVersions = false;
  NoteVersion? _selectedVersion;

  // Resizable column widths (wide layout only)
  double _notesColWidth = _kColDefaultNotes;
  double _versionsColWidth = _kColDefaultVersions;

  @override
  void initState() {
    super.initState();
    _loadNotesWithHistory();
    _loadColWidths();
    _searchController.addListener(() =>
        setState(() => _searchQuery = _searchController.text.toLowerCase()));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadColWidths() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notesColWidth = (prefs.getDouble(_kPrefNotesWidth) ?? _kColDefaultNotes)
          .clamp(_kColMin, _kColMax);
      _versionsColWidth =
          (prefs.getDouble(_kPrefVersionsWidth) ?? _kColDefaultVersions)
              .clamp(_kColMin, _kColMax);
    });
  }

  Future<void> _saveColWidths() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kPrefNotesWidth, _notesColWidth);
    await prefs.setDouble(_kPrefVersionsWidth, _versionsColWidth);
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

  Future<void> _selectNote(Note note) async {
    setState(() {
      _selectedNote = note;
      _selectedVersion = null;
      _selectedNoteVersions = [];
      _loadingVersions = true;
    });
    final versions = await _versionService.getNoteVersions(note.id!);
    setState(() {
      _selectedNoteVersions = versions;
      _loadingVersions = false;
    });
  }

  void _selectVersion(NoteVersion version) =>
      setState(() => _selectedVersion = version);

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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(l10n.noteRestored),
      backgroundColor: Colors.green,
    ));
    _loadNotesWithHistory();
  }

  String _toPlainText(String c) => NoteContentUtils.toDisplayText(c);

  String _formatTimeAgo(BuildContext context, DateTime dt) {
    final diff = DateTime.now().difference(dt);
    final l10n = AppLocalizations.of(context)!;
    if (diff.inMinutes < 1) return l10n.justNow;
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  IconData _getActionIcon(String a) {
    switch (a) {
      case 'manual_save':
        return Icons.save;
      case 'auto_save':
        return Icons.update;
      case 'created':
        return Icons.add_circle;
      case 'archived':
        return Icons.archive;
      case 'restored':
        return Icons.restore;
      default:
        return Icons.edit;
    }
  }

  Color _getActionColor(String a) {
    switch (a) {
      case 'manual_save':
        return Colors.green;
      case 'auto_save':
        return Colors.blue;
      case 'created':
        return Colors.purple;
      case 'archived':
        return Colors.orange;
      case 'restored':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    Provider.of<SettingsProvider>(context);
    final filteredNotes = _filterAndSortNotes();
    final isWide = MediaQuery.of(context).size.width >= 700;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          if (_selectedVersion != null) {
            setState(() => _selectedVersion = null);
          } else if (_selectedNote != null && !isWide) {
            setState(() {
              _selectedNote = null;
              _selectedNoteVersions = [];
            });
          } else {
            Navigator.of(context).popUntil((r) => r.isFirst);
          }
        }
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
                onSearchChange: (q) =>
                    setState(() => _searchQuery = q.toLowerCase()),
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
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  onSelected: (v) => setState(() => _sortBy = v),
                  itemBuilder: (_) => [
                    _sortMenuItem(
                        context, 'date', Icons.access_time, l10n.sortByDate),
                    _sortMenuItem(context, 'title', Icons.sort_by_alpha,
                        l10n.sortByTitle),
                  ],
                ),
              );
            }),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : isWide
                      ? _buildWideLayout(context, filteredNotes, l10n)
                      : _buildNarrowLayout(context, filteredNotes, l10n),
            ),
          ],
        ),
      ),
    );
  }

  // ── Wide: progressive columns with resizable dividers ────────────────────
  Widget _buildWideLayout(
      BuildContext context, List<Note> notes, AppLocalizations l10n) {
    final showVersions = _selectedNote != null;
    final showDiff = _selectedVersion != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // نفس ألوان MasterDetailsLayout
    final panelColor = isDark
        ? Theme.of(context).colorScheme.surfaceContainerLow
        : Theme.of(context).colorScheme.surfaceContainerLowest;

    // لون الـ diff panel يعكس لون النوتة المختارة
    final Color diffPanelColor = _selectedNote != null
        ? AppColorPalette.palette[_selectedNote!.colorIndex]
            .getColor(Theme.of(context).brightness)
        : panelColor;

    BoxDecoration panelDecoration(Color color) => BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        );

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          // ── Column 1: Notes ────────────────────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: _notesColWidth,
              decoration: panelDecoration(panelColor),
              child: _buildNotesList(context, notes, l10n),
            ),
          ),

          // ── Divider 1 ──────────────────────────────────────────────────
          _ResizableDivider(
            onDrag: (dx) => setState(() {
              _notesColWidth = (_notesColWidth + dx).clamp(_kColMin, _kColMax);
            }),
            onDragEnd: _saveColWidths,
          ),

          // ── Column 2: Versions (animated) ──────────────────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            child: showVersions
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: _versionsColWidth,
                      decoration: panelDecoration(panelColor),
                      child: _buildVersionsList(context, l10n),
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // ── Divider 2 ──────────────────────────────────────────────────
          if (showVersions)
            _ResizableDivider(
              onDrag: (dx) => setState(() {
                _versionsColWidth =
                    (_versionsColWidth + dx).clamp(_kColMin, _kColMax);
              }),
              onDragEnd: _saveColWidths,
            ),

          // ── Column 3: Diff ─────────────────────────────────────────────
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: ClipRRect(
                key: ValueKey(showDiff
                    ? 'diff_${_selectedVersion?.id}'
                    : 'hint_$showVersions'),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration:
                      panelDecoration(showDiff ? diffPanelColor : panelColor),
                  child: showDiff
                      ? _buildDiffPanel(context, l10n)
                      : _buildEmptyHint(
                          context,
                          showVersions
                              ? Icons.compare_arrows_outlined
                              : Icons.touch_app_outlined,
                          showVersions
                              ? l10n.selectVersionToViewDiff
                              : l10n.selectNoteToViewHistory,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Narrow: stack navigation ──────────────────────────────────────────────
  Widget _buildNarrowLayout(
      BuildContext context, List<Note> notes, AppLocalizations l10n) {
    if (_selectedNote != null && _selectedVersion != null) {
      return _buildDiffPanel(context, l10n);
    }
    if (_selectedNote != null) return _buildVersionsList(context, l10n);
    return _buildNotesList(context, notes, l10n);
  }

  // ── Notes list ────────────────────────────────────────────────────────────
  Widget _buildNotesList(
      BuildContext context, List<Note> notes, AppLocalizations l10n) {
    if (notes.isEmpty) {
      return Center(
        child: Text(
          _searchQuery.isEmpty ? l10n.noHistoryYet : l10n.noResults,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      itemCount: notes.length,
      itemBuilder: (_, i) => _buildNoteItem(context, notes[i], l10n),
    );
  }

  Widget _buildNoteItem(
      BuildContext context, Note note, AppLocalizations l10n) {
    final brightness = Theme.of(context).brightness;
    final noteColor =
        AppColorPalette.palette[note.colorIndex].getColor(brightness);
    final isLight = noteColor.computeLuminance() > 0.5;
    final titleColor = isLight ? Colors.black87 : Colors.white;
    final isSelected = _selectedNote?.id == note.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      elevation: isSelected ? 2 : 0,
      color: isSelected ? noteColor : noteColor.withValues(alpha: 0.6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: isSelected
            ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _selectNote(note),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  note.title.isEmpty ? l10n.untitled : note.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: titleColor),
                ),
              ),
              FutureBuilder<int>(
                future: _versionService.getVersionCount(note.id!),
                builder: (_, snap) => snap.hasData
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${snap.data}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isLight ? Colors.black54 : Colors.white70,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Versions list ─────────────────────────────────────────────────────────
  Widget _buildVersionsList(BuildContext context, AppLocalizations l10n) {
    if (_loadingVersions) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_selectedNoteVersions.isEmpty) {
      return Center(child: Text(l10n.noHistory));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: Text(
            _selectedNote!.title.isEmpty ? l10n.untitled : _selectedNote!.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            itemCount: _selectedNoteVersions.length,
            itemBuilder: (_, i) {
              final version = _selectedNoteVersions[i];
              final isSelected = _selectedVersion?.id == version.id;
              final actionColor = _getActionColor(version.action);
              final actionIcon = _getActionIcon(version.action);

              return Card(
                margin: const EdgeInsets.only(bottom: 6),
                elevation: isSelected ? 2 : 0,
                color: isSelected
                    ? Theme.of(context).colorScheme.primaryContainer
                    : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: isSelected
                      ? BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 1.5)
                      : BorderSide.none,
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => _selectVersion(version),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: actionColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(actionIcon, color: actionColor, size: 16),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                version.title.isEmpty
                                    ? l10n.untitled
                                    : version.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _formatTimeAgo(context, version.timestamp),
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Diff panel ────────────────────────────────────────────────────────────
  Widget _buildDiffPanel(BuildContext context, AppLocalizations l10n) {
    final version = _selectedVersion!;
    final note = _selectedNote!;
    final idx = _selectedNoteVersions.indexWhere((v) => v.id == version.id);
    final older = idx < _selectedNoteVersions.length - 1
        ? _selectedNoteVersions[idx + 1]
        : null;

    final newText = _toPlainText(version.content);
    final oldText = older != null ? _toPlainText(older.content) : '';
    final spans = older != null ? computeDiff(oldText, newText) : null;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color:
                      _getActionColor(version.action).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(_getActionIcon(version.action),
                    color: _getActionColor(version.action), size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      version.title.isEmpty ? l10n.untitled : version.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Text(
                      _formatTimeAgo(context, version.timestamp),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.restore, size: 20),
                tooltip: l10n.restore,
                onPressed: () => _onRestoreVersion(version, note),
              ),
            ],
          ),
        ),
        if (spans != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                _legendDot(const Color(0xFF2E7D32), const Color(0xFFE8F5E9)),
                const SizedBox(width: 4),
                Text(l10n.added, style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 12),
                _legendDot(const Color(0xFFC62828), const Color(0xFFFFEBEE)),
                const SizedBox(width: 4),
                Text(l10n.deleted, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        const Divider(height: 1),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.maxFinite,
              child: spans != null
                  ? DiffView(spans: spans)
                  : Text(
                      newText.isEmpty ? l10n.noHistory : newText,
                      style: const TextStyle(fontSize: 14, height: 1.6),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _legendDot(Color fg, Color bg) => Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          border: Border.all(color: fg, width: 1.5),
        ),
      );

  Widget _buildEmptyHint(BuildContext context, IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
        ],
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
}

// ── Resizable divider widget ──────────────────────────────────────────────────
class _ResizableDivider extends StatefulWidget {
  final ValueChanged<double> onDrag;
  final VoidCallback onDragEnd;

  const _ResizableDivider({
    required this.onDrag,
    required this.onDragEnd,
  });

  @override
  State<_ResizableDivider> createState() => _ResizableDividerState();
}

class _ResizableDividerState extends State<_ResizableDivider> {
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragStart: (_) => setState(() => _dragging = true),
      onHorizontalDragUpdate: (d) => widget.onDrag(d.delta.dx),
      onHorizontalDragEnd: (_) {
        setState(() => _dragging = false);
        widget.onDragEnd();
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeColumn,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 20,
          color: _dragging
              ? Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withValues(alpha: 0.3)
              : Colors.transparent,
          child: Center(
            child: Icon(
              Icons.drag_indicator,
              size: 20,
              color: _dragging
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
        ),
      ),
    );
  }
}
