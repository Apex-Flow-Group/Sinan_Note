// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:async';

import 'package:apex_note/controllers/notes/notes_provider.dart';
import 'package:apex_note/core/theme/app_theme.dart';
import 'package:apex_note/core/utils/checklist_formatter.dart';
import 'package:apex_note/core/utils/quill_migration.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:apex_note/models/note.dart';
import 'package:apex_note/models/note_mode.dart';
import 'package:apex_note/screens/shared/note_editor/core/editor_build_methods.dart';
import 'package:apex_note/screens/shared/note_editor/core/editor_coordinator.dart';
import 'package:apex_note/screens/shared/note_editor/handlers/editor_dialog_handlers.dart';
import 'package:apex_note/screens/shared/note_editor/state/editor_save_manager.dart';
import 'package:apex_note/screens/shared/note_editor/widgets/read_only_bars.dart';
import 'package:apex_note/services/unified_notification_service.dart';
import 'package:apex_note/widgets/common/custom_share_sheet.dart';
import 'package:apex_note/widgets/home/note_card_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:provider/provider.dart';

// Import Core Components
// Import Handlers
// Import State Managers
/// Note Editor - Clean and Efficient
class NoteEditorImmersive extends StatefulWidget {
  final Note? note;
  final NoteMode mode;
  final bool skipAuthentication;
  final bool originallyLocked;
  final VoidCallback? onClose;
  final bool readOnly;
  final String? heroTag;

  const NoteEditorImmersive({
    super.key,
    this.note,
    this.mode = NoteMode.simple,
    this.skipAuthentication = false,
    this.originallyLocked = false,
    this.onClose,
    this.readOnly = false,
    this.heroTag,
  });

  @override
  State<NoteEditorImmersive> createState() => _NoteEditorImmersiveState();
}

