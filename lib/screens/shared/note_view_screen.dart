// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/controllers/notes/notes_provider.dart';
import 'package:apex_note/core/theme/app_theme.dart';
import 'package:apex_note/core/utils/adaptive_color.dart';
import 'package:apex_note/core/utils/checklist_formatter.dart';
import 'package:apex_note/core/utils/editor_page_route.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:apex_note/models/note.dart';
import 'package:apex_note/models/note_mode.dart';
import 'package:apex_note/screens/shared/note_editor.dart'
    show NoteEditorImmersive;
import 'package:apex_note/screens/shared/note_view/note_view_bars.dart';
import 'package:apex_note/screens/shared/note_view/note_view_helpers.dart';
import 'package:apex_note/screens/shared/note_view/note_view_widgets.dart';
import 'package:apex_note/services/notification_service.dart';
import 'package:apex_note/services/security/biometric_service.dart';
import 'package:apex_note/services/unified_notification_service.dart';
import 'package:apex_note/services/widget_service.dart';
import 'package:apex_note/widgets/common/custom_share_sheet.dart';
import 'package:apex_note/widgets/editor/category_picker_sheet.dart';
import 'package:apex_note/widgets/home/note_card_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

/// Interactive read-only note viewer with markdown rendering
class NoteViewScreen extends StatefulWidget {
  final Note note;
  final bool showRestore;
  final String? heroTag;

  const NoteViewScreen({
    super.key,
    required this.note,
    this.showRestore = false,
    this.heroTag,
  });

  @override
  State<NoteViewScreen> createState() => _NoteViewScreenState();
}

