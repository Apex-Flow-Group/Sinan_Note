// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/controllers/settings/settings_provider.dart';
import 'package:apex_note/core/utils/adaptive_color.dart';
import 'package:apex_note/core/utils/checklist_formatter.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:apex_note/models/note.dart';
import 'package:apex_note/models/note_version.dart';
import 'package:apex_note/services/version_history_service.dart';
import 'package:apex_note/widgets/home/home_drawer_widget.dart';
import 'package:apex_note/widgets/home/note_card_utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// ── Diff types ───────────────────────────────────────────────────────────────
enum _DiffType { equal, added, removed }

class _DiffSpan {
  final _DiffType type;
  final String text;
  const _DiffSpan(this.type, this.text);
}

List<_DiffSpan> _computeDiff(String oldText, String newText) {
  final a = oldText.split(RegExp(r'(?<=\s)|(?=\s)'));
  final b = newText.split(RegExp(r'(?<=\s)|(?=\s)'));
  final m = a.length, n = b.length;
  final dp = List.generate(m + 1, (_) => List.filled(n + 1, 0));
  for (var i = m - 1; i >= 0; i--) {
    for (var j = n - 1; j >= 0; j--) {
      if (a[i] == b[j]) {
        dp[i][j] = dp[i + 1][j + 1] + 1;
      } else {
        dp[i][j] = dp[i + 1][j] > dp[i][j + 1] ? dp[i + 1][j] : dp[i][j + 1];
      }
    }
  }
  final spans = <_DiffSpan>[];
  var i = 0, j = 0;
  while (i < m && j < n) {
    if (a[i] == b[j]) {
      spans.add(_DiffSpan(_DiffType.equal, a[i]));
      i++;
      j++;
    } else if (dp[i + 1][j] >= dp[i][j + 1]) {
      spans.add(_DiffSpan(_DiffType.removed, a[i]));
      i++;
    } else {
      spans.add(_DiffSpan(_DiffType.added, b[j]));
      j++;
    }
  }
  while (i < m) {
    spans.add(_DiffSpan(_DiffType.removed, a[i++]));
  }
  while (j < n) {
    spans.add(_DiffSpan(_DiffType.added, b[j++]));
  }
  return spans;
}

