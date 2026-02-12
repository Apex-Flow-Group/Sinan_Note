// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/note.dart';
import '../core/utils/adaptive_color.dart';
import '../models/note_mode.dart';
import '../controllers/notes/notes_provider.dart';
import '../services/security/biometric_service.dart';
import '../services/widget_service.dart';
import '../services/notification_service.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import '../widgets/common/apex_snackbar.dart';
import '../core/utils/checklist_formatter.dart';
import '../widgets/common/custom_share_sheet.dart';
import 'note_editor.dart' show NoteEditorImmersive;
import 'note_view/note_view_helpers.dart';
import 'note_view/note_view_widgets.dart';
import 'note_view/note_view_bars.dart';

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
    } else {
      // Note not found in active notes, close view
      if (mounted) Navigator.pop(context, true);
    }
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
          if (!_currentNote.isTrashed)
            IconButton(
              icon: const Icon(Icons.widgets_outlined),
              tooltip: 'Pin to Widget',
              onPressed: () async {
                if (_currentNote.id == null) {
                  ApexSnackBar.show(
                    context,
                    'Cannot pin unsaved note',
                    type: SnackBarType.error,
                  );
                  return;
                }
                
                final isChecklistNote = (_currentNote.isChecklist == true) || 
                    (_currentNote.noteType == 'checklist');
                
                if (isChecklistNote) {
                  final stats = NoteViewHelpers.parseChecklistStats(_currentNote.content);
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
                
                final widgetName = isChecklistNote ? l10n.checklists : l10n.note;
                ApexSnackBar.show(
                  context,
                  '${l10n.widgetPinned} $widgetName',
                  type: SnackBarType.success,
                  duration: const Duration(seconds: 2),
                );
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
                    ? NoteViewWidgets.buildChecklistView(_currentNote.content, textColor)
                    : Directionality(
                        textDirection: NoteViewHelpers.getDirection(_currentNote.content)
                            ? TextDirection.rtl
                            : TextDirection.ltr,
                        child: MarkdownBody(
                          data: _currentNote.content.replaceAll('\n', '  \n'),
                          checkboxBuilder: (bool checked) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Icon(
                              checked ? Icons.check_box : Icons.check_box_outline_blank,
                              size: 20,
                              color: textColor,
                            ),
                          ),
                          styleSheet: NoteViewWidgets.buildMarkdownStyle(textColor),
                        ),
                      ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '${l10n.created}: ${NoteViewHelpers.formatDate(_currentNote.createdAt)}',
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
                        Expanded(
                          child: Text(
                            _formatReminderDate(_currentNote.reminderDateTime!),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.orange,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () async {
                            HapticFeedback.lightImpact();
                            final provider = Provider.of<NotesProvider>(context, listen: false);
                            await NotificationService().cancelNotification(_currentNote.id!);
                            final updatedNote = _currentNote.copyWith(
                              reminderDateTime: null,
                              recurrenceRule: null,
                            );
                            await provider.updateNote(updatedNote);
                            await _refreshNote();
                            if (mounted) {
                              ApexSnackBar.show(
                                context,
                                l10n.reminderRemoved,
                                type: SnackBarType.info,
                              );
                            }
                          },
                          child: Icon(Icons.close, size: 16, color: textColor.withValues(alpha: 0.7)),
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
      bottomNavigationBar: _currentNote.isTrashed
          ? NoteViewBars.buildRestoreBar(context, l10n, _currentNote, 
              () => _restore(context, l10n),
              () => _confirmPermanentDelete(context, l10n))
          : NoteViewBars.buildActionBar(context, l10n, _currentNote,
              _onShareTap,
              () => _toggleArchive(context, l10n),
              () => _confirmDelete(context, l10n),
              () => _editNote(context)),

    );
  }



  Future<void> _editNote(BuildContext context) async {
    if (_currentNote.isTrashed) return;
    
    // CRITICAL: Check isChecklist flag first
    NoteMode mode;
    if (_currentNote.isChecklist) {
      mode = NoteMode.checklist;
    } else {
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

      if (codeTypes.contains(_currentNote.noteType)) {
        mode = NoteMode.code;
      } else {
        mode = NoteMode.values.firstWhere(
          (m) => m.name == _currentNote.noteType,
          orElse: () => NoteMode.simple,
        );
      }
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            NoteEditorImmersive(note: _currentNote, mode: mode),
      ),
    );

    // 🔄 CRITICAL: Refresh note data after editing
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



  void _onShareTap() async {
    String textToShare;

    if (_currentNote.isChecklist) {
      textToShare = ChecklistFormatter.formatForSharing(
        _currentNote.title,
        _currentNote.content,
      );
    } else {
      textToShare = '${_currentNote.title}\n\n${_currentNote.content}';
    }

    if (!mounted) return;
    
    final provider = Provider.of<NotesProvider>(context, listen: false);
    CustomShareSheet.show(
      context,
      textToShare,
      subject: _currentNote.title,
      note: _currentNote,
      onNoteCopied: () async {
        final duplicate = Note(
          title: '${_currentNote.title} - Copy',
          content: _currentNote.content,
          colorIndex: _currentNote.colorIndex,
          noteType: _currentNote.noteType,
          isChecklist: _currentNote.isChecklist,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final newId = await provider.addNote(duplicate);
        await _refreshNote();
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          ApexSnackBar.show(
            context,
            l10n.noteCopied,
            type: SnackBarType.success,
          );
        }
      },
    );
  }

  String _formatReminderDate(DateTime date) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final reminderDay = DateTime(date.year, date.month, date.day);
    final diff = reminderDay.difference(today).inDays;

    String dateStr;
    if (diff == 0) {
      dateStr = l10n.today;
    } else if (diff == 1) {
      dateStr = l10n.tomorrow;
    } else if (diff < 7) {
      dateStr = '$diff ${l10n.thisWeek.toLowerCase()}';
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



