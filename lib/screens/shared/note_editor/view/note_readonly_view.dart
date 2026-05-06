// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/controllers/notes/notes_provider.dart';
import 'package:apex_note/controllers/settings/settings_provider.dart';
import 'package:apex_note/core/theme/app_theme.dart';
import 'package:apex_note/core/utils/checklist_formatter.dart';
import 'package:apex_note/core/utils/note_content_utils.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:apex_note/models/note.dart';
import 'package:apex_note/models/note_mode.dart';
import 'package:apex_note/screens/shared/note_editor/core/editor_coordinator.dart';
import 'package:apex_note/screens/shared/note_editor/view/readonly_checklist_view.dart';
import 'package:apex_note/screens/shared/note_editor/widgets/read_only_bars.dart';
import 'package:apex_note/services/unified_notification_service.dart';
import 'package:apex_note/widgets/common/custom_share_sheet.dart';
import 'package:apex_note/widgets/editor/markdown_viewer.dart';
import 'package:apex_note/widgets/editor/reminder_picker_sheet.dart';
import 'package:apex_note/widgets/home/note_card_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:provider/provider.dart';

class NoteReadOnlyView extends StatefulWidget {
  final Note note;
  final NoteMode mode;
  final EditorCoordinator coordinator;
  final double sidePadding;
  final String? heroTag;
  final VoidCallback? onClose;
  final VoidCallback onEnterEdit;
  final Future<void> Function({bool isManualSave}) onSave;

  const NoteReadOnlyView({
    super.key,
    required this.note,
    required this.mode,
    required this.coordinator,
    required this.sidePadding,
    required this.onEnterEdit,
    required this.onSave,
    this.heroTag,
    this.onClose,
  });

  @override
  State<NoteReadOnlyView> createState() => _NoteReadOnlyViewState();
}

