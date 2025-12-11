// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/note.dart';
import '../utils/adaptive_color.dart';
import '../models/note_mode.dart';
// DatabaseService removed - use Provider instead
import '../services/notes_provider.dart';
import '../services/biometric_service.dart';
import '../services/widget_service.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import '../widgets/apex_snackbar.dart';
import '../utils/checklist_formatter.dart';
import '../widgets/custom_share_sheet.dart';
import 'note_editor.dart' show NoteEditorImmersive;

/// Interactive read-only note viewer with markdown rendering
class NoteViewScreen extends StatefulWidget {
  final Note note;
  final bool showRestore;

  const NoteViewScreen({
    super.key,
    required this.note,
    this.showRestore = false,
  });

  @override
  State<NoteViewScreen> createState() => _NoteViewScreenState();
}

class _NoteViewScreenState extends State<NoteViewScreen> {
  bool _isAuthenticated = false;
  late Note _currentNote;

  @override
  void initState() {
    super.initState();
    _currentNote = widget.note;
    if (!widget.note.isLocked) {
      _isAuthenticated = true;
    } else {
      _verifyUser();
    }
  }

  Future<void> _verifyUser() async {
    final provider = Provider.of<NotesProvider>(context, listen: false);

    // 1. تحقق من الجلسة المفتوحة مسبقاً
    if (provider.isVaultUnlocked) {
      if (mounted) {
        setState(() => _isAuthenticated = true);
      }
      return;
    }

    // 2. طلب البصمة إذا لم تكن مفتوحة
    final bool success = await BiometricService.authenticate();

    if (success) {
      provider.unlockVault(); // تفعيل الجلسة
    }

    if (mounted) {
      setState(() => _isAuthenticated = success);

      if (!success) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _refreshNote() async {
    final provider = Provider.of<NotesProvider>(context, listen: false);
    await provider.refreshAllNotes();
    final updatedNote = provider.activeNotes
        .cast<Note?>()
        .firstWhere((n) => n?.id == _currentNote.id, orElse: () => null);
    if (updatedNote != null && mounted) {
      setState(() => _currentNote = updatedNote);
    }
  }

  TextDirection _getDirection(String text) {
    final hasArabic = RegExp(r'[؀-ۿ]').hasMatch(text);
    return hasArabic ? TextDirection.rtl : TextDirection.ltr;
  }

  Map<String, int> _parseChecklistStats(String content) {
    try {
      final items = ChecklistFormatter.parseJson(content);
      final total = items.length;
      final completed = items.where((item) => item.isDone).length;
      return {'total': total, 'completed': completed};
    } catch (e) {
      return {'total': 0, 'completed': 0};
    }
  }

  Widget _buildChecklistView(String content, Color textColor) {
    final items = ChecklistFormatter.parseJson(content);
    if (items.isEmpty) {
      return Text(
        content,
        style: TextStyle(fontSize: 16, height: 1.5, color: textColor),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                item.isDone ? Icons.check_box : Icons.check_box_outline_blank,
                size: 24,
                color: item.isDone
                    ? Colors.green
                    : textColor.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.text.isEmpty ? 'Mission...' : item.text,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: item.isDone
                        ? textColor.withValues(alpha: 0.6)
                        : textColor,
                    decoration: item.isDone ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentNote.isLocked && !_isAuthenticated) {
      final l10n = AppLocalizations.of(context)!;
      return Scaffold(
        appBar: AppBar(title: Text(l10n.protectedNote)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(l10n.verifyingIdentity,
                  style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }
    final l10n = AppLocalizations.of(context)!;
    final bgColor = AppColorPalette.palette[_currentNote.colorIndex].getColor(Theme.of(context).brightness);
    final textColor =
        bgColor.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: Text(
            _currentNote.title.isEmpty ? l10n.viewNote : _currentNote.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.widgets_outlined),
            tooltip: 'Pin to Widget',
            onPressed: () async {
              
              // Check if note ID exists
              if (_currentNote.id == null) {
                ApexSnackBar.show(
                  context,
                  'Cannot pin unsaved note',
                  type: SnackBarType.error,
                );
                return;
              }
              
              // Check if it's a checklist (same logic as WidgetService)
              final isChecklistNote = (_currentNote.isChecklist == true) || 
                  (_currentNote.noteType == 'checklist');
              
              if (isChecklistNote) {
                // Parse checklist stats for widget
                final stats = _parseChecklistStats(_currentNote.content);
                await WidgetService().updateChecklistWidget(
                  _currentNote.id!,
                  _currentNote.title.isEmpty ? 'Checklist' : _currentNote.title,
                  _currentNote.content,
                  _currentNote.colorIndex,
                  totalItems: stats['total'] ?? 0,
                  completedItems: stats['completed'] ?? 0,
                );
              } else {
                await WidgetService().updateNoteWidget(_currentNote);
              }
              
              final widgetName = isChecklistNote ? 'ويدجت القوائم' : 'ويدجت الملاحظات';
              ApexSnackBar.show(
                context,
                '✅ تم التثبيت في $widgetName',
                type: SnackBarType.success,
                duration: const Duration(seconds: 2),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: l10n.copy,
            onPressed: () {
              String textToCopy;
              if (_currentNote.isChecklist) {
                textToCopy = ChecklistFormatter.formatForSharing(
                  _currentNote.title,
                  _currentNote.content,
                );
              } else {
                textToCopy = '${_currentNote.title}\n\n${_currentNote.content}';
              }
              Clipboard.setData(ClipboardData(text: textToCopy));
              ApexSnackBar.show(context, l10n.copied,
                  type: SnackBarType.success);
            },
          ),
        ],
      ),
      body: GestureDetector(
        onDoubleTap: () => _editNote(context),
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ChecklistFormatter.isValidChecklist(_currentNote.content)
                    ? _buildChecklistView(_currentNote.content, textColor)
                    : Directionality(
                        textDirection: _getDirection(_currentNote.content),
                        child: MarkdownBody(
                          data: _currentNote.content,
                          checkboxBuilder: (bool checked) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Icon(
                              checked
                                  ? Icons.check_box
                                  : Icons.check_box_outline_blank,
                              size: 20,
                              color: textColor,
                            ),
                          ),
                          styleSheet: MarkdownStyleSheet(
                            p: TextStyle(
                                fontSize: 16, height: 1.5, color: textColor),
                            h1: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: textColor),
                            h2: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: textColor),
                            h3: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: textColor),
                            strong: TextStyle(
                                fontWeight: FontWeight.bold, color: textColor),
                            em: TextStyle(
                                fontStyle: FontStyle.italic, color: textColor),
                            listBullet: TextStyle(color: textColor),
                            checkbox: TextStyle(color: textColor),
                            code: TextStyle(
                              backgroundColor: textColor.withValues(alpha: 0.1),
                              fontFamily: 'monospace',
                              color: textColor,
                            ),
                          ),
                        ),
                      ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '${l10n.created}: ${_formatDate(_currentNote.createdAt)}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                if (_currentNote.reminderDateTime != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.3),
                          width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.alarm, size: 14, color: Colors.orange),
                        const SizedBox(width: 6),
                        Text(
                          _formatReminderDate(_currentNote.reminderDateTime!),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: widget.showRestore
          ? _buildRestoreBar(context, l10n)
          : _buildActionBar(context, l10n),
      floatingActionButton: !widget.showRestore
          ? FloatingActionButton(
              heroTag: 'note_view_edit_fab',
              onPressed: () => _editNote(context),
              child: const Icon(Icons.edit),
            )
          : null,
      floatingActionButtonLocation: _RTLAwareFloatingActionButtonLocation(),

    );
  }

  Widget _buildActionBar(BuildContext context, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).bottomAppBarTheme.color ??
            Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: const Icon(Icons.share),
              tooltip: l10n.share,
              onPressed: _onShareTap,
            ),
            IconButton(
              icon: Icon(
                  _currentNote.isArchived ? Icons.unarchive : Icons.archive),
              tooltip: _currentNote.isArchived ? l10n.unarchive : l10n.archive,
              onPressed: () => _toggleArchive(context, l10n),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              tooltip: l10n.delete,
              onPressed: () => _confirmDelete(context, l10n),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestoreBar(BuildContext context, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        border: const Border(top: BorderSide(color: Colors.green, width: 2)),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.restore),
              label: Text(l10n.restore),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () => _restore(context, l10n),
            ),
            if (_currentNote.isTrashed)
              OutlinedButton.icon(
                icon: const Icon(Icons.delete_forever, color: Colors.red),
                label: Text(l10n.permanentDelete),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                onPressed: () => _confirmPermanentDelete(context, l10n),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _editNote(BuildContext context) async {
    // Map noteType to NoteMode
    final codeTypes = [
      'python',
      'javascript',
      'java',
      'dart',
      'html',
      'css',
      'sql',
      'cpp',
      'c',
      'csharp',
      'swift',
      'kotlin',
      'go',
      'rust',
      'php',
      'ruby',
      'bash',
      'json',
      'xml',
      'code',
      'pro',
      'professional'
    ];

    NoteMode mode;
    if (codeTypes.contains(_currentNote.noteType)) {
      mode = NoteMode.code;
    } else {
      mode = NoteMode.values.firstWhere(
        (m) => m.name == _currentNote.noteType,
        orElse: () => NoteMode.simple,
      );
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            NoteEditorImmersive(note: _currentNote, mode: mode),
      ),
    );

    await _refreshNote();
  }

  Future<void> _toggleArchive(
      BuildContext context, AppLocalizations l10n) async {
    final provider = Provider.of<NotesProvider>(context, listen: false);
    if (_currentNote.isArchived) {
      await provider.unarchiveNote(_currentNote.id!);
    } else {
      await provider.archiveNote(_currentNote.id!);
    }
    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _onShareTap() {
    String textToShare;

    if (_currentNote.isChecklist) {
      textToShare = ChecklistFormatter.formatForSharing(
        _currentNote.title,
        _currentNote.content,
      );
    } else {
      textToShare = '${_currentNote.title}\n\n${_currentNote.content}';
    }

    CustomShareSheet.show(context, textToShare, subject: _currentNote.title);
  }

  String _formatReminderDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final reminderDay = DateTime(date.year, date.month, date.day);
    final diff = reminderDay.difference(today).inDays;

    String dateStr;
    if (diff == 0) {
      dateStr = 'Today';
    } else if (diff == 1) {
      dateStr = 'Tomorrow';
    } else if (diff < 7) {
      dateStr = 'in $diff days';
    } else {
      dateStr = '${date.month}/${date.day}';
    }

    final timeStr =
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    return '$dateStr • $timeStr';
  }

  Future<void> _restore(BuildContext context, AppLocalizations l10n) async {
    final provider = Provider.of<NotesProvider>(context, listen: false);
    if (widget.note.isTrashed) {
      await provider.restoreNote(widget.note.id!);
    } else if (widget.note.isArchived) {
      await provider.unarchiveNote(widget.note.id!);
    }
    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _confirmDelete(
      BuildContext context, AppLocalizations l10n) async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteNote),
        content: Text(l10n.deleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        final provider = Provider.of<NotesProvider>(context, listen: false);
        await provider.trashNote(_currentNote.id!);
        if (mounted && Navigator.canPop(context)) {
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('${l10n.deleteFailed}: $e'),
                backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _confirmPermanentDelete(
      BuildContext context, AppLocalizations l10n) async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.permanentDelete),
        content: Text(l10n.confirmPermanentDelete),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        final provider = Provider.of<NotesProvider>(context, listen: false);
        await provider.deleteNote(_currentNote.id!);
        if (mounted && Navigator.canPop(context)) {
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('${l10n.deleteFailed}: $e'),
                backgroundColor: Colors.red),
          );
        }
      }
    }
  }
}


// Custom FloatingActionButton location that always positions on the right
class _RTLAwareFloatingActionButtonLocation extends FloatingActionButtonLocation {
  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    // Always position on the right (16px from right edge, 80px from bottom)
    final double fabX = scaffoldGeometry.scaffoldSize.width - 
                        scaffoldGeometry.floatingActionButtonSize.width - 16.0;
    final double fabY = scaffoldGeometry.scaffoldSize.height - 
                        scaffoldGeometry.floatingActionButtonSize.height - 
                        scaffoldGeometry.minInsets.bottom - 80.0;
    return Offset(fabX, fabY);
  }
}
