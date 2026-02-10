// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../generated/l10n/app_localizations.dart';
import '../controllers/settings/settings_provider.dart';
import '../widgets/home/home_drawer_widget.dart';
import '../services/version_history_service.dart';
import '../models/note.dart';
import '../models/note_version.dart';
import '../core/utils/checklist_formatter.dart';
import '../core/utils/adaptive_color.dart';

class VersionHistoryScreen extends StatefulWidget {
  const VersionHistoryScreen({super.key});

  @override
  State<VersionHistoryScreen> createState() => _VersionHistoryScreenState();
}

class _VersionHistoryScreenState extends State<VersionHistoryScreen> {
  final _versionService = VersionHistoryService();
  List<Note> _notesWithHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotesWithHistory();
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
    // 🔒 SECURITY: Filter out locked notes from history
    final unlockedNotes = notes.where((note) => !note.isLocked).toList();
    setState(() {
      _notesWithHistory = unlockedNotes;
      _isLoading = false;
    });
  }

  Future<void> _showVersionsDialog(Note note) async {
    final versions = await _versionService.getNoteVersions(note.id!);
    final versionCount = await _versionService.getVersionCount(note.id!);
    if (!mounted) return;

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
          onRestore: (version) async {
            // Show confirmation
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text(AppLocalizations.of(context)!.confirmRestore),
                content: Text(AppLocalizations.of(context)!.restoreWarning),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(AppLocalizations.of(context)!.cancel),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(AppLocalizations.of(context)!.restore),
                  ),
                ],
              ),
            );

            if (confirmed == true) {
              await _versionService.restoreVersion(note.id!, version);
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context)!.noteRestored),
                    backgroundColor: Colors.green,
                  ),
                );
                _loadNotesWithHistory();
              }
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final isDark = settingsProvider.themeMode == ThemeMode.dark ||
        (settingsProvider.themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.noteHistory),
          centerTitle: true,
        ),
        drawer: HomeDrawerWidget(
          onBackupTap: () {},
          onNotesChanged: () {},
        ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notesWithHistory.isEmpty
              ? Center(
                  child: Text(
                    l10n.noHistoryYet,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 16,
                    bottom: MediaQuery.of(context).padding.bottom + 80,
                  ),
                  itemCount: _notesWithHistory.length,
                  itemBuilder: (context, index) {
                    final note = _notesWithHistory[index];
                    // ✅ Format checklist content for display
                    final displayContent = (note.isChecklist || note.noteType == 'checklist')
                        ? _formatChecklistForDisplay(note.content)
                        : note.content;
                    final preview = displayContent.length > 100
                        ? '${displayContent.substring(0, 100)}...'
                        : displayContent;
                    
                    // ✅ Use note's color (same as note cards)
                    final brightness = Theme.of(context).brightness;
                    final baseColor = AppColorPalette.palette[note.colorIndex].getColor(brightness);
                    final isLightColor = baseColor.computeLuminance() > 0.5;
                    final titleColor = isLightColor ? Colors.black87 : Colors.white;
                    final contentColor = isLightColor ? Colors.grey[700]! : Colors.grey[300]!;

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
                              future: _versionService.getVersionCount(note.id!),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
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
    );
  }
}

class _VersionsBottomSheet extends StatelessWidget {
  final Note note;
  final List<NoteVersion> versions;
  final int totalVersions;
  final ScrollController scrollController;
  final Function(NoteVersion) onRestore;

  const _VersionsBottomSheet({
    required this.note,
    required this.versions,
    required this.totalVersions,
    required this.scrollController,
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        // Handle bar
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
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              const Icon(Icons.history, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.noteHistory,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
            ],
          ),
        ),
        const SizedBox(height: 16),
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
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: actionColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(actionIcon, color: actionColor, size: 22),
                        ),
                        title: Text(
                          version.title.isEmpty ? l10n.untitled : version.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(timeAgo, style: const TextStyle(fontSize: 12)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.visibility_outlined, size: 20),
                              onPressed: () => _showVersionPreview(context, version, l10n),
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

  void _showVersionPreview(BuildContext context, NoteVersion version, AppLocalizations l10n) {
    // ✅ Format checklist content for preview
    final isChecklist = ChecklistFormatter.isValidChecklist(version.content);
    final displayContent = isChecklist
        ? ChecklistFormatter.toDisplayText(version.content)
        : version.content;
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(version.title.isEmpty ? l10n.untitled : version.title),
        content: SingleChildScrollView(
          child: Text(displayContent.isEmpty ? l10n.noHistory : displayContent),
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