class _NoteViewScreenState extends State<NoteViewScreen>
    with SingleTickerProviderStateMixin {
  bool _isAuthenticated = false;
  late Note _currentNote;
  final _scrollController = ScrollController();
  final _scrollProgress = ValueNotifier<double>(0.0);
  late final AnimationController _contentFadeController;
  late final Animation<double> _contentFade;

  @override
  void initState() {
    super.initState();
    _currentNote = widget.note;

    _contentFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _contentFade = CurvedAnimation(
      parent: _contentFadeController,
      curve: Curves.easeOut,
    );

    // ابدأ الـ fade بعد انتهاء أنيميشن الـ Hero
    final heroDuration = widget.heroTag != null
        ? const Duration(milliseconds: 350)
        : Duration.zero;
    Future.delayed(heroDuration, () {
      if (mounted) _contentFadeController.forward();
    });

    if (!widget.note.isLocked) {
      _isAuthenticated = true;
    } else {
      _verifyUser();
    }
    _scrollController.addListener(() {
      final offset = _scrollController.offset.clamp(0.0, 120.0);
      _scrollProgress.value = offset / 120.0;
    });
  }

  @override
  void dispose() {
    _contentFadeController.dispose();
    _scrollController.dispose();
    _scrollProgress.dispose();
    super.dispose();
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

    if (mounted) {
      provider.unlockVault(); // تفعيل الجلسة
      setState(() => _isAuthenticated = success);
      if (!success && mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _refreshNote() async {
    final provider = Provider.of<NotesProvider>(context, listen: false);
    await provider.refreshAllNotes();
    if (!mounted) return;

    final updatedNote = provider.activeNotes
        .cast<Note?>()
        .firstWhere((n) => n?.id == _currentNote.id, orElse: () => null);
    if (updatedNote != null) {
      setState(() => _currentNote = updatedNote);
    } else if (mounted) {
      // Note not found in active notes, close view
      Navigator.pop(context, true);
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
    final scheme = Theme.of(context).colorScheme;
    final bgColor = AppColorPalette.palette[_currentNote.colorIndex]
        .getColor(Theme.of(context).brightness);
    final textColor =
        bgColor.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;

    return ValueListenableBuilder<double>(
      valueListenable: _scrollProgress,
      builder: (context, progress, child) {
        final barColor = Color.lerp(
          AppTheme.bg(scheme),
          scheme.surface,
          progress,
        )!;

        // الأشرطة تظهر بـ fade بعد اكتمال انيميشن الـ Hero
        final routeAnimation = ModalRoute.of(context)?.animation;
        final barsFade = routeAnimation == null
            ? const AlwaysStoppedAnimation(1.0)
            : CurvedAnimation(
                parent: routeAnimation,
                curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
              );

        return Scaffold(
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight),
            child: FadeTransition(
              opacity: barsFade,
              child: AppBar(
                backgroundColor: barColor,
                title: Text(_currentNote.title.isEmpty ? l10n.viewNote : _currentNote.title),
        actions: [
          if (!_currentNote.isTrashed)
            IconButton(
              icon: Icon(
                _currentNote.categoryIds.isEmpty
                    ? Icons.label_outline_rounded
                    : Icons.label_rounded,
                color: _currentNote.categoryIds.isEmpty
                    ? null
                    : Theme.of(context).colorScheme.primary,
              ),
              tooltip: l10n.categories,
              onPressed: () async {
                final provider = Provider.of<NotesProvider>(context, listen: false);
                final result = await CategoryPickerSheet.show(
                  context, _currentNote.categoryIds,
                  isHiddenFromHome: _currentNote.isHiddenFromHome,
                );
                if (result == null || !mounted) return;
                final updated = _currentNote.copyWith(
                  categoryIds: result['categoryIds'] as List<int>,
                  isHiddenFromHome: result['isHiddenFromHome'] as bool,
                );
                await provider.updateNote(updated);
                if (!mounted) return;
                await _refreshNote();
              },
            ),
          if (!_currentNote.isTrashed)
            IconButton(
              icon: const Icon(Icons.widgets_outlined),
              tooltip: 'Pin to Widget',
              onPressed: () async {
                final nav = Navigator.of(context);
                final messenger = UnifiedNotificationService();
                final l10nSnap = AppLocalizations.of(context)!;
                if (_currentNote.id == null) {
                  messenger.show(
                    context: context,
                    message: 'Cannot pin unsaved note',
                    type: NotificationType.error,
                  );
                  return;
                }

                final noteId = _currentNote.id!;
                final noteTitle = _currentNote.title.isEmpty
                    ? 'Checklist'
                    : _currentNote.title;
                final noteContent = _currentNote.content;
                final noteColorIndex = _currentNote.colorIndex;
                final isChecklistNote = (_currentNote.isChecklist == true) ||
                    (_currentNote.noteType == 'checklist');
                final currentNote = _currentNote;

                if (isChecklistNote) {
                  final stats =
                      NoteViewHelpers.parseChecklistStats(noteContent);
                  await WidgetService().updateChecklistWidget(
                    noteId,
                    noteTitle,
                    noteContent,
                    noteColorIndex,
                    totalItems: stats['total'] ?? 0,
                    completedItems: stats['completed'] ?? 0,
                  );
                } else {
                  await WidgetService().updateNoteWidget(currentNote);
                }

                if (!mounted) return;
                final widgetName =
                    isChecklistNote ? l10nSnap.checklists : l10nSnap.note;
                messenger.show(
                  context: nav.context,
                  message: '${l10nSnap.widgetPinned} $widgetName',
                  type: NotificationType.success,
                  duration: const Duration(seconds: 2),
                );
              },
            ),
        ],
      ),          // AppBar
            ),    // FadeTransition
          ),      // PreferredSize
          body: GestureDetector(
        onDoubleTap: _editNote,
        onLongPress: () {
          final content = _currentNote.isChecklist
              ? ChecklistFormatter.formatForSharing(
                  _currentNote.title, _currentNote.content)
              : '${_currentNote.title}\n\n${NoteCardUtils.fixNoteContent(_currentNote.content, maxChars: _currentNote.content.length)}';
          Clipboard.setData(ClipboardData(text: content.trim()));
          HapticFeedback.mediumImpact();
          UnifiedNotificationService().show(
            context: context,
            message: AppLocalizations.of(context)!.noteCopied,
            type: NotificationType.success,
            duration: const Duration(seconds: 2),
          );
        },
          child: SingleChildScrollView(
          controller: _scrollController,
          child: widget.heroTag != null
              ? Hero(
                  tag: widget.heroTag!,
                  child: _buildNoteCard(bgColor, textColor, l10n),
                )
              : FadeTransition(
                  opacity: CurvedAnimation(
                    parent: routeAnimation ?? const AlwaysStoppedAnimation(1.0),
                    curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
                  ),
                  child: _buildNoteCard(bgColor, textColor, l10n),
                ),
        ),
      ),
          bottomNavigationBar: FadeTransition(
            opacity: barsFade,
            child: _currentNote.isTrashed
                ? NoteViewBars.buildRestoreBar(
                    context, l10n, _currentNote, _restore, _confirmPermanentDelete, barColor: barColor)
                : NoteViewBars.buildActionBar(context, l10n, _currentNote,
                    _onShareTap, _toggleArchive, _confirmDelete, _editNote, barColor: barColor),
          ),
        );
      },
    );
  }

  Widget _buildNoteCard(Color bgColor, Color textColor, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8, bottom: 16),
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
          FadeTransition(
            opacity: _contentFade,
            child: _buildNoteContent(textColor),
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.3), width: 1),
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
                      final provider =
                          Provider.of<NotesProvider>(context, listen: false);
                      final messenger = UnifiedNotificationService();
                      final nav = Navigator.of(context);
                      final reminderRemovedMsg =
                          AppLocalizations.of(context)!.reminderRemoved;
                      final noteId = _currentNote.id!;
                      await NotificationService().cancelNotification(noteId);
                      final updatedNote = _currentNote.copyWith(
                        reminderDateTime: null,
                        recurrenceRule: null,
                      );
                      await provider.updateNote(updatedNote);
                      await _refreshNote();
                      if (!mounted) return;
                      messenger.show(
                        context: nav.context,
                        message: reminderRemovedMsg,
                        type: NotificationType.info,
                      );
                    },
                    child: Icon(Icons.close,
                        size: 16, color: textColor.withValues(alpha: 0.7)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNoteContent(Color textColor) {
    final content = _currentNote.content;

    // checklist
    if (ChecklistFormatter.isValidChecklist(content)) {
      return NoteViewWidgets.buildChecklistView(content, textColor);
    }

    // نوت محترف (كود) — نص خام بخط monospace
    if (_currentNote.isProfessional == true ||
        _currentNote.noteType == 'code' ||
        _currentNote.noteType == 'pro') {
      return SelectableText(
        content,
        style: TextStyle(
          fontSize: 14,
          height: 1.6,
          color: textColor,
          fontFamily: 'monospace',
        ),
      );
    }

    // نوت عادي أو rich — تنظيف Delta إن وجد ثم عرض markdown
    return NoteViewWidgets.buildDirectionalMarkdown(content, textColor);
  }

  Future<void> _editNote() async {
    if (_currentNote.isTrashed) return;

    // CRITICAL: Check isChecklist flag first
    NoteMode mode = NoteCardUtils.getNoteMode(_currentNote);

    if (!mounted) return;
    await Navigator.push(
      context,
      EditorPageRoute(
        builder: (context) =>
            NoteEditorImmersive(note: _currentNote, mode: mode),
      ),
    );

    if (!mounted) return;

    // 🔄 CRITICAL: Refresh note data after editing
    await _refreshNote();
  }

  Future<void> _toggleArchive() async {
    final provider = Provider.of<NotesProvider>(context, listen: false);
    if (_currentNote.isArchived) {
      await provider.unarchiveNote(_currentNote.id!);
    } else {
      await provider.archiveNote(_currentNote.id!);
    }
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  void _onShareTap() async {
    String textToShare;

    if (_currentNote.isChecklist) {
      textToShare = ChecklistFormatter.formatForSharing(
        _currentNote.title,
        _currentNote.content,
      );
    } else {
      textToShare = '${_currentNote.title}\n\n${NoteCardUtils.fixNoteContent(_currentNote.content, maxChars: _currentNote.content.length)}';
    }

    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final provider = Provider.of<NotesProvider>(context, listen: false);
    final noteCopiedMsg = l10n.noteCopied;
    final nav = Navigator.of(context);
    final messenger = UnifiedNotificationService();
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
        await provider.addNote(duplicate);
        await _refreshNote();
        if (!mounted) return;
        messenger.show(
          context: nav.context,
          message: noteCopiedMsg,
          type: NotificationType.success,
        );
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

  Future<void> _restore() async {
    final provider = Provider.of<NotesProvider>(context, listen: false);
    if (widget.note.isTrashed) {
      await provider.restoreNote(widget.note.id!);
    } else if (widget.note.isArchived) {
      await provider.unarchiveNote(widget.note.id!);
    }
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Future<void> _confirmDelete() async {
    if (!mounted) return;
    final currentContext = context;
    final l10n = AppLocalizations.of(currentContext)!;
    final provider = Provider.of<NotesProvider>(currentContext, listen: false);
    final deleteFailed = l10n.deleteFailed;
    final deleteNote = l10n.deleteNote;
    final deleteConfirm = l10n.deleteConfirm;
    final cancel = l10n.cancel;
    final delete = l10n.delete;

    if (!mounted) return;
    final confirm = await showDialog<bool>(
      context: currentContext,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(deleteNote),
        content: Text(deleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final nav = Navigator.of(context);
      final messenger = UnifiedNotificationService();
      try {
        final noteId = _currentNote.id!;
        await provider.trashNote(noteId);
        if (!mounted) return;
        nav.pop(true);
      } catch (e) {
        if (!mounted) return;
        messenger.show(
          context: nav.context,
          message: '$deleteFailed: $e',
          type: NotificationType.error,
        );
      }
    }
  }

  Future<void> _confirmPermanentDelete() async {
    if (!mounted) return;
    final currentContext = context;
    final l10n = AppLocalizations.of(currentContext)!;
    final provider = Provider.of<NotesProvider>(currentContext, listen: false);
    final deleteFailed = l10n.deleteFailed;
    final permanentDelete = l10n.permanentDelete;
    final confirmPermanentDelete = l10n.confirmPermanentDelete;
    final cancel = l10n.cancel;
    final delete = l10n.delete;

    if (!mounted) return;
    final confirm = await showDialog<bool>(
      context: currentContext,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(permanentDelete),
        content: Text(confirmPermanentDelete),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final nav = Navigator.of(context);
      final messenger = UnifiedNotificationService();
      try {
        final noteId = _currentNote.id!;
        await provider.deleteNote(noteId);
        if (!mounted) return;
        nav.pop(true);
      } catch (e) {
        if (!mounted) return;
        messenger.show(
          context: nav.context,
          message: '$deleteFailed: $e',
          type: NotificationType.error,
        );
      }
    }
  }
}