class _NoteReadOnlyViewState extends State<NoteReadOnlyView> {
  final _scrollController = ScrollController();
  bool _showMarkdown = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _closeOrPop() {
    if (widget.onClose != null) {
      widget.onClose!();
    } else if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _onReminder() async {
    final note = widget.note;
    final provider = Provider.of<NotesProvider>(context, listen: false);
    final noteColor = widget.coordinator.getBackgroundColor(context);

    final result = await ReminderPickerSheet.show(
      context,
      note.reminderDateTime,
      null,
      noteColor,
    );
    if (result == null || !mounted) return;

    final updatedNote = note.copyWith(
      reminderDateTime:
          result['remove'] == true ? null : result['dateTime'] as DateTime?,
    );
    await provider.updateNote(updatedNote);
    await _onRefresh();
  }

  Future<void> _onShare() async {
    final note = widget.note;
    final content = note.isChecklist
        ? ChecklistFormatter.formatForSharing(note.title, note.content)
        : '${note.title}\n\n${NoteCardUtils.fixNoteContent(note.content, maxChars: note.content.length)}';
    CustomShareSheet.show(context, content, subject: note.title, note: note);
  }

  Future<void> _onArchive() async {
    if (widget.note.id == null || !mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final provider = Provider.of<NotesProvider>(context, listen: false);
    final note = widget.note;
    final wasArchived = note.isArchived;

    wasArchived
        ? await provider.unarchiveNote(note.id!)
        : await provider.archiveNote(note.id!);

    if (!mounted) return;
    _closeOrPop();

    UnifiedNotificationService().showWithUndo(
      context: context,
      message: wasArchived ? l10n.noteRestored : l10n.movedToArchive,
      type: NotificationType.success,
      actionKey: 'note_archive_${note.id}',
      onExecute: () {},
      onUndo: () async {
        wasArchived
            ? await provider.archiveNote(note.id!)
            : await provider.unarchiveNote(note.id!);
      },
      undoLabel: l10n.undo,
    );
  }

  Future<void> _onDelete() async {
    if (widget.note.id == null || !mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final provider = Provider.of<NotesProvider>(context, listen: false);
    final note = widget.note;

    await provider.trashNote(note.id!);

    if (!mounted) return;
    _closeOrPop();

    UnifiedNotificationService().showWithUndo(
      context: context,
      message: l10n.movedToTrash,
      type: NotificationType.info,
      actionKey: 'note_delete_${note.id}',
      onExecute: () {},
      onUndo: () async => await provider.restoreNote(note.id!),
      undoLabel: l10n.undo,
    );
  }

  Future<void> _onRestore() async {
    if (widget.note.id == null) return;
    final provider = Provider.of<NotesProvider>(context, listen: false);
    widget.note.isTrashed
        ? await provider.restoreNote(widget.note.id!)
        : await provider.unarchiveNote(widget.note.id!);
    if (mounted) _closeOrPop();
  }

  Future<void> _onPermanentDelete() async {
    if (widget.note.id == null || !mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.permanentDelete),
        content: Text(l10n.confirmPermanentDelete),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel)),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child:
                  Text(l10n.delete, style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await Provider.of<NotesProvider>(context, listen: false)
          .deleteNote(widget.note.id!);
      if (mounted) _closeOrPop();
    }
  }

  Future<void> _onRefresh() async {
    if (widget.note.id == null) return;
    final provider = Provider.of<NotesProvider>(context, listen: false);
    await provider.refreshAllNotes();
    if (!mounted) return;
    final updated = provider.activeNotes
        .cast<Note?>()
        .firstWhere((n) => n?.id == widget.note.id, orElse: () => null);
    if (updated != null) {
      setState(() =>
          widget.coordinator.stateManager.colorIndex = updated.colorIndex);
    }
  }

  Widget _buildContent(Color textColor, Color noteColor) {
    // Checklist
    if (widget.mode == NoteMode.checklist) {
      return ReadOnlyChecklistView(
        coordinator: widget.coordinator,
        textColor: textColor,
        noteColor: noteColor,
        scrollController: _scrollController,
        onSave: widget.onSave,
      );
    }

    // Code
    if (widget.mode == NoteMode.code) {
      final content = widget.coordinator.codeController?.text ??
          widget.coordinator.contentController.text;
      return ScrollbarTheme(
        data: const ScrollbarThemeData(thickness: WidgetStatePropertyAll(0)),
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: SelectableText(
                content,
                style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                    height: 1.6,
                    color: textColor),
              ),
            ),
          ),
        ),
      );
    }

    // Quill
    final qc = widget.coordinator.quillController;
    if (qc == null) return const SizedBox.shrink();

    // Markdown
    if (_showMarkdown) {
      final rawContent = widget.note.content;
      final converted = NoteContentUtils.toDisplayText(rawContent);
      debugPrint('📝 [Markdown] raw length: ${rawContent.length}');
      debugPrint('📝 [Markdown] converted length: ${converted.length}');
      debugPrint(
          '📝 [Markdown] first 300 chars:\n${converted.substring(0, converted.length.clamp(0, 300))}');
      return MarkdownViewer(
        content: converted,
        textColor: textColor,
      );
    }

    // Rich / Simple / Reminder
    final fontFamily = Theme.of(context).textTheme.bodyMedium?.fontFamily;
    qc.readOnly = true;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: DefaultTextStyle.merge(
        style: TextStyle(fontFamily: fontFamily),
        child: ScrollbarTheme(
          data: const ScrollbarThemeData(thickness: WidgetStatePropertyAll(0)),
          child: QuillEditor(
            controller: qc,
            focusNode: widget.coordinator.textFieldFocusNode,
            scrollController: _scrollController,
            config: QuillEditorConfig(
              autoFocus: false,
              expands: true,
              scrollable: true,
              padding: const EdgeInsets.symmetric(vertical: 20),
              showCursor: false,
              enableInteractiveSelection: false,
              customStyles: DefaultStyles(
                paragraph: DefaultTextBlockStyle(
                  TextStyle(
                      fontSize: 16,
                      fontFamily: fontFamily,
                      height: 1.6,
                      color: textColor),
                  HorizontalSpacing.zero,
                  VerticalSpacing.zero,
                  VerticalSpacing.zero,
                  null,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final note = widget.note;
    final scheme = Theme.of(context).colorScheme;
    final noteColor = widget.coordinator.getBackgroundColor(context);
    final textColor =
        noteColor.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;
    final appBarColor = AppTheme.secondaryBackground(scheme);

    final routeAnimation = ModalRoute.of(context)?.animation;
    final barsFade = routeAnimation == null
        ? const AlwaysStoppedAnimation(1.0)
        : CurvedAnimation(
            parent: routeAnimation,
            curve: const Interval(0.6, 1.0, curve: Curves.easeOut));

    final isChecklist = widget.mode == NoteMode.checklist;
    final isMarkdown = _showMarkdown;
    final noteCard = Container(
      width: double.infinity,
      height: isMarkdown ? null : double.infinity,
      margin: const EdgeInsets.only(top: 8, bottom: 16),
      padding: isChecklist
          ? const EdgeInsets.fromLTRB(12, 20, 12, 12)
          : const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: noteColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8))
        ],
      ),
      child: _buildContent(textColor, noteColor),
    );

    final heroTag = widget.heroTag ?? 'note_card_${note.id}';
    final heroEnabled = Provider.of<SettingsProvider>(context, listen: false)
        .heroAnimationEnabled;
    final heroCard = heroEnabled
        ? Hero(
            tag: heroTag,
            transitionOnUserGestures: false,
            createRectTween: (begin, end) => RectTween(begin: begin, end: end),
            flightShuttleBuilder: (_, animation, direction, fromCtx, toCtx) =>
                FadeTransition(
              opacity: direction == HeroFlightDirection.push
                  ? animation
                  : ReverseAnimation(animation),
              child: Material(color: Colors.transparent, child: noteCard),
            ),
            child: noteCard,
          )
        : noteCard;

    final canMarkdown = widget.mode == NoteMode.simple ||
        widget.mode == NoteMode.rich ||
        widget.mode == NoteMode.reminder;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppTheme.scaffoldBackground(scheme),
      appBar: ReadOnlyBars.buildTopBar(
        context: context,
        note: note,
        barColor: appBarColor,
        fadeAnimation: barsFade,
        onEdit: widget.onEnterEdit,
        onRefresh: _onRefresh,
        showMarkdown: _showMarkdown,
        onReminder: note.isTrashed ? null : _onReminder,
        onMarkdownToggle: canMarkdown
            ? () => setState(() => _showMarkdown = !_showMarkdown)
            : null,
      ),
      body: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        thickness: 4,
        radius: const Radius.circular(4),
        child: isMarkdown
            ? SingleChildScrollView(
                controller: _scrollController,
                child: GestureDetector(
                  onDoubleTap: note.isTrashed ? null : widget.onEnterEdit,
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: widget.sidePadding),
                    child: heroCard,
                  ),
                ),
              )
            : GestureDetector(
                onDoubleTap: note.isTrashed ? null : widget.onEnterEdit,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: widget.sidePadding),
                  child: heroCard,
                ),
              ),
      ),
      bottomNavigationBar: note.isTrashed
          ? ReadOnlyBars.buildRestoreBar(
              context: context,
              barColor: appBarColor,
              fadeAnimation: barsFade,
              onRestore: _onRestore,
              onPermanentDelete: _onPermanentDelete,
            )
          : ReadOnlyBars.buildActionBar(
              context: context,
              note: note,
              barColor: appBarColor,
              fadeAnimation: barsFade,
              onShare: _onShare,
              onArchive: _onArchive,
              onDelete: _onDelete,
              onEdit: widget.onEnterEdit,
            ),
    );
  }
}