class _DiffView extends StatelessWidget {
  final List<_DiffSpan> spans;
  const _DiffView({required this.spans});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: spans.map((s) {
          switch (s.type) {
            case _DiffType.added:
              return TextSpan(
                text: s.text,
                style: const TextStyle(
                  color: Color(0xFF2E7D32),
                  backgroundColor: Color(0xFFE8F5E9),
                  fontWeight: FontWeight.w500,
                ),
              );
            case _DiffType.removed:
              return TextSpan(
                text: s.text,
                style: const TextStyle(
                  color: Color(0xFFC62828),
                  backgroundColor: Color(0xFFFFEBEE),
                  decoration: TextDecoration.lineThrough,
                ),
              );
            case _DiffType.equal:
              return TextSpan(text: s.text);
          }
        }).toList(),
      ),
      style: const TextStyle(fontSize: 14, height: 1.6),
    );
  }
}

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
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Note> _filterAndSortNotes() {
    var notes = _notesWithHistory;

    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.trim();
      notes = notes.where((note) {
        return note.title.toLowerCase().contains(query) ||
            note.content.toLowerCase().contains(query);
      }).toList();
    }

    if (_sortBy == 'title') {
      notes.sort((a, b) => a.title.compareTo(b.title));
    } else {
      notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    }

    return notes;
  }

  /// Format checklist JSON to readable text
  String _formatChecklistForDisplay(String content) {
    if (!ChecklistFormatter.isValidChecklist(content)) {
      return content;
    }
    return ChecklistFormatter.toDisplayText(content);
  }

  Future<void> _loadNotesWithHistory() async {
    setState(() => _isLoading = true);
    final notes = await _versionService.getNotesWithHistory();
    final unlockedNotes = notes.where((note) => !note.isLocked).toList();
    setState(() {
      _notesWithHistory = unlockedNotes;
      _isLoading = false;
    });
  }

  Future<void> _onRestoreVersion(NoteVersion version, Note note) async {
    final l10n = AppLocalizations.of(context)!;
    // Show confirmation
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.confirmRestore),
        content: Text(l10n.restoreWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.restore),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) return;

    await _versionService.restoreVersion(note.id!, version);
    if (!mounted) return;

    Navigator.pop(context); // Pop the bottom sheet
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.noteRestored),
        backgroundColor: Colors.green,
      ),
    );
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
            child: _VersionsBottomSheet(
              note: note,
              versions: versions,
              totalVersions: versionCount,
              scrollController: ScrollController(),
              onRestore: (version) => _onRestoreVersion(version, note),
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => _VersionsBottomSheet(
            note: note,
            versions: versions,
            totalVersions: versionCount,
            scrollController: scrollController,
            onRestore: (version) => _onRestoreVersion(version, note),
            isDesktop: false,
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
        if (!didPop) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      },
      child: Scaffold(
        drawer: HomeDrawerWidget(
          onBackupTap: () {},
          onNotesChanged: () {},
        ),
        appBar: AppBar(
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          title: _isSearching
              ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: l10n.searchNotes,
                    border: InputBorder.none,
                  ),
                )
              : Text(l10n.noteHistory),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(_isSearching ? Icons.close : Icons.search),
              onPressed: () {
                setState(() {
                  if (_isSearching) {
                    _isSearching = false;
                    _searchController.clear();
                  } else {
                    _isSearching = true;
                  }
                });
              },
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.sort),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              onSelected: (value) {
                setState(() => _sortBy = value);
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'date',
                  child: Row(
                    children: [
                      Icon(Icons.access_time,
                          size: 20,
                          color: _sortBy == 'date'
                              ? Theme.of(context).colorScheme.primary
                              : null),
                      const SizedBox(width: 12),
                      Text(l10n.sortByDate),
                      if (_sortBy == 'date') ...[
                        const Spacer(),
                        Icon(Icons.check,
                            size: 20,
                            color: Theme.of(context).colorScheme.primary),
                      ],
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'title',
                  child: Row(
                    children: [
                      Icon(Icons.sort_by_alpha,
                          size: 20,
                          color: _sortBy == 'title'
                              ? Theme.of(context).colorScheme.primary
                              : null),
                      const SizedBox(width: 12),
                      Text(l10n.sortByTitle),
                      if (_sortBy == 'title') ...[
                        const Spacer(),
                        Icon(Icons.check,
                            size: 20,
                            color: Theme.of(context).colorScheme.primary),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: _isLoading
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
                        itemBuilder: (context, index) {
                          final note = filteredNotes[index];
                          // ✅ Format checklist content for display
                          final displayContent =
                              (note.isChecklist || note.noteType == 'checklist')
                                  ? _formatChecklistForDisplay(note.content)
                                  : note.content;
                          final preview = displayContent.length > 100
                              ? '${displayContent.substring(0, 100)}...'
                              : displayContent;

                          // ✅ Use note's color (same as note cards)
                          final brightness = Theme.of(context).brightness;
                          final baseColor = AppColorPalette
                              .palette[note.colorIndex]
                              .getColor(brightness);
                          final isLightColor =
                              baseColor.computeLuminance() > 0.5;
                          final titleColor =
                              isLightColor ? Colors.black87 : Colors.white;
                          final contentColor = isLightColor
                              ? Colors.grey[700]!
                              : Colors.grey[300]!;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 0,
                            color: baseColor,
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              title: Text(
                                note.title.isEmpty ? l10n.untitled : note.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: titleColor,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 8),
                                  Text(
                                    preview,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: contentColor),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  FutureBuilder<int>(
                                    future: _versionService
                                        .getVersionCount(note.id!),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData) {
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.blue
                                                .withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            '${snapshot.data}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        );
                                      }
                                      return const SizedBox.shrink();
                                    },
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
                        },
                      ),
                    ),
                  ),
      ),
    );
  }
}

class _VersionsBottomSheet extends StatelessWidget {
  final Note note;
  final List<NoteVersion> versions;
  final int totalVersions;
  final ScrollController scrollController;
  final Function(NoteVersion) onRestore;
  final bool isDesktop;

