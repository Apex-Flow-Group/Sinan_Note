// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:convert';

import 'package:apex_note/controllers/notes/notes_provider.dart';
import 'package:apex_note/controllers/settings/settings_provider.dart';
import 'package:apex_note/core/theme/app_theme.dart';
import 'package:apex_note/core/utils/checklist_formatter.dart';
import 'package:apex_note/core/utils/note_content_utils.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:apex_note/models/note.dart';
import 'package:apex_note/models/note_mode.dart';
import 'package:apex_note/screens/shared/note_editor/core/editor_coordinator.dart';
import 'package:apex_note/screens/shared/note_editor/widgets/read_only_bars.dart';
import 'package:apex_note/widgets/common/custom_share_sheet.dart';
import 'package:apex_note/widgets/editor/markdown_viewer.dart';
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

  Future<void> _onShare() async {
    final note = widget.note;
    final content = note.isChecklist
        ? ChecklistFormatter.formatForSharing(note.title, note.content)
        : '${note.title}\n\n${NoteCardUtils.fixNoteContent(note.content, maxChars: note.content.length)}';
    CustomShareSheet.show(context, content, subject: note.title, note: note);
  }

  Future<void> _onArchive() async {
    if (widget.note.id == null) return;
    final provider = Provider.of<NotesProvider>(context, listen: false);
    widget.note.isArchived
        ? await provider.unarchiveNote(widget.note.id!)
        : await provider.archiveNote(widget.note.id!);
    if (mounted) _closeOrPop();
  }

  Future<void> _onDelete() async {
    if (widget.note.id == null || !mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteNote),
        content: Text(l10n.deleteConfirm),
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
          .trashNote(widget.note.id!);
      if (mounted) _closeOrPop();
    }
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
      return _ChecklistView(
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
              padding: EdgeInsets.zero,
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
          ? const EdgeInsets.fromLTRB(20, 20, 20, 12)
          : const EdgeInsets.all(20),
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

// ── Checklist — بدون ReorderableListView لتجنب scrollbar الداخلي ──────────────

class _ChecklistView extends StatefulWidget {
  final EditorCoordinator coordinator;
  final Color textColor;
  final Color noteColor;
  final ScrollController scrollController;
  final Future<void> Function({bool isManualSave}) onSave;

  const _ChecklistView({
    required this.coordinator,
    required this.textColor,
    required this.noteColor,
    required this.scrollController,
    required this.onSave,
  });

  @override
  State<_ChecklistView> createState() => _ChecklistViewState();
}

class _ChecklistViewState extends State<_ChecklistView> {
  void _save(List<ChecklistItem> updated) {
    // ── حافظ على العنوان الموجود في JSON عند الحفظ ──────────────────────
    // ChecklistFormatter.toJson() يكتب array فقط ويفقد العنوان
    // نقرأ العنوان الحالي من المحتوى أو من stateManager ونُعيد دمجه
    final currentContent = widget.coordinator.contentController.text;
    String existingTitle = '';
    try {
      final decoded = jsonDecode(currentContent);
      if (decoded is Map && decoded.containsKey('title')) {
        existingTitle = (decoded['title'] as String?) ?? '';
      }
    } catch (_) {}

    // إذا لم يكن في المحتوى، خذه من stateManager
    if (existingTitle.isEmpty) {
      existingTitle = widget.coordinator.stateManager.customTitle ??
          widget.coordinator.stateManager.checklistTitle ??
          '';
    }

    // أعد بناء JSON مع الحفاظ على العنوان
    final newJson = jsonEncode({
      'title': existingTitle,
      'items': updated.map((item) => item.toJson()).toList(),
    });

    widget.coordinator.contentController.text = newJson;
    widget.coordinator.stateManager.markDirty();
    widget.onSave(isManualSave: true);
  }

  @override
  Widget build(BuildContext context) {
    final items =
        ChecklistFormatter.parseJson(widget.coordinator.contentController.text);
    if (items.isEmpty) {
      return Text(widget.coordinator.contentController.text,
          style: TextStyle(fontSize: 16, color: widget.textColor));
    }

    final done = items.where((e) => e.isDone).length;
    final progress = done / items.length;

    return ScrollbarTheme(
      data: const ScrollbarThemeData(thickness: WidgetStatePropertyAll(0)),
      child: SingleChildScrollView(
        controller: widget.scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${(progress * 100).toInt()}%',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: widget.textColor.withValues(alpha: 0.7))),
                Text('$done / ${items.length}',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: widget.textColor.withValues(alpha: 0.7))),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: widget.textColor.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(
                    progress == 1.0 ? Colors.green : Colors.blue),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 12),
            ReorderableListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              proxyDecorator: (child, index, animation) {
                return Material(
                  color: Colors.transparent,
                  shadowColor: Colors.black26,
                  elevation: 10,
                  borderRadius: BorderRadius.circular(8),
                  child: ScaleTransition(
                    scale: CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOut,
                    ),
                    child: child,
                  ),
                );
              },
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex--;
                  final item = items.removeAt(oldIndex);
                  items.insert(newIndex, item);
                });
                _save(items);
              },
              children: items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return Padding(
                  key: ValueKey(item.id),
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      ReorderableDragStartListener(
                        index: index,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Icon(
                            Icons.drag_indicator,
                            size: 20,
                            color: widget.textColor.withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() => items[index].isDone = !item.isDone);
                          _save(items);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 12),
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color:
                                item.isDone ? Colors.green : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: item.isDone
                                  ? Colors.green
                                  : widget.textColor.withValues(alpha: 0.5),
                              width: 2,
                            ),
                          ),
                          child: item.isDone
                              ? const Icon(Icons.check,
                                  size: 16, color: Colors.white)
                              : null,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          item.text.isEmpty ? '...' : item.text,
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.5,
                            color: item.isDone
                                ? widget.textColor.withValues(alpha: 0.5)
                                : widget.textColor,
                            decoration: item.isDone
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Markdown — انتقل إلى lib/widgets/editor/markdown_viewer.dart ──────────────