class _NoteEditorImmersiveState extends State<NoteEditorImmersive>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  late EditorCoordinator _coordinator;
  AppLocalizations? _l10nRef;
  StreamSubscription? _quillChangesSubscription;
  late bool _isReadOnly;

  @override
  bool get wantKeepAlive => true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _l10nRef = AppLocalizations.of(context);
    _coordinator.updateFontSize(context);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _coordinator = EditorCoordinator(
      note: widget.note,
      mode: widget.mode,
      skipAuthentication: widget.skipAuthentication,
      originallyLocked: widget.originallyLocked,
    );

    _coordinator.initialize(context);
    _isReadOnly = widget.readOnly;

    // Rebuild after init so detectedLanguage is reflected in toolbar
    if (widget.mode == NoteMode.code && widget.note != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    }

    // Add listeners
    _coordinator.contentController.addListener(_onContentChanged);
    _coordinator.undoController.addListener(_updateUndoRedoState);

    if (widget.mode == NoteMode.code) {
      _coordinator.codeController!.addListener(_onContentChanged);
      _coordinator.codeUndoController.addListener(_updateUndoRedoState);
    }

    if (widget.mode == NoteMode.simple ||
        widget.mode == NoteMode.reminder ||
        widget.mode == NoteMode.rich) {
      _quillChangesSubscription =
          _coordinator.quillController!.document.changes.listen((_) {
        _onQuillContentChanged();
        _updateUndoRedoState();
      });
    }

    _updateUndoRedoState();

    // Show reminder dialog for new reminder notes
    if (widget.mode == NoteMode.reminder && widget.note == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showReminderDialog();
      });
    }

    // Handle locked notes
    if (widget.note != null &&
        widget.note!.isLocked &&
        !widget.skipAuthentication &&
        !widget.note!.isChecklist) {
      _promptForPassword();
    } else if (widget.note != null &&
        widget.note!.isLocked &&
        widget.skipAuthentication &&
        !widget.note!.isChecklist) {
      _loadDecryptedContent();
    }
  }

  @override
  void dispose() {
    _quillChangesSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _coordinator.dispose();
    super.dispose();
  }

  // ==================== DIALOG METHODS ====================

  void _showReminderDialog() async {
    if (!mounted) return;
    await EditorDialogHandlers.showReminderDialog(
      context: context,
      stateManager: _coordinator.stateManager,
      backgroundColor: _coordinator.getBackgroundColor(context),
      note: widget.note,
      saveCallback: ({bool isManualSave = false}) =>
          _saveNoteToDatabase(isManualSave: isManualSave),
    );
    if (mounted) setState(() {});
  }

  void _showColorPalette() async {
    if (!mounted) return;
    await EditorDialogHandlers.showColorPalette(
      context: context,
      stateManager: _coordinator.stateManager,
      mode: widget.mode,
      onColorSelected: (colorIndex, textColor) {
        if (mounted) {
          setState(() {
            _coordinator.textColor = textColor;
          });
        }
      },
    );
  }

  void _showHistorySheet() {
    EditorDialogHandlers.showHistorySheet(
      context: context,
      note: widget.note,
    );
  }

  void _showRenameTitleDialog() async {
    if (!mounted) return;
    final newTitle = await EditorDialogHandlers.showRenameTitleDialog(
      context: context,
      currentTitle: _coordinator.stateManager.customTitle ??
          _coordinator.getCurrentTitle(_l10nRef?.newNoteTitle ?? 'New Note'),
    );

    if (newTitle != null && newTitle.isNotEmpty && mounted) {
      setState(() {
        _coordinator.stateManager.customTitle = newTitle;
        _coordinator.stateManager.markDirty();
      });
    }
  }

  Future<void> _showSmartSaveDialog(String selectedExtension) async {
    if (!mounted) return;
    await EditorDialogHandlers.showSmartSaveDialog(
      context: context,
      selectedExtension: selectedExtension,
      detectedLanguage: _coordinator.detectedLanguage,
      smartController: _coordinator.smartController,
      backgroundColor: _coordinator.getBackgroundColor(context),
      textColor: _coordinator.textColor,
      saveAsMarkdown: _saveAsMarkdown,
      saveWithExtension: _saveWithExtension,
    );
  }

  // ==================== SAVE METHODS ====================

  Future<bool> _saveNoteToDatabase(
      {bool forceUpdate = false, bool isManualSave = false}) async {
    if (_coordinator.stateManager.isSaving) {
      return false;
    }

    final isNewLockedNote =
        (_coordinator.initialLockState || widget.note?.isLocked == true) &&
            widget.note?.id == null &&
            _coordinator.savedNoteId == null;

    if (!forceUpdate &&
        !isNewLockedNote &&
        (_coordinator.savedNoteId != null || widget.note != null)) {
      if (!_coordinator.stateManager.hasChanges()) {
        return false;
      }
    }

    _coordinator.stateManager.isSaving = true;

    try {
      String contentToSave = widget.mode == NoteMode.code
          ? _coordinator.codeController!.text
          : (widget.mode == NoteMode.checklist
              ? _coordinator.contentController.text
              : QuillMigration.toDeltaJson(_coordinator.quillController!));

      // Handle code note empty validation
      if (widget.mode == NoteMode.code) {
        if (contentToSave.trim().isEmpty && !isNewLockedNote) {
          _coordinator.stateManager.isSaving = false;
          return false;
        }
      }

      // Handle checklist validation
      if (widget.mode == NoteMode.checklist ||
          widget.note?.noteType == 'checklist') {
        contentToSave = EditorSaveManager.prepareChecklistContent(
          contentToSave,
          _l10nRef?.checklistItemHint ?? 'Task 1',
        );

        if (EditorSaveManager.isContentEmpty(
            contentToSave, NoteMode.checklist)) {
          _coordinator.stateManager.isSaving = false;
          return false;
        }
      }

      bool isContentEmpty = contentToSave.trim().isEmpty;

      if (isContentEmpty && !isNewLockedNote) {
        final noteId = _coordinator.savedNoteId ?? widget.note?.id;
        if (noteId != null) {
          await _coordinator.notesProviderRef!.trashNote(noteId);
        }
        _coordinator.stateManager.isSaving = false;
        return false;
      }

      String noteType = EditorSaveManager.determineNoteType(
        mode: widget.mode,
        detectedLanguage: _coordinator.detectedLanguage,
        isLanguageManuallySelected: _coordinator.isLanguageManuallySelected,
        existingNoteType: widget.note?.noteType,
        smartController: _coordinator.smartController,
      );

      final newId = await EditorSaveManager.saveNote(
        provider: _coordinator.notesProviderRef!,
        existingNote: widget.note,
        savedNoteId: _coordinator.savedNoteId,
        content: contentToSave,
        title:
            _coordinator.getCurrentTitle(_l10nRef?.newNoteTitle ?? 'New Note'),
        colorIndex: _coordinator.stateManager.colorIndex,
        initialLockState: _coordinator.initialLockState,
        noteType: noteType,
        isChecklist: widget.mode == NoteMode.checklist,
        reminderDateTime: _coordinator.stateManager.reminderDateTime,
        recurrenceRule: _coordinator.stateManager.recurrenceRule,
        categoryIds: _coordinator.stateManager.categoryIds,
        isHiddenFromHome: _coordinator.stateManager.isHiddenFromHome,
        mode: widget.mode,
        silent: !isManualSave,
        isAutoSave: !isManualSave, // FIXED: Pass auto-save flag
      );

      // REMOVED: Unnecessary loadNotes() that causes race condition
      // The provider already updates state via notifyListeners()

      if (_coordinator.savedNoteId == null) {
        if (mounted) setState(() => _coordinator.savedNoteId = newId);
      }

      if (isManualSave) {
        _coordinator.stateManager.updateSnapshot();
      }

      return true; // Successfully saved
    } catch (e) {
      // Ignore save errors
      return false;
    } finally {
      _coordinator.stateManager.isSaving = false;
    }
  }

  Future<void> _saveNote() async {
    _coordinator.autosaveTimer?.cancel();

    // Check if content is empty before saving
    final content = widget.mode == NoteMode.code
        ? _coordinator.codeController!.text
        : widget.mode == NoteMode.checklist
            ? _coordinator.contentController.text
            : QuillMigration.toPlainText(_coordinator.quillController!);
    final title = _coordinator.stateManager.customTitle ?? '';

    if (content.trim().isEmpty && title.trim().isEmpty) {
      // Don't save or show message for empty notes
      return;
    }

    final savedSuccessfully = await _saveNoteToDatabase(isManualSave: true);

    // Only show message if actually saved
    if (savedSuccessfully && mounted) {
      final l10n = AppLocalizations.of(context);
      UnifiedNotificationService().show(
        context: context,
        message: l10n!.noteSaved,
        type: NotificationType.success,
        duration: const Duration(seconds: 1),
      );
    }
  }

  Future<void> _saveAsMarkdown() async {
    if (!mounted) return;
    final content = widget.mode == NoteMode.code
        ? _coordinator.codeController!.text
        : _coordinator.contentController.text;

    await EditorSaveManager.saveAsMarkdown(
      context: context,
      provider: _coordinator.notesProviderRef!,
      existingNote: widget.note,
      savedNoteId: _coordinator.savedNoteId,
      content: content,
      title: _coordinator.getCurrentTitle(_l10nRef?.newNoteTitle ?? 'New Note'),
      colorIndex: _coordinator.stateManager.colorIndex,
      isLocked: _coordinator.initialLockState,
      reminderDateTime: _coordinator.stateManager.reminderDateTime,
      recurrenceRule: _coordinator.stateManager.recurrenceRule,
      mode: widget.mode,
    );

    _coordinator.stateManager.markClean();
  }

  Future<void> _saveWithExtension(String extension) async {
    if (!mounted) return;
    final content = widget.mode == NoteMode.code
        ? _coordinator.codeController!.text
        : _coordinator.contentController.text;

    await EditorSaveManager.saveWithExtension(
      context: context,
      provider: _coordinator.notesProviderRef!,
      existingNote: widget.note,
      savedNoteId: _coordinator.savedNoteId,
      content: content,
      title: _coordinator.getCurrentTitle(_l10nRef?.newNoteTitle ?? 'New Note'),
      colorIndex: _coordinator.stateManager.colorIndex,
      isLocked: _coordinator.initialLockState,
      reminderDateTime: _coordinator.stateManager.reminderDateTime,
      recurrenceRule: _coordinator.stateManager.recurrenceRule,
      mode: widget.mode,
      detectedLanguage: _coordinator.detectedLanguage,
      smartController: _coordinator.smartController,
    );

    _coordinator.stateManager.markClean();
  }

  // ==================== LIFECYCLE METHODS ====================

  void _onQuillContentChanged() {
    // لا نحفظ أثناء تحميل النوتة — تغييرات _fixDeltaDirections ليست من المستخدم
    if (_coordinator.stateManager.isLoading) return;
    _coordinator.stateManager.markDirty();
    final newHasContent =
        QuillMigration.toPlainText(_coordinator.quillController!)
            .trim()
            .isNotEmpty;
    if (_coordinator.stateManager.hasContent != newHasContent) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _coordinator.stateManager.hasContent = newHasContent);
        }
      });
    }
    _coordinator.autosaveTimer?.cancel();
    _coordinator.autosaveTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted && !_coordinator.stateManager.isSaving) {
        _saveNoteToDatabase();
      }
    });
  }

  void _onContentChanged() {
    _coordinator.stateManager.markDirty();

    final currentText = widget.mode == NoteMode.code
        ? _coordinator.codeController!.text
        : _coordinator.contentController.text;
    final newHasContent = currentText.trim().isNotEmpty;

    if (_coordinator.stateManager.hasContent != newHasContent) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _coordinator.stateManager.hasContent = newHasContent);
        }
      });
    }

    _coordinator.autosaveTimer?.cancel();
    _coordinator.autosaveTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted &&
          _coordinator.codeController!.text.trim().isNotEmpty &&
          !_coordinator.stateManager.isSaving) {
        _saveNoteToDatabase();
      }
    });
  }

  void _updateUndoRedoState() {
    if (widget.mode == NoteMode.checklist) return;

    if (widget.mode == NoteMode.code) {
      setState(() {
        _coordinator.stateManager.canUndo =
            _coordinator.codeUndoController.value.canUndo;
        _coordinator.stateManager.canRedo =
            _coordinator.codeUndoController.value.canRedo;
      });
    } else if (widget.mode == NoteMode.simple ||
        widget.mode == NoteMode.rich ||
        widget.mode == NoteMode.reminder) {
      final quill = _coordinator.quillController;
      if (quill == null) return;
      setState(() {
        _coordinator.stateManager.canUndo = quill.document.history.hasUndo;
        _coordinator.stateManager.canRedo = quill.document.history.hasRedo;
      });
    }
  }

  void _updateChecklistUndoRedo() {
    if (_coordinator.checklistUndoRedo != null && mounted) {
      _coordinator.stateManager.canUndo =
          _coordinator.checklistUndoRedo!.canUndo;
      _coordinator.stateManager.canRedo =
          _coordinator.checklistUndoRedo!.canRedo;
    }
  }

  Future<void> _promptForPassword() async {
    // Password prompt logic
  }

  Future<void> _loadDecryptedContent() async {
    // Decryption logic
  }

  Future<void> _handleBack() async {
    // وضع القراءة — اخرج مباشرة بدون حفظ أو رسالة
    if (_isReadOnly) {
      if (!mounted) return;
      if (widget.onClose != null) {
        widget.onClose!();
      } else {
        Navigator.of(context).pop(widget.note != null);
      }
      return;
    }

    final content = widget.mode == NoteMode.code
        ? _coordinator.codeController!.text
        : (widget.mode == NoteMode.checklist
            ? _coordinator.contentController.text
            : QuillMigration.toPlainText(_coordinator.quillController!));
    final title = _coordinator.stateManager.customTitle ??
        _coordinator.stateManager.checklistTitle ??
        '';

    final hasContent = content.trim().isNotEmpty || title.trim().isNotEmpty;
    final hasChanges = _coordinator.stateManager.hasChanges();
    final wasSaved = _coordinator.savedNoteId != null || widget.note != null;

    if (hasContent && hasChanges) {
      await _saveNoteToDatabase(isManualSave: true);
    }

    if (hasContent && wasSaved && mounted) {
      final l10n = AppLocalizations.of(context);
      UnifiedNotificationService().show(
        context: context,
        message: l10n!.noteSaved,
        type: NotificationType.success,
        duration: const Duration(seconds: 1),
      );
    }

    if (!mounted) return;
    if (widget.onClose != null) {
      widget.onClose!();
    } else {
      Navigator.of(context)
          .pop(_coordinator.savedNoteId != null || widget.note != null);
    }
  }

  // ==================== READ-ONLY CONTENT ====================

  Widget _buildReadOnlyChecklist(Color textColor, Color bgColor) {
    final content = _coordinator.contentController.text;
    final items = ChecklistFormatter.parseJson(content);
    if (items.isEmpty) {
      return Text(content, style: TextStyle(fontSize: 16, color: textColor));
    }

    // حساب التقدم
    final total = items.length;
    final done = items.where((e) => e.isDone).length;
    final progress = total > 0 ? done / total : 0.0;

    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        // شريط التقدم
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${(progress * 100).toInt()}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textColor.withValues(alpha: 0.7),
              ),
            ),
            Text(
              '$done / $total',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textColor.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: textColor.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(
              progress == 1.0 ? Colors.green : Colors.blue,
            ),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 12),
        // العناصر
        ...items.map((item) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(top: 2, right: 12),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: item.isDone ? Colors.green : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: item.isDone
                        ? Colors.green
                        : textColor.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: item.isDone
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
              Expanded(
                child: Text(
                  item.text.isEmpty ? '...' : item.text,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: item.isDone
                        ? textColor.withValues(alpha: 0.5)
                        : textColor,
                    decoration: item.isDone
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildReadOnlyContent(Color textColor) {
    final bgColor = _coordinator.getBackgroundColor(context);

    // checklist
    if (widget.mode == NoteMode.checklist) {
      return _buildReadOnlyChecklist(textColor, bgColor);
    }

    // code — نص monospace بدون أرقام أسطر
    if (widget.mode == NoteMode.code) {
      final content = _coordinator.codeController?.text ??
          _coordinator.contentController.text;
      return Directionality(
        textDirection: TextDirection.ltr,
        child: SelectableText(
          content,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 14,
            height: 1.6,
            color: textColor,
          ),
        ),
      );
    }

    // Quill (simple / rich / reminder)
    final qc = _coordinator.quillController;
    if (qc == null) return const SizedBox.shrink();
    final fontFamily = Theme.of(context).textTheme.bodyMedium?.fontFamily;
    qc.readOnly = true;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: DefaultTextStyle.merge(
        style: TextStyle(fontFamily: fontFamily),
        child: QuillEditor(
          controller: qc,
          focusNode: _coordinator.textFieldFocusNode,
          scrollController: ScrollController(),
          config: QuillEditorConfig(
            autoFocus: false,
            expands: false,
            scrollable: false,
            padding: EdgeInsets.zero,
            showCursor: false,
            enableInteractiveSelection: false,
            customStyles: DefaultStyles(
              paragraph: DefaultTextBlockStyle(
                TextStyle(
                  fontSize: 16,
                  fontFamily: fontFamily,
                  height: 1.6,
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
    );
  }

  // ==================== READ-ONLY ACTIONS ====================

  Future<void> _refreshCurrentNote() async {
    if (widget.note?.id == null) return;
    final provider = Provider.of<NotesProvider>(context, listen: false);
    await provider.refreshAllNotes();
    if (!mounted) return;
    final updated = provider.activeNotes
        .cast<Note?>()
        .firstWhere((n) => n?.id == widget.note!.id, orElse: () => null);
    if (updated != null) {
      setState(() => _coordinator.stateManager.colorIndex = updated.colorIndex);
    }
  }

  void _onReadOnlyShare() {
    final note = widget.note;
    if (note == null) return;
    final content = note.isChecklist
        ? ChecklistFormatter.formatForSharing(note.title, note.content)
        : '${note.title}\n\n${NoteCardUtils.fixNoteContent(note.content, maxChars: note.content.length)}';
    CustomShareSheet.show(context, content, subject: note.title, note: note);
  }

  Future<void> _onReadOnlyArchive() async {
    final note = widget.note;
    if (note?.id == null) return;
    final provider = Provider.of<NotesProvider>(context, listen: false);
    if (note!.isArchived) {
      await provider.unarchiveNote(note.id!);
    } else {
      await provider.archiveNote(note.id!);
    }
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Future<void> _onReadOnlyDelete() async {
    final note = widget.note;
    if (note?.id == null || !mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteNote),
        content: Text(l10n.deleteConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      final provider = Provider.of<NotesProvider>(context, listen: false);
      await provider.trashNote(note!.id!);
      if (!mounted) return;
      Navigator.pop(context, true);
    }
  }

  Future<void> _onReadOnlyRestore() async {
    final note = widget.note;
    if (note?.id == null) return;
    final provider = Provider.of<NotesProvider>(context, listen: false);
    if (note!.isTrashed) {
      await provider.restoreNote(note.id!);
    } else if (note.isArchived) {
      await provider.unarchiveNote(note.id!);
    }
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Future<void> _onReadOnlyPermanentDelete() async {
    final note = widget.note;
    if (note?.id == null || !mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.permanentDelete),
        content: Text(l10n.confirmPermanentDelete),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      final provider = Provider.of<NotesProvider>(context, listen: false);
      await provider.deleteNote(note!.id!);
      if (!mounted) return;
      Navigator.pop(context, true);
    }
  }

  // ==================== BUILD METHOD ====================

  Widget _buildScaffold(
    BuildContext context,
    Color statusColor,
    Brightness statusBrightness,
    Color finalTextColor,
    Color finalHintColor,
    double sidePadding,
    AppLocalizations l10n,
  ) {
    if (_isReadOnly && widget.note != null) {
      final note = widget.note!;
      final scheme = Theme.of(context).colorScheme;
      final barColor = Color.lerp(
        AppTheme.bg(scheme),
        scheme.surface,
        _coordinator.scrollProgress.value,
      )!;
      final bgColor = _coordinator.getBackgroundColor(context);
      final textColor = bgColor.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;

      // الأشرطة تظهر بـ fade بعد اكتمال انيميشن الـ Route
      final routeAnimation = ModalRoute.of(context)?.animation;
      final barsFade = routeAnimation == null
          ? const AlwaysStoppedAnimation(1.0)
          : CurvedAnimation(
              parent: routeAnimation,
              curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
            );

      // البطاقة — نفس شكل العارض القديم
      final isChecklist = widget.mode == NoteMode.checklist;
      final noteCard = Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 8, bottom: 16),
        padding: isChecklist
            ? const EdgeInsets.fromLTRB(20, 20, 20, 12)
            : const EdgeInsets.all(20),
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
        child: _buildReadOnlyContent(textColor),
      );

      // Hero يلف البطاقة فقط — لا الـ Scaffold
      final heroTag = widget.heroTag ?? 'note_card_${note.id}';
      final heroCard = Hero(
        tag: heroTag,
        transitionOnUserGestures: false,
        flightShuttleBuilder: (_, animation, direction, fromCtx, toCtx) =>
            FadeTransition(
              opacity: direction == HeroFlightDirection.push
                  ? animation
                  : ReverseAnimation(animation),
              child: Material(color: Colors.transparent, child: noteCard),
            ),
        child: noteCard,
      );

      return Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: ReadOnlyBars.buildTopBar(
          context: context,
          note: note,
          barColor: barColor,
          fadeAnimation: barsFade,
          onEdit: () => setState(() => _isReadOnly = false),
          onRefresh: _refreshCurrentNote,
        ),
        body: NotificationListener<ScrollNotification>(
          onNotification: (n) {
            final offset = n.metrics.pixels.clamp(0.0, 120.0);
            _coordinator.scrollProgress.value = offset / 120.0;
            return false;
          },
          child: SingleChildScrollView(
            controller: ScrollController(),
            padding: EdgeInsets.symmetric(horizontal: sidePadding),
            child: heroCard,
          ),
        ),
        bottomNavigationBar: note.isTrashed
            ? ReadOnlyBars.buildRestoreBar(
                context: context,
                barColor: barColor,
                fadeAnimation: barsFade,
                onRestore: _onReadOnlyRestore,
                onPermanentDelete: _onReadOnlyPermanentDelete,
              )
            : ReadOnlyBars.buildActionBar(
                context: context,
                note: note,
                barColor: barColor,
                fadeAnimation: barsFade,
                onShare: _onReadOnlyShare,
                onArchive: _onReadOnlyArchive,
                onDelete: _onReadOnlyDelete,
                onEdit: () => setState(() => _isReadOnly = false),
              ),
      );
    }

    // وضع التعديل — المحرر الكامل
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: _coordinator.getBackgroundColor(context),
      appBar: AppBar(
        toolbarHeight: 0,
        backgroundColor: statusColor,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: statusColor,
          statusBarIconBrightness: statusBrightness,
        ),
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          final offset = n.metrics.pixels.clamp(0.0, 120.0);
          _coordinator.scrollProgress.value = offset / 120.0;
          return false;
        },
        child: Stack(
          children: [
            EditorBuildMethods.buildContentArea(
              context: context,
              coordinator: _coordinator,
              sidePadding: sidePadding,
              finalTextColor: finalTextColor,
              finalHintColor: finalHintColor,
              mode: widget.mode,
              note: widget.note,
              savedNoteId: _coordinator.savedNoteId,
              onReminderTap: _showReminderDialog,
              saveCallback: ({bool isManualSave = false}) =>
                  _saveNoteToDatabase(isManualSave: isManualSave),
              onUndoRedoControllerCreated: (controller) {
                _coordinator.checklistUndoRedo = controller;
                _updateChecklistUndoRedo();
              },
              onUndoRedoChanged: _updateChecklistUndoRedo,
              onScroll: (progress) {
                _coordinator.scrollProgress.value = progress;
              },
              onChecklistTitleChanged: (title) {
                if (_coordinator.stateManager.checklistTitle != title) {
                  Future.microtask(() {
                    if (mounted) {
                      setState(() =>
                          _coordinator.stateManager.checklistTitle = title);
                    }
                  });
                }
              },
              readOnly: false,
            ),
            EditorBuildMethods.buildHeader(
              context: context,
              coordinator: _coordinator,
              finalTextColor: finalTextColor,
              currentTitle: _coordinator.getCurrentTitle(l10n.newNoteTitle),
              note: widget.note,
              notePassword: _coordinator.notePassword,
              onReminderTap: _showReminderDialog,
              onHistoryTap: _showHistorySheet,
              onTitleTap: _showRenameTitleDialog,
              onBackTap: _handleBack,
              onCategoryChanged: (ids) {
                setState(() => _coordinator.stateManager.categoryIds = ids);
                _coordinator.stateManager.markDirty();
              },
              originallyLocked: widget.originallyLocked,
              scrollProgress: _coordinator.scrollProgress,
              isReadOnly: false,
              onSaveTap: () async {
                if (widget.mode == NoteMode.code &&
                    _coordinator.detectedLanguage != null) {
                  final ext = _coordinator.smartController
                      .getExtensionForLanguage(_coordinator.detectedLanguage!);
                  await _showSmartSaveDialog(ext);
                } else {
                  await _saveNote();
                }
                if (context.mounted) {
                  if (widget.onClose != null) {
                    widget.onClose!();
                  } else {
                    Navigator.pop(context,
                        _coordinator.savedNoteId != null || widget.note != null);
                  }
                }
              },
            ),
            EditorBuildMethods.buildToolbar(
              context: context,
              coordinator: _coordinator,
              finalTextColor: finalTextColor,
              mode: widget.mode,
              note: widget.note,
              savedNoteId: _coordinator.savedNoteId,
              smartController: _coordinator.smartController,
              formattingController: _coordinator.formattingController,
              onReminderTap: _showReminderDialog,
              onColorPaletteTap: _showColorPalette,
              onRebuild: () { if (mounted) setState(() {}); },
              onSmartSaveDialog: () async {
                if (_coordinator.detectedLanguage != null) {
                  final ext = _coordinator.smartController
                      .getExtensionForLanguage(_coordinator.detectedLanguage!);
                  await _showSmartSaveDialog(ext);
                }
              },
              saveNote: _saveNote,
              scrollProgress: _coordinator.scrollProgress,
              onInsertSymbol: (symbol) {
                final ctrl = _coordinator.codeController;
                if (ctrl == null) return;
                final sel = ctrl.selection;
                final text = ctrl.text;
                if (sel.isValid && !sel.isCollapsed) {
                  ctrl.text = text.replaceRange(sel.start, sel.end, symbol);
                } else if (sel.isValid) {
                  final pos = sel.baseOffset;
                  final newText = text.substring(0, pos) + symbol + text.substring(pos);
                  ctrl.value = ctrl.value.copyWith(
                    text: newText,
                    selection: TextSelection.collapsed(offset: pos + symbol.length ~/ 2),
                  );
                } else {
                  ctrl.text = text + symbol;
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final l10n = AppLocalizations.of(context)!;
    final isDarkBg =
        _coordinator.getBackgroundColor(context).computeLuminance() < 0.5;
    final finalTextColor = isDarkBg ? Colors.white : Colors.black87;
    final finalHintColor = isDarkBg ? Colors.white54 : Colors.black45;
    final screenWidth = MediaQuery.of(context).size.width;
    final sidePadding = screenWidth > 600 ? 16.0 : screenWidth * 0.05;

    final base = _coordinator.getBackgroundColor(context);
    final isDarkBase = base.computeLuminance() < 0.5;
    final scrolled = Color.alphaBlend(
      isDarkBase
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.black.withValues(alpha: 0.06),
      base,
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) await _handleBack();
      },
      child: ValueListenableBuilder<double>(
        valueListenable: _coordinator.scrollProgress,
        builder: (context, progress, _) {
          final statusColor = Color.lerp(base, scrolled, progress)!;
          final statusBrightness = statusColor.computeLuminance() < 0.5
              ? Brightness.light
              : Brightness.dark;
          final scaffold = _buildScaffold(
            context, statusColor, statusBrightness,
            finalTextColor, finalHintColor, sidePadding, l10n,
          );
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOut,
                ),
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.04),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  )),
                  child: child,
                ),
              );
            },
            child: KeyedSubtree(
              key: ValueKey(_isReadOnly),
              child: scaffold,
            ),
          );
        },
      ),
    );
  }
}