  const _VersionsBottomSheet({
    required this.note,
    required this.versions,
    required this.totalVersions,
    required this.scrollController,
    required this.onRestore,
    this.isDesktop = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        // Handle bar - موبايل فقط
        if (!isDesktop)
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 16),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        // Header
        Padding(
          padding: EdgeInsets.fromLTRB(20, isDesktop ? 12 : 0, 8, 0),
          child: Row(
            children: [
              const Icon(Icons.history, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.noteHistory,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '$totalVersions',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
              if (isDesktop)
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
            ],
          ),
        ),
        if (isDesktop) const Divider(height: 1),
        const SizedBox(height: 8),
        // Versions list
        Expanded(
          child: versions.isEmpty
              ? Center(child: Text(l10n.noHistory))
              : ListView.builder(
                  controller: scrollController,
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: MediaQuery.of(context).padding.bottom + 16,
                  ),
                  itemCount: versions.length,
                  itemBuilder: (context, index) {
                    final version = versions[index];
                    final timeAgo = _formatTimeAgo(context, version.timestamp);
                    final actionIcon = _getActionIcon(version.action);
                    final actionColor = _getActionColor(version.action);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: actionColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(actionIcon,
                                  color: actionColor, size: 22),
                            ),
                            const SizedBox(width: 12),
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
                                        fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(timeAgo,
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                            ),
                            if (index < versions.length - 1)
                              IconButton(
                                icon: const Icon(Icons.compare, size: 20),
                                tooltip: l10n.preview,
                                onPressed: () => _showDiffDialog(
                                  context,
                                  versions[index + 1],
                                  version,
                                  l10n,
                                ),
                              ),
                            IconButton(
                              icon: const Icon(Icons.visibility_outlined,
                                  size: 20),
                              onPressed: () =>
                                  _showVersionPreview(context, version, l10n),
                            ),
                            IconButton(
                              icon: const Icon(Icons.restore, size: 20),
                              onPressed: () => onRestore(version),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  IconData _getActionIcon(String action) {
    switch (action) {
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

  Color _getActionColor(String action) {
    switch (action) {
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

  void _showDiffDialog(BuildContext context, NoteVersion older,
      NoteVersion newer, AppLocalizations l10n) {
    final oldText = ChecklistFormatter.isValidChecklist(older.content)
        ? ChecklistFormatter.toDisplayText(older.content)
        : older.content;
    final newText = ChecklistFormatter.isValidChecklist(newer.content)
        ? ChecklistFormatter.toDisplayText(newer.content)
        : newer.content;
    final spans = _computeDiff(oldText, newText);

    final screenSize = MediaQuery.of(context).size;
    final isSmall = screenSize.width < 600;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: EdgeInsets.symmetric(
          horizontal: isSmall ? 16 : 40,
          vertical: isSmall ? 24 : 40,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 600,
            maxHeight: screenSize.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
                child: Row(
                  children: [
                    const Icon(Icons.compare, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(l10n.preview,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              // Legend
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _legendDot(
                        const Color(0xFF2E7D32), const Color(0xFFE8F5E9)),
                    const SizedBox(width: 4),
                    Text(l10n.added, style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 12),
                    _legendDot(
                        const Color(0xFFC62828), const Color(0xFFFFEBEE)),
                    const SizedBox(width: 4),
                    Text(l10n.deleted, style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Diff content - scrollable
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.maxFinite,
                    child: _DiffView(spans: spans),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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

  void _showVersionPreview(
      BuildContext context, NoteVersion version, AppLocalizations l10n) {
    final isChecklist = ChecklistFormatter.isValidChecklist(version.content);
    final displayContent = isChecklist
        ? ChecklistFormatter.toDisplayText(version.content)
        : version.content;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(version.title.isEmpty ? l10n.untitled : version.title),
        content: SingleChildScrollView(
          child: isChecklist
              ? NoteCardUtils.buildChecklistPreview(
                  version.content, Theme.of(ctx).textTheme.bodyMedium!.color!)
              : Text(displayContent.isEmpty ? l10n.noHistory : displayContent),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.close),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onRestore(version);
            },
            child: Text(l10n.restore),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(BuildContext context, DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    final l10n = AppLocalizations.of(context)!;

    if (difference.inMinutes < 1) {
      return l10n.justNow;
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
