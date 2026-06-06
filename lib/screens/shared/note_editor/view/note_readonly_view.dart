// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:convert';
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:provider/provider.dart';
import 'package:sinan_note/controllers/notes/notes_provider.dart';
import 'package:sinan_note/controllers/settings/settings_provider.dart';
import 'package:sinan_note/core/theme/app_theme.dart';
import 'package:sinan_note/core/utils/checklist_formatter.dart';
import 'package:sinan_note/core/utils/note_content_utils.dart';
import 'package:sinan_note/core/utils/quill_migration.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';
import 'package:sinan_note/models/note.dart';
import 'package:sinan_note/models/note_mode.dart';
import 'package:sinan_note/screens/shared/note_editor/core/editor_coordinator.dart';
import 'package:sinan_note/screens/shared/note_editor/view/book_mode_view.dart';
import 'package:sinan_note/screens/shared/note_editor/view/readonly_content.dart';
import 'package:sinan_note/screens/shared/note_editor/view/trash_floating_sheet.dart';
import 'package:sinan_note/screens/shared/note_editor/widgets/read_only_bars.dart';
import 'package:sinan_note/services/storage/sqlite_database_service.dart';
import 'package:sinan_note/services/unified_notification_service.dart';
import 'package:sinan_note/services/version_control_service.dart';
import 'package:sinan_note/widgets/common/color_picker_sheet.dart';
import 'package:sinan_note/widgets/common/custom_share_sheet.dart';
import 'package:sinan_note/widgets/editor/reminder_picker_sheet.dart';
import 'package:sinan_note/widgets/home/note_card_utils.dart';

class NoteReadOnlyView extends StatefulWidget {
  final Note note;
  final NoteMode mode;
  final EditorCoordinator coordinator;
  final double sidePadding;
  final String? heroTag;
  final VoidCallback? onClose;
  final VoidCallback onEnterEdit;
  final void Function(NoteMode newMode, Note newNote)? onModeChanged;
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
    this.onModeChanged,
  });

  @override
  State<NoteReadOnlyView> createState() => _NoteReadOnlyViewState();
}

class _NoteReadOnlyViewState extends State<NoteReadOnlyView> {
  final _scrollController = ScrollController();
  bool _showMarkdown = false;
  late Note _currentNote;
  late NoteMode _currentMode;
  int _quillKey = 0;

  static const _bookModeMinLength = 600;

  static bool _looksLikeMarkdown(String text) => RegExp(
        r'(^#{1,6} |\*\*|__| *[-*+] | *\d+\. |^> |```|`[^`])',
        multiLine: true,
      ).hasMatch(text);

