// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:convert';

import 'package:apex_note/controllers/notes/notes_provider.dart';
import 'package:apex_note/controllers/settings/settings_provider.dart';
import 'package:apex_note/core/constants/app_text_styles.dart';
import 'package:apex_note/core/theme/app_theme.dart';
import 'package:apex_note/core/utils/checklist_formatter.dart';
import 'package:apex_note/core/utils/quill_migration.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:apex_note/models/note.dart';
import 'package:apex_note/models/note_mode.dart';
import 'package:apex_note/screens/shared/note_editor/core/editor_coordinator.dart';
import 'package:apex_note/screens/shared/note_editor/view/readonly_checklist_view.dart';
import 'package:apex_note/screens/shared/note_editor/widgets/read_only_bars.dart';
import 'package:apex_note/services/storage/sqlite_database_service.dart';
import 'package:apex_note/services/unified_notification_service.dart';
import 'package:apex_note/services/version_control_service.dart';
import 'package:apex_note/widgets/common/custom_share_sheet.dart';
import 'package:apex_note/widgets/editor/markdown_viewer.dart';
import 'package:apex_note/widgets/editor/reminder_picker_sheet.dart';
import 'package:apex_note/widgets/home/note_card_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:provider/provider.dart';

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
        // إذا كان المحتوى Markdown — حوّله منسقاً
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
        // إذا كان Markdown — أزل الرموز
        if (_looksLikeMarkdown(newContent)) {
          newContent = newContent
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
        }
        // نص عادي → simple: يبقى كما هو
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
        newContent = newContent
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
      }
    } else if (newContent.trimLeft().startsWith('[')) {
      if (targetType == 'code') {
        try {
          final ops = jsonDecode(newContent) as List;
          newContent = ops
              .where((op) => op is Map && op['insert'] is String)
              .map((op) => op['insert'] as String)
              .join()
              .replaceAll(RegExp(r'\n+$'), '');
        } catch (_) {}
      } else if (targetType == 'simple') {
        try {
          final ops = jsonDecode(newContent) as List;
          newContent = ops
              .where((op) => op is Map && op['insert'] is String)
              .map((op) => op['insert'] as String)
              .join()
              .replaceAll(RegExp(r'\n+$'), '');
        } catch (_) {}
      }
      // Delta JSON → rich: يبقى كما هو
    } else {
      // نص عادي → rich
      if (targetType == 'rich') {
        final qc = QuillMigration.controllerFromContent(newContent);
        newContent = QuillMigration.toDeltaJson(qc);
        qc.dispose();
      }
      // نص عادي → code/simple: يبقى كما هو
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

    // تحديث coordinator بالمحتوى الجديد
    widget.coordinator.contentController.text = updated.content;

    final newMode = NoteCardUtils.getNoteMode(updated);

    if (newMode == NoteMode.code) {
      // تحويل إلى كود — أنشئ codeController جديد
      widget.coordinator.codeController?.dispose();
      widget.coordinator.codeController = CodeController(text: updated.content);
      widget.coordinator.quillController?.dispose();
      widget.coordinator.quillController = null;
    } else {
      // تحويل من كود أو إلى rich/simple — أنشئ quillController جديد
      final newQc = QuillMigration.controllerFromContent(updated.content);
      widget.coordinator.quillController?.dispose();
      widget.coordinator.quillController = newQc;
      widget.coordinator.quillControllerVersion++;
    }

    // إعادة تهيئة stateManager بالمحتوى الجديد حتى يعمل hasChanges() بشكل صحيح
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

  void _closeOrPop() {
    if (widget.onClose != null) {
      widget.onClose!();
    } else if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context, true);
    }
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
    final content = note.isChecklist
        ? ChecklistFormatter.formatForSharing(note.title, note.content)
        : '${note.title}\n\n${NoteCardUtils.fixNoteContent(note.content, maxChars: note.content.length)}';
    CustomShareSheet.show(context, content, subject: note.title, note: note);
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

  Future<void> _onRefresh() async {
    if (_currentNote.id == null) return;
    final provider = Provider.of<NotesProvider>(context, listen: false);
    await provider.refreshAllNotes();
    if (!mounted) return;
    final updated = provider.activeNotes
        .cast<Note?>()
        .firstWhere((n) => n?.id == _currentNote.id, orElse: () => null);
    if (updated != null) {
      setState(() =>
          widget.coordinator.stateManager.colorIndex = updated.colorIndex);
    }
  }

  Widget _buildContent(Color textColor, Color noteColor) {
    if (_currentMode == NoteMode.checklist) {
      return ReadOnlyChecklistView(
        coordinator: widget.coordinator,
        textColor: textColor,
        noteColor: noteColor,
        scrollController: _scrollController,
        onSave: widget.onSave,
        isTrashed: _currentNote.isTrashed,
      );
    }

    // Markdown preview — يجب أن يكون قبل Code
    if (_showMarkdown) {
      final content = widget.coordinator.codeController?.text ??
          widget.coordinator.contentController.text;
      return Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 80),
        child: MarkdownViewer(
          content: content,
          textColor: textColor,
        ),
      );
    }

    // Code
    if (_currentMode == NoteMode.code) {
      final content = widget.coordinator.codeController?.text ??
          widget.coordinator.contentController.text;
      return ScrollbarTheme(
        data: const ScrollbarThemeData(thickness: WidgetStatePropertyAll(0)),
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 80),
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
            key: ValueKey(_quillKey),
            controller: qc,
            focusNode: widget.coordinator.textFieldFocusNode,
            scrollController: ScrollController(),
            config: QuillEditorConfig(
              unknownEmbedBuilder: _unknownEmbedBuilder,
              autoFocus: false,
              expands: true,
              scrollable: true,
              padding: const EdgeInsets.only(top: 20, bottom: 40),
              showCursor: false,
              enableInteractiveSelection: false,
              checkBoxReadOnly: true,
              // ignore: experimental_member_use
              customLeadingBlockBuilder: (node, config) =>
                  _buildCheckboxLeading(config, textColor),
              customStyles: DefaultStyles(
                leading: DefaultTextBlockStyle(
                  TextStyle(
                    fontSize: AppFontSize.noteBody,
                    fontFamily: fontFamily,
                    height: AppLineHeight.body(
                      Provider.of<SettingsProvider>(context, listen: false)
                          .textScaleFactor,
                      fontFamily,
                    ),
                    color: textColor,
                  ),
                  HorizontalSpacing.zero,
                  VerticalSpacing.zero,
                  VerticalSpacing.zero,
                  null,
                ),
                lists: DefaultListBlockStyle(
                  TextStyle(
                    fontSize: AppFontSize.noteBody,
                    fontFamily: fontFamily,
                    height: AppLineHeight.body(
                      Provider.of<SettingsProvider>(context, listen: false)
                          .textScaleFactor,
                      fontFamily,
                    ),
                    color: textColor,
                  ),
                  HorizontalSpacing.zero,
                  VerticalSpacing.zero,
                  VerticalSpacing.zero,
                  null,
                  null,
                ),
                paragraph: DefaultTextBlockStyle(
                  TextStyle(
                    fontSize: AppFontSize.noteBody,
                    fontFamily: fontFamily,
                    height: AppLineHeight.body(
                      Provider.of<SettingsProvider>(context, listen: false)
                          .textScaleFactor,
                      fontFamily,
                    ),
                    color: textColor,
                  ),
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

  /// Checkbox بألوان النوتة — نفس شكل المحرر
  Widget? _buildCheckboxLeading(LeadingConfig config, Color textColor) {
    final isCheck = config.attribute == Attribute.checked ||
        config.attribute == Attribute.unchecked;
    if (!isCheck) return null;

    final isChecked = config.value;
    final size = config.lineSize ?? 16.0;

    return Container(
      alignment: AlignmentDirectional.centerEnd,
      padding: EdgeInsetsDirectional.only(end: size / 2),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isChecked ? Colors.green : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isChecked ? Colors.green : textColor.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        child: isChecked
            ? Icon(Icons.check, size: size * 0.75, color: Colors.white)
            : null,
      ),
    );
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

    final canMarkdown = _currentNote.noteType == 'markdown';

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

        // للسلة: Stack مع sheet عائم في الأسفل
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
              child: _TrashFloatingSheet(
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
              onConvert: (targetType) => _onConvert(targetType),
              currentNoteType:
                  _currentNote.isProfessional ? 'code' : _currentNote.noteType,
              isChecklist: _currentNote.isChecklist,
            ),
    );
  }
}

class _UnknownEmbedBuilder extends EmbedBuilder {
  const _UnknownEmbedBuilder();
  @override
  String get key => '__unknown__';
  @override
  Widget build(BuildContext context, EmbedContext embedContext) =>
      const SizedBox.shrink();
}

const _unknownEmbedBuilder = _UnknownEmbedBuilder();

/// Sheet عائم في الأسفل — يبدأ بـ handle فقط ويتمدد عند السحب
class _TrashFloatingSheet extends StatefulWidget {
  final Animation<double> fadeAnimation;
  final VoidCallback onRestore;
  final VoidCallback onPermanentDelete;

  const _TrashFloatingSheet({
    required this.fadeAnimation,
    required this.onRestore,
    required this.onPermanentDelete,
  });

  @override
  State<_TrashFloatingSheet> createState() => _TrashFloatingSheetState();
}

class _TrashFloatingSheetState extends State<_TrashFloatingSheet>
    with SingleTickerProviderStateMixin {
  static const double _peekH = 56.0;
  static const double _fullH =
      56.0 + 56.0 + 1.0 + 56.0 + 16.0; // handle + 2 tiles + divider + pad

  late final AnimationController _anim;
  late final Animation<double> _heightAnim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _heightAnim = Tween<double>(begin: _peekH, end: _fullH).animate(
      CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails d) {
    // سحب للأعلى = delta سالب → نزيد الـ animation
    final delta = -d.primaryDelta! / (_fullH - _peekH);
    _anim.value = (_anim.value + delta).clamp(0.0, 1.0);
  }

  void _onDragEnd(DragEndDetails d) {
    // snap: إذا > 50% أو velocity سريع → افتح، وإلا أغلق
    if (d.primaryVelocity != null && d.primaryVelocity! < -300) {
      _anim.forward();
    } else if (d.primaryVelocity != null && d.primaryVelocity! > 300) {
      _anim.reverse();
    } else if (_anim.value > 0.5) {
      _anim.forward();
    } else {
      _anim.reverse();
    }
  }

  void _toggle() {
    if (_anim.value > 0.5) {
      _anim.reverse();
    } else {
      _anim.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return FadeTransition(
      opacity: widget.fadeAnimation,
      child: AnimatedBuilder(
        animation: _heightAnim,
        builder: (context, _) {
          final height = _heightAnim.value + bottomPad;
          final openRatio = _anim.value;

          return GestureDetector(
            onVerticalDragUpdate: _onDragUpdate,
            onVerticalDragEnd: _onDragEnd,
            onTap: _toggle,
            child: Container(
              height: height,
              decoration: BoxDecoration(
                color: isDark ? scheme.surfaceContainerLow : scheme.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Handle ──────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: scheme.onSurface.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          Localizations.localeOf(context).languageCode == 'ar'
                              ? 'اسحب للأعلى'
                              : 'Swipe up',
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // ── أزرار بـ fade ────────────────────────────
                  Expanded(
                    child: Opacity(
                      opacity: openRatio,
                      child: IgnorePointer(
                        ignoring: openRatio < 0.5,
                        child: ListView(
                          padding: EdgeInsets.zero,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.restore_rounded,
                                    color: Colors.green, size: 22),
                              ),
                              title: Text(l10n.restore,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              onTap: widget.onRestore,
                            ),
                            const Divider(height: 1, indent: 16, endIndent: 16),
                            ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.delete_forever_rounded,
                                    color: Colors.red, size: 22),
                              ),
                              title: Text(
                                l10n.permanentDelete,
                                style: const TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.w600),
                              ),
                              onTap: widget.onPermanentDelete,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