  @override
  void initState() {
    super.initState();
    _currentNote = widget.note;
    _currentMode = widget.mode;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _onConvert(String targetType) async {
    final noteId = _currentNote.id;
    if (noteId == null || !mounted) return;
    final l10n = AppLocalizations.of(context)!;

    final dbNote = await SqliteDatabaseService().getNoteById(noteId);
    if (dbNote == null || !mounted) return;

    String newContent = dbNote.content;
    if (targetType == 'checklist') {
      if (newContent.trimLeft().startsWith('[')) {
        try {
          final ops = jsonDecode(newContent) as List;
          newContent = ops
              .where((op) => op is Map && op['insert'] is String)
              .map((op) => op['insert'] as String)
              .join()
              .trimRight();
        } catch (_) {}
      }
      newContent =
          ChecklistFormatter.fromPlainText(newContent, title: dbNote.title);
    } else if (dbNote.isChecklist) {
      final plain = ChecklistFormatter.toPlainText(dbNote.content);
      if (targetType == 'code') {
        newContent = plain;
      } else {
        final qc = QuillMigration.controllerFromContent(plain);
        newContent = QuillMigration.toDeltaJson(qc);
        qc.dispose();
      }
    } else if (dbNote.isProfessional ||
        dbNote.noteType == 'code' ||
        dbNote.noteType == 'pro') {
      if (targetType == 'rich') {
        if (_looksLikeMarkdown(newContent)) {
          final mdDelta = MarkdownToDelta(
            markdownDocument: md.Document(encodeHtml: false),
          ).convert(newContent);
          final qc = QuillController(
            document: Document.fromDelta(mdDelta),
            selection: const TextSelection.collapsed(offset: 0),
          );
          newContent = QuillMigration.toDeltaJson(qc);
          qc.dispose();
        } else {
          final qc = QuillMigration.controllerFromContent(newContent);
          newContent = QuillMigration.toDeltaJson(qc);
          qc.dispose();
        }
      } else if (targetType == 'simple') {
        if (_looksLikeMarkdown(newContent)) {
          newContent = _stripMarkdown(newContent);
        }
      }
    } else if (dbNote.noteType == 'markdown') {
      if (targetType == 'rich') {
        final mdDelta = MarkdownToDelta(
          markdownDocument: md.Document(encodeHtml: false),
        ).convert(newContent);
        final qc = QuillController(
          document: Document.fromDelta(mdDelta),
          selection: const TextSelection.collapsed(offset: 0),
        );
        newContent = QuillMigration.toDeltaJson(qc);
        qc.dispose();
      } else if (targetType == 'simple' || targetType == 'code') {
        newContent = _stripMarkdown(newContent);
      }
    } else if (newContent.trimLeft().startsWith('[')) {
      if (targetType == 'code' || targetType == 'simple') {
        try {
          final ops = jsonDecode(newContent) as List;
          newContent = ops
              .where((op) => op is Map && op['insert'] is String)
              .map((op) => op['insert'] as String)
              .join()
              .replaceAll(RegExp(r'\n+$'), '');
        } catch (_) {}
      }
    } else {
      if (targetType == 'rich') {
        final qc = QuillMigration.controllerFromContent(newContent);
        newContent = QuillMigration.toDeltaJson(qc);
        qc.dispose();
      }
    }

    await VersionControlService().smartLogVersion(
      noteId: noteId,
      title: dbNote.title,
      content: dbNote.content,
      isManualAction: true,
      noteType: dbNote.noteType,
      forceLog: true,
    );

    if (!mounted) return;
    final provider = Provider.of<NotesProvider>(context, listen: false);
    await provider.convertNoteType(
      noteId,
      newContent: newContent,
      newNoteType: targetType,
      isChecklist: targetType == 'checklist',
    );

    final updated = await SqliteDatabaseService().getNoteById(noteId);
    if (updated == null || !mounted) return;

    widget.coordinator.contentController.text = updated.content;
    final newMode = NoteCardUtils.getNoteMode(updated);

    if (newMode == NoteMode.code) {
      widget.coordinator.codeController?.dispose();
      widget.coordinator.codeController = CodeController(text: updated.content);
      widget.coordinator.quillController?.dispose();
      widget.coordinator.quillController = null;
    } else {
      final newQc = QuillMigration.controllerFromContent(updated.content);
      widget.coordinator.quillController?.dispose();
      widget.coordinator.quillController = newQc;
      widget.coordinator.quillControllerVersion++;
    }

    widget.coordinator.stateManager.loadFromNote(
      noteContent: updated.content,
      noteTitle: updated.title.isNotEmpty ? updated.title : null,
      noteColorIndex: updated.colorIndex,
      noteReminderDateTime: updated.reminderDateTime,
      noteRecurrenceRule: updated.recurrenceRule,
      noteCategoryIds: updated.categoryIds,
      noteIsHiddenFromHome: updated.isHiddenFromHome,
      isChecklist: updated.isChecklist,
    );
    widget.coordinator.savedNoteId = updated.id;

    setState(() {
      _currentNote = updated;
      _currentMode = newMode;
      _quillKey++;
    });
    widget.onModeChanged?.call(_currentMode, _currentNote);

    UnifiedNotificationService().show(
      context: context,
      message: l10n.noteConverted,
      type: NotificationType.success,
    );
  }

  static String _stripMarkdown(String text) => text
      .replaceAll(RegExp(r'^#{1,6} ', multiLine: true), '')
      .replaceAll(RegExp(r'\*\*(.+?)\*\*'), r'$1')
      .replaceAll(RegExp(r'__(.+?)__'), r'$1')
      .replaceAll(RegExp(r'\*(.+?)\*'), r'$1')
      .replaceAll(RegExp(r'_(.+?)_'), r'$1')
      .replaceAll(RegExp(r'~~(.+?)~~'), r'$1')
      .replaceAll(RegExp(r'`(.+?)`'), r'$1')
      .replaceAll(RegExp(r'^ *[-*+] ', multiLine: true), '')
      .replaceAll(RegExp(r'^ *\d+\. ', multiLine: true), '')
      .replaceAll(RegExp(r'^> ', multiLine: true), '')
      .replaceAll(RegExp(r'```[\s\S]*?```'), '')
      .trim();

  void _closeOrPop() {
    if (widget.onClose != null) {
      widget.onClose!();
    } else if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context, true);
    }
  }

  void _openBookMode() {
    final note = _currentNote;
    final noteColor = widget.coordinator.getBackgroundColor(context);
    final textColor =
        noteColor.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;

    // نمرر Delta JSON للحفاظ على التنسيق في وضع القراءة
    final String? deltaJson;
    if (widget.coordinator.quillController != null) {
      deltaJson =
          QuillMigration.toDeltaJson(widget.coordinator.quillController!);
    } else {
      final raw = widget.coordinator.contentController.text;
      deltaJson = QuillMigration.isDelta(raw) ? raw : null;
    }

    final String plainContent;
    if (widget.coordinator.quillController != null) {
      plainContent = widget.coordinator.quillController!.document.toPlainText();
    } else if (_currentMode == NoteMode.code) {
      plainContent = widget.coordinator.codeController?.text ??
          widget.coordinator.contentController.text;
    } else {
      plainContent = NoteContentUtils.toDisplayText(
          widget.coordinator.contentController.text);
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookModeView(
          noteId: note.id!,
          textColor: textColor,
          noteColor: noteColor,
          plainContent: plainContent,
          deltaJson: deltaJson,
          isMarkdown: note.noteType == 'markdown',
        ),
      ),
    );
  }

  Future<void> _removeReminder() async {
    if (_currentNote.id == null) return;
    final provider = Provider.of<NotesProvider>(context, listen: false);
    final updated = _currentNote.copyWith(reminderDateTime: null);
    await provider.updateNote(updated);
    if (!mounted) return;
    setState(() => _currentNote = updated);
  }

  Future<void> _onReminder() async {
    final note = _currentNote;
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
    final note = _currentNote;
    final l10n = AppLocalizations.of(context)!;
    final content = note.isChecklist
        ? ChecklistFormatter.formatForSharing(note.title, note.content)
        : '${note.title}\n\n${NoteCardUtils.fixNoteContent(note.content, maxChars: null)}';
    CustomShareSheet.show(
      context,
      content,
      subject: note.title,
      note: note,
      onNoteCopied: () async {
        if (note.id == null || !mounted) return;
        final provider = Provider.of<NotesProvider>(context, listen: false);
        await provider.duplicateNote(note.id!, copyLabel: l10n.noteCopy);
        if (!mounted) return;
        UnifiedNotificationService().show(
          context: context,
          message: l10n.noteDuplicated,
          type: NotificationType.success,
          duration: const Duration(seconds: 2),
        );
      },
    );
  }

  Future<void> _onArchive() async {
    if (_currentNote.id == null || !mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final provider = Provider.of<NotesProvider>(context, listen: false);
    final note = _currentNote;
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
    if (_currentNote.id == null || !mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final provider = Provider.of<NotesProvider>(context, listen: false);
    final note = _currentNote;

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
    if (_currentNote.id == null) return;
    final l10n = AppLocalizations.of(context)!;
    final provider = Provider.of<NotesProvider>(context, listen: false);
    final note = _currentNote;
    note.isTrashed
        ? await provider.restoreNote(note.id!)
        : await provider.unarchiveNote(note.id!);
    if (!mounted) return;
    _closeOrPop();
    UnifiedNotificationService().showWithUndo(
      context: context,
      message: l10n.noteRestored,
      type: NotificationType.success,
      actionKey: 'note_restore_${note.id}',
      onExecute: () {},
      onUndo: () async => await provider.trashNote(note.id!),
      undoLabel: l10n.undo,
    );
  }

  Future<void> _onPermanentDelete() async {
    if (_currentNote.id == null || !mounted) return;
    await Provider.of<NotesProvider>(context, listen: false)
        .deleteNote(_currentNote.id!);
    if (mounted) _closeOrPop();
  }

  Future<void> _onColorChange() async {
    final selectedIndex = await ColorPickerSheet.show(
      context,
      currentIndex: widget.coordinator.stateManager.colorIndex,
    );
    if (selectedIndex == null || !mounted) return;
    widget.coordinator.stateManager.colorIndex = selectedIndex;
    widget.coordinator.stateManager.markDirty();
    final provider = Provider.of<NotesProvider>(context, listen: false);
    final updated = _currentNote.copyWith(colorIndex: selectedIndex);
    await provider.updateNote(updated);
    if (!mounted) return;
    setState(() => _currentNote = updated);
  }

  Future<void> _onRefresh() async {
    if (_currentNote.id == null) return;
    final provider = Provider.of<NotesProvider>(context, listen: false);
    await provider.refreshAllNotes();
    if (!mounted) return;
    final updated = provider.activeNotes
        .cast<Note?>()
        .firstWhere((n) => n?.id == _currentNote.id, orElse: () => null);
    if (updated != null) {
      setState(() {
        _currentNote = updated;
        widget.coordinator.stateManager.colorIndex = updated.colorIndex;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final note = _currentNote;
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

    final isChecklist = _currentMode == NoteMode.checklist;
    final isMarkdown = _showMarkdown;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    final noteCard = Container(
      width: double.infinity,
      height: isMarkdown ? null : double.infinity,
      margin: isLandscape
          ? const EdgeInsets.only(top: 4, bottom: 4)
          : const EdgeInsets.only(top: 8, bottom: 8),
      padding: isChecklist
          ? EdgeInsets.fromLTRB(12, isLandscape ? 8 : 16, 12, 8)
          : isMarkdown
              ? const EdgeInsets.symmetric(horizontal: 12, vertical: 12)
              : const EdgeInsets.fromLTRB(12, 2, 12, 2),
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
      child: ReadOnlyContent(
        mode: _currentMode,
        coordinator: widget.coordinator,
        textColor: textColor,
        noteColor: noteColor,
        scrollController: _scrollController,
        showMarkdown: _showMarkdown,
        isTrashed: _currentNote.isTrashed,
        quillKey: _quillKey,
        onSave: widget.onSave,
        reminderDateTime:
            _currentNote.isTrashed ? null : _currentNote.reminderDateTime,
        onRemoveReminder: _currentNote.isTrashed ? null : _removeReminder,
        onEditReminder: _currentNote.isTrashed ? null : _onReminder,
      ),
    );

    final heroTag = widget.heroTag ?? 'note_card_${note.id}';
    final heroEnabled = Provider.of<SettingsProvider>(context, listen: true)
        .heroAnimationEnabled;
    final heroCard = heroEnabled
        ? Hero(
            tag: heroTag,
            transitionOnUserGestures: false,
            createRectTween: (begin, end) =>
                MaterialRectArcTween(begin: begin, end: end),
            placeholderBuilder: (context, heroSize, child) => SizedBox(
              width: heroSize.width,
              height: heroSize.height,
            ),
            flightShuttleBuilder: (_, animation, direction, fromCtx, toCtx) {
              final curved = CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
                reverseCurve: Curves.easeInCubic,
              );
              return AnimatedBuilder(
                animation: curved,
                builder: (context, _) {
                  final radius = BorderRadius.circular(
                    direction == HeroFlightDirection.push
                        ? lerpDouble(16, 0, curved.value)!
                        : lerpDouble(0, 16, curved.value)!,
                  );
                  return Material(
                    color: Colors.transparent,
                    child: ClipRRect(
                      borderRadius: radius,
                      child: noteCard,
                    ),
                  );
                },
              );
            },
            child: noteCard,
          )
        : noteCard;

    final canMarkdown = _currentNote.noteType == 'markdown';

    // زر وضع القراءة — يظهر فقط إذا المحتوى > 600 حرف وليس checklist أو code
    final contentForLength = widget.coordinator.codeController?.text ??
        widget.coordinator.contentController.text;
    final canBookMode = _currentMode != NoteMode.checklist &&
        _currentMode != NoteMode.code &&
        contentForLength.length >= _bookModeMinLength &&
        _currentNote.id != null;

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
        onReadingMode: canBookMode ? _openBookMode : null,
      ),
      body: Builder(builder: (ctx) {
        final canDoubleTap = !note.isTrashed &&
            Provider.of<SettingsProvider>(ctx, listen: false).doubleTapToEdit;
        final inner = GestureDetector(
          onDoubleTap: canDoubleTap ? widget.onEnterEdit : null,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: widget.sidePadding),
            child: heroCard,
          ),
        );
        final content = isMarkdown
            ? Scrollbar(
                controller: _scrollController,
                thumbVisibility: true,
                thickness: 4,
                radius: const Radius.circular(4),
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: inner,
                ),
              )
            : inner;

        if (!note.isTrashed) return content;

        return Stack(
          children: [
            Padding(
              padding: EdgeInsets.only(
                  bottom: 56.0 + MediaQuery.of(context).padding.bottom),
              child: content,
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: TrashFloatingSheet(
                fadeAnimation: barsFade,
                onRestore: _onRestore,
                onPermanentDelete: _onPermanentDelete,
              ),
            ),
          ],
        );
      }),
      bottomNavigationBar: note.isTrashed
          ? null
          : ReadOnlyBars.buildActionBar(
              context: context,
              note: note,
              barColor: appBarColor,
              fadeAnimation: barsFade,
              onShare: _onShare,
              onArchive: _onArchive,
              onDelete: _onDelete,
              onEdit: widget.onEnterEdit,
              onColorChange: _onColorChange,
              onConvert: (targetType) => _onConvert(targetType),
              currentNoteType:
                  _currentNote.isProfessional ? 'code' : _currentNote.noteType,
              isChecklist: _currentNote.isChecklist,
            ),
    );
  }
}
