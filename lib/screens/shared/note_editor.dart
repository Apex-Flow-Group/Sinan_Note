// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:provider/provider.dart';
import 'package:sinan_note/controllers/notes/notes_provider.dart';
import 'package:sinan_note/core/shortcuts/app_shortcuts.dart';
import 'package:sinan_note/core/utils/quill_migration.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';
import 'package:sinan_note/models/note.dart';
import 'package:sinan_note/models/note_mode.dart';
import 'package:sinan_note/screens/shared/note_editor/core/editor_build_methods.dart';
import 'package:sinan_note/screens/shared/note_editor/core/editor_coordinator.dart';
import 'package:sinan_note/screens/shared/note_editor/handlers/editor_dialog_handlers.dart';
import 'package:sinan_note/screens/shared/note_editor/state/editor_save_operations.dart';
import 'package:sinan_note/screens/shared/note_editor/view/note_readonly_view.dart';
import 'package:sinan_note/services/keyboard/editor_command_bus.dart';
import 'package:sinan_note/services/unified_notification_service.dart';
import 'package:sinan_note/services/version_control_service.dart';
import 'package:sinan_note/widgets/editor/category_picker_sheet.dart';

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

  static bool _looksLikeMarkdown(String text) => RegExp(
        r'(^#{1,6} |\*\*|__| *[-*+] | *\d+\. |^> |```|`[^`])',
        multiLine: true,
      ).hasMatch(text);
  late NoteMode _currentMode;
  Note? _currentNote;
  bool _isQuillReady = false;
  final ValueNotifier<bool> _selectionBarActive = ValueNotifier(false);

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

    _currentMode = widget.mode;
    _coordinator = EditorCoordinator(
      note: widget.note,
      mode: _currentMode,
      skipAuthentication: widget.skipAuthentication,
      originallyLocked: widget.originallyLocked,
    );

    _coordinator.initialize(context);
    _isReadOnly = widget.readOnly;

    // Start version control session for existing notes
    if (widget.note != null &&
        widget.note!.id != null &&
        !widget.note!.isLocked) {
      VersionControlService().startEditingSession(
        widget.note!.id!,
        widget.note!.title,
        widget.note!.content,
      );
    }
    // ظ„ظ„ظ†ظˆطھط§طھ ط§ظ„ط·ظˆظٹظ„ط©: ط£ط¹ط¯ ط¨ظ†ط§ط، QuillController ظپظٹ isolate ط¨ط¹ط¯ ط£ظˆظ„ frame
    // ظ‡ط°ط§ ظٹظ…ظ†ط¹ ط§ظ„طھط¬ظ…ط¯ ط¹ظ†ط¯ ظپطھط­ ظ†ظˆطھط§طھ > 5000 ط­ط±ظپ
    if (widget.mode == NoteMode.simple ||
        widget.mode == NoteMode.reminder ||
        widget.mode == NoteMode.rich) {
      // ط£ظˆظ„ 20 ط³ط·ط± ط¬ط§ظ‡ط²ط© ظپظˆط±ط§ظ‹ â€” ط§ظ„ظ…ط­ط±ط± ظٹظپطھط­ ط¨ط¯ظˆظ† طھط¬ظ…ط¯
      _isQuillReady = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _coordinator.initializeQuillAsync();
        if (mounted) {
          // ط£ط¹ط¯ ط±ط¨ط· ط§ظ„ظ€ listener ط¨ط¹ط¯ ط§ط³طھط¨ط¯ط§ظ„ ط§ظ„ظ€ controller ط¨ط§ظ„ظƒط§ظ…ظ„
          _quillChangesSubscription?.cancel();
          _quillChangesSubscription =
              _coordinator.quillController!.document.changes.listen((_) {
            _onQuillContentChanged();
            _updateUndoRedoState();
          });
          // تحديث الـ toolbar عند تغيير الـ selection (لإظهار حالة Bold/Italic/إلخ)
          _coordinator.quillController!.addListener(_onQuillSelectionChanged);
          // طھط­ط¯ظٹط« طµط§ظ…طھ â€” ط¨ط¯ظˆظ† loading indicator
          setState(() {});
        }
      });
    } else {
      _isQuillReady = true;
    }

    // Rebuild after init so detectedLanguage is reflected in toolbar
    if (widget.mode == NoteMode.code && widget.note != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    }

    // Add listeners
    _attachListeners();
    // استمع لأوامر القائمة (DesktopMenuBar)
    EditorCommandBus().addListener(_onEditorCommand);
    // سجّل هذا المحرر كالمحرر النشط
    final myId = widget.note?.id;
    if (myId != null) EditorCommandBus().registerEditor(myId);

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
    EditorCommandBus().removeListener(_onEditorCommand);
    // ألغِ تسجيل هذا المحرر
    EditorCommandBus().unregisterEditor(widget.note?.id);
    // End version control session to save history (fire-and-forget)
    _endVersionSession();
    _quillChangesSubscription?.cancel();
    _coordinator.quillController?.removeListener(_onQuillSelectionChanged);
    _selectionBarActive.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _coordinator.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // حفظ المحتوى فوراً قبل أي شيء آخر
      _coordinator.autosaveTimer?.cancel();
      if (_coordinator.stateManager.hasChanges() &&
          !_coordinator.stateManager.isSaving &&
          !_isReadOnly) {
        _saveNoteToDatabase();
      }
      _endVersionSession();
    } else if (state == AppLifecycleState.resumed) {
      // Restart session when app comes back
      final noteId = _coordinator.savedNoteId ?? widget.note?.id;
      if (noteId != null && !_coordinator.initialLockState) {
        final content = _currentMode == NoteMode.code
            ? _coordinator.codeController!.text
            : (_currentMode == NoteMode.checklist
                ? _coordinator.contentController.text
                : (_coordinator.quillController != null
                    ? QuillMigration.toDeltaJson(_coordinator.quillController!)
                    : ''));
        final title = _coordinator.getCurrentTitle('');
        VersionControlService().startEditingSession(noteId, title, content);
      }
    }
  }

  /// End the version control session, saving history if there were significant changes
  Future<void> _endVersionSession() async {
    final noteId = _coordinator.savedNoteId ?? widget.note?.id;
    if (noteId == null || _coordinator.initialLockState) return;

    final content = _currentMode == NoteMode.code
        ? (_coordinator.codeController?.text ?? '')
        : (_currentMode == NoteMode.checklist
            ? _coordinator.contentController.text
            : (_coordinator.quillController != null
                ? QuillMigration.toDeltaJson(_coordinator.quillController!)
                : ''));
    final title = _coordinator.getCurrentTitle('');

    await VersionControlService().endEditingSession(
      noteId: noteId,
      title: title,
      content: content,
      isLocked: _coordinator.initialLockState,
    );
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
      mode: _currentMode,
      onColorSelected: (colorIndex, textColor) {
        if (mounted) {
          setState(() {
            _coordinator.textColor = textColor;
          });
        }
      },
    );
    // حفظ اللون فوراً إذا كانت الملاحظة موجودة مسبقاً
    final noteId = _coordinator.savedNoteId ?? widget.note?.id;
    if (noteId != null && _coordinator.stateManager.hasChanges()) {
      final saved =
          await _saveNoteToDatabase(forceUpdate: true, isManualSave: true);
      if (saved) {
        _coordinator.stateManager.updateSnapshot();
      }
    }
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
      {bool forceUpdate = false, bool isManualSave = false}) {
    final effectiveNote = _currentNote ?? widget.note;
    return EditorSaveOperations.saveToDatabase(
      coordinator: _coordinator,
      mode: _currentMode,
      existingNote: effectiveNote,
      l10n: _l10nRef,
      isMounted: () => mounted,
      onSavedNewId: () {
        if (mounted) setState(() {});
      },
      forceUpdate: forceUpdate,
      isManualSave: isManualSave,
    );
  }

  Future<void> _saveNote() => EditorSaveOperations.saveManually(
        context: context,
        coordinator: _coordinator,
        mode: _currentMode,
        existingNote: _currentNote ?? widget.note,
        l10n: _l10nRef,
        isMounted: () => mounted,
        onSavedNewId: () {
          if (mounted) setState(() {});
        },
      );

  Future<void> _saveAsMarkdown() => EditorSaveOperations.saveAsMarkdown(
        context: context,
        coordinator: _coordinator,
        mode: _currentMode,
        existingNote: _currentNote ?? widget.note,
        l10n: _l10nRef,
      );

  Future<void> _saveWithExtension(String extension) =>
      EditorSaveOperations.saveWithExtension(
        context: context,
        coordinator: _coordinator,
        mode: _currentMode,
        existingNote: _currentNote ?? widget.note,
        l10n: _l10nRef,
        extension: extension,
      );

  // ==================== LIFECYCLE METHODS ====================

  void _attachListeners() {
    _coordinator.contentController.addListener(_onContentChanged);
    _coordinator.undoController.addListener(_updateUndoRedoState);
    if (_currentMode == NoteMode.code) {
      _coordinator.codeController!.addListener(_onContentChanged);
      _coordinator.codeUndoController.addListener(_updateUndoRedoState);
    }
    _updateUndoRedoState();
  }

  void _onQuillContentChanged() {
    // ظ„ط§ ظ†ط­ظپط¸ ط£ط«ظ†ط§ط، طھط­ظ…ظٹظ„ ط§ظ„ظ†ظˆطھط© â€” طھط؛ظٹظٹط±ط§طھ _fixDeltaDirections ظ„ظٹط³طھ ظ…ظ† ط§ظ„ظ…ط³طھط®ط¯ظ…
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

    final currentText = _currentMode == NoteMode.code
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
          (_coordinator.codeController?.text.trim().isNotEmpty ?? false) &&
          !_coordinator.stateManager.isSaving) {
        _saveNoteToDatabase();
      }
    });
  }

  /// يُعاد استدعاؤه عند تغيير الـ cursor/selection في Quill
  /// لتحديث حالة أزرار التنسيق (Bold/Italic/H1/إلخ) في الـ toolbar
  void _onQuillSelectionChanged() {
    if (mounted) setState(() {});
  }

  void _updateUndoRedoState() {
    if (_currentMode == NoteMode.checklist) return;

    if (_currentMode == NoteMode.code) {
      setState(() {
        _coordinator.stateManager.canUndo =
            _coordinator.codeUndoController.value.canUndo;
        _coordinator.stateManager.canRedo =
            _coordinator.codeUndoController.value.canRedo;
      });
    } else if (_currentMode == NoteMode.simple ||
        _currentMode == NoteMode.rich ||
        _currentMode == NoteMode.reminder) {
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
    // ظˆط¶ط¹ ط§ظ„ظ‚ط±ط§ط،ط© â€” ط§ط®ط±ط¬ ظ…ط¨ط§ط´ط±ط© ط¨ط¯ظˆظ† ط­ظپط¸ ط£ظˆ ط±ط³ط§ظ„ط©
    if (_isReadOnly) {
      if (!mounted) return;
      if (widget.onClose != null) {
        widget.onClose!();
      } else {
        Navigator.of(context).pop(widget.note != null);
      }
      return;
    }

    final content = _currentMode == NoteMode.code
        ? _coordinator.codeController!.text
        : (_currentMode == NoteMode.checklist
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

    // End version control session — saves history for significant changes
    await _endVersionSession();

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
      return NoteReadOnlyView(
        note: widget.note!,
        mode: _currentMode,
        coordinator: _coordinator,
        sidePadding: sidePadding,
        heroTag: widget.heroTag,
        onClose: widget.onClose,
        onModeChanged: (newMode, newNote) => setState(() {
          _currentMode = newMode;
          _currentNote = newNote;
        }),
        onEnterEdit: () {
          if ((_currentNote ?? widget.note)?.isTrashed == true) return;
          if (_currentMode != widget.mode) {
            _coordinator.dispose();
            _coordinator = EditorCoordinator(
              note: _currentNote ?? widget.note,
              mode: _currentMode,
              skipAuthentication: widget.skipAuthentication,
              originallyLocked: widget.originallyLocked,
            );
            _coordinator.initialize(context);
            _attachListeners();
            // ربط quill listener إذا كان الـ mode يستخدم quill
            if (_currentMode == NoteMode.simple ||
                _currentMode == NoteMode.rich ||
                _currentMode == NoteMode.reminder) {
              _quillChangesSubscription?.cancel();
              if (_coordinator.quillController != null) {
                _quillChangesSubscription =
                    _coordinator.quillController!.document.changes.listen((_) {
                  _onQuillContentChanged();
                  _updateUndoRedoState();
                });
                _coordinator.quillController!
                    .addListener(_onQuillSelectionChanged);
              }
            }
          } else {
            if (_coordinator.stateManager.customTitle == null &&
                widget.note != null &&
                widget.note!.title.isNotEmpty &&
                widget.note!.title != 'Untitled') {
              _coordinator.stateManager.customTitle = widget.note!.title;
            }
          }
          setState(() => _isReadOnly = false);
        },
        onSave: ({bool isManualSave = false}) =>
            _saveNoteToDatabase(isManualSave: isManualSave),
      );
    }

    // ظˆط¶ط¹ ط§ظ„طھط¹ط¯ظٹظ„ â€” ط§ظ„ظ…ط­ط±ط± ط§ظ„ظƒط§ظ…ظ„
    // ط¥ط°ط§ ظ„ظ… ظٹظƒطھظ…ظ„ ط¨ظ†ط§ط، QuillController ط¨ط¹ط¯ â€” ظ†ط¹ط±ط¶ skeleton ط¨ط³ظٹط·
    if (!_isQuillReady && !_isReadOnly) {
      return Scaffold(
        backgroundColor: _coordinator.getBackgroundColor(context),
        body: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: _coordinator.getBackgroundColor(context).computeLuminance() >
                    0.5
                ? Colors.black38
                : Colors.white38,
          ),
        ),
      );
    }

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
            RepaintBoundary(
              child: EditorBuildMethods.buildContentArea(
                context: context,
                coordinator: _coordinator,
                sidePadding: sidePadding,
                finalTextColor: finalTextColor,
                finalHintColor: finalHintColor,
                mode: _currentMode,
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
                  // نحدث العنوان بدون setState لتجنب إعادة بناء ChecklistEditor
                  if (_coordinator.stateManager.checklistTitle != title) {
                    _coordinator.stateManager.checklistTitle = title;
                  }
                },
                readOnly: false,
                selectionBarActive: _selectionBarActive,
              ),
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
              selectionBarActive: _selectionBarActive,
              quillController: _coordinator.quillController,
              onPaste: () async {
                final ctrl = _coordinator.quillController;
                if (ctrl == null) return;
                final data = await Clipboard.getData(Clipboard.kTextPlain);
                final text = data?.text;
                if (text == null || text.isEmpty) return;
                final sel = ctrl.selection;
                final offset = sel.isCollapsed ? sel.extentOffset : sel.start;
                final deleteLen = sel.isCollapsed ? 0 : sel.end - sel.start;
                if (_currentMode == NoteMode.rich && _looksLikeMarkdown(text)) {
                  final mdDelta = MarkdownToDelta(
                    markdownDocument: md.Document(encodeHtml: false),
                  ).convert(text);
                  final insertDelta = Delta();
                  if (deleteLen > 0) {
                    insertDelta
                      ..retain(offset)
                      ..delete(deleteLen);
                  } else {
                    insertDelta.retain(offset);
                  }
                  for (final op in mdDelta.toList()) {
                    insertDelta.push(op);
                  }
                  ctrl.compose(
                    insertDelta,
                    TextSelection.collapsed(
                        offset: offset + mdDelta.length - 1),
                    ChangeSource.local,
                  );
                } else {
                  ctrl.replaceText(offset, deleteLen, text, null);
                }
              },
              onSaveTap: () async {
                if (_currentMode == NoteMode.code &&
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
                    Navigator.pop(
                        context,
                        _coordinator.savedNoteId != null ||
                            widget.note != null);
                  }
                }
              },
            ),
            EditorBuildMethods.buildToolbar(
              context: context,
              coordinator: _coordinator,
              finalTextColor: finalTextColor,
              mode: _currentMode,
              note: widget.note,
              savedNoteId: _coordinator.savedNoteId,
              smartController: _coordinator.smartController,
              formattingController: _coordinator.formattingController,
              selectionBarActive: _selectionBarActive,
              onReminderTap: _showReminderDialog,
              onColorPaletteTap: _showColorPalette,
              onRebuild: () {
                if (mounted) setState(() {});
              },
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
                  final newText =
                      text.substring(0, pos) + symbol + text.substring(pos);
                  ctrl.value = ctrl.value.copyWith(
                    text: newText,
                    selection: TextSelection.collapsed(
                        offset: pos + symbol.length ~/ 2),
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

    return ShortcutScope(
      enabled: true, // دائماً مفعّل — الـ bindings نفسها تتحقق من _isReadOnly
      bindings: _buildShortcutBindings(),
      child: PopScope(
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
              context,
              statusColor,
              statusBrightness,
              finalTextColor,
              finalHintColor,
              sidePadding,
              l10n,
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
      ),
    );
  }

  // ==================== EDITOR COMMAND BUS ====================

  /// يستقبل أوامر من DesktopMenuBar عبر EditorCommandBus
  void _onEditorCommand() {
    final cmd = EditorCommandBus().lastCommand;
    if (cmd == null) return;

    // تحقق أن هذا المحرر هو المحرر النشط
    final myId = _coordinator.savedNoteId ?? widget.note?.id;
    final activeId = EditorCommandBus().activeNoteId;
    if (activeId != null && myId != activeId) return;

    switch (cmd) {
      // ── تنسيق (عبر ShortcutBindings) ──────────────────────────────
      case EditorCommand.bold:
        _buildShortcutBindings()[AppShortcuts.bold]?.call();
      case EditorCommand.italic:
        _buildShortcutBindings()[AppShortcuts.italic]?.call();
      case EditorCommand.underline:
        _buildShortcutBindings()[AppShortcuts.underline]?.call();
      case EditorCommand.strikethrough:
        _buildShortcutBindings()[AppShortcuts.strikethrough]?.call();
      case EditorCommand.undo:
        _buildShortcutBindings()[AppShortcuts.undo]?.call();
      case EditorCommand.redo:
        _buildShortcutBindings()[AppShortcuts.redo]?.call();
      case EditorCommand.rename:
        _buildShortcutBindings()[AppShortcuts.rename]?.call();
      case EditorCommand.save:
        _buildShortcutBindings()[AppShortcuts.save]?.call();
      case EditorCommand.saveAs:
        _buildShortcutBindings()[AppShortcuts.saveAs]?.call();

      // ── إدارة الملاحظة ─────────────────────────────────────────────
      case EditorCommand.archive:
        _handleMenuArchive();
      case EditorCommand.pin:
        _handleMenuPin();
      case EditorCommand.duplicate:
        _handleMenuDuplicate();
      case EditorCommand.delete:
        _handleMenuDelete();
      case EditorCommand.category:
        _handleMenuCategory();
    }
  }

  /// أرشفة الملاحظة مع snackbar تراجع
  Future<void> _handleMenuArchive() async {
    final noteId = _coordinator.savedNoteId ?? widget.note?.id;
    if (noteId == null || !mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final provider = Provider.of<NotesProvider>(context, listen: false);
    await provider.archiveNote(noteId);
    if (!mounted) return;
    UnifiedNotificationService().showWithUndo(
      context: context,
      message: l10n.movedToArchive,
      type: NotificationType.success,
      actionKey: 'menu_archive_$noteId',
      onExecute: () {},
      onUndo: () async => await provider.unarchiveNote(noteId),
      undoLabel: l10n.undo,
    );
    _handleBack();
  }

  /// تثبيت/إلغاء تثبيت الملاحظة مع snackbar
  Future<void> _handleMenuPin() async {
    final noteId = _coordinator.savedNoteId ?? widget.note?.id;
    if (noteId == null || !mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final provider = Provider.of<NotesProvider>(context, listen: false);
    final note = widget.note ??
        provider.notes
            .firstWhere((n) => n.id == noteId, orElse: () => widget.note!);
    final wasPinned = note.isPinned;
    await provider.updateNote(note.copyWith(isPinned: !wasPinned));
    if (!mounted) return;
    UnifiedNotificationService().show(
      context: context,
      message: wasPinned ? l10n.unpin : l10n.pin,
      type: NotificationType.success,
      duration: const Duration(seconds: 2),
    );
  }

  /// تكرار الملاحظة مع snackbar
  Future<void> _handleMenuDuplicate() async {
    final noteId = _coordinator.savedNoteId ?? widget.note?.id;
    if (noteId == null || !mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final provider = Provider.of<NotesProvider>(context, listen: false);
    await provider.duplicateNote(noteId, copyLabel: l10n.noteCopy);
    if (!mounted) return;
    UnifiedNotificationService().show(
      context: context,
      message: l10n.noteCopied,
      type: NotificationType.success,
      duration: const Duration(seconds: 2),
    );
  }

  /// حذف الملاحظة — bottom sheet تأكيد مع snackbar تراجع
  Future<void> _handleMenuDelete() async {
    final noteId = _coordinator.savedNoteId ?? widget.note?.id;
    if (noteId == null || !mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final provider = Provider.of<NotesProvider>(context, listen: false);

    // bottom sheet تأكيد
    final confirm = await showModalBottomSheet<bool>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Icon(Icons.delete_outline_rounded,
                  size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(
                l10n.deleteNote,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.deleteConfirm,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(l10n.cancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(l10n.delete),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm != true || !mounted) return;
    await provider.trashNote(noteId);
    if (!mounted) return;
    UnifiedNotificationService().showWithUndo(
      context: context,
      message: l10n.movedToTrash,
      type: NotificationType.info,
      actionKey: 'menu_delete_$noteId',
      onExecute: () {},
      onUndo: () async => await provider.restoreNote(noteId),
      undoLabel: l10n.undo,
    );
    _handleBack();
  }

  /// فتح منتقي الكتالوج
  Future<void> _handleMenuCategory() async {
    if (!mounted) return;
    final current = _coordinator.stateManager.categoryIds;
    final result = await CategoryPickerSheet.show(
      context,
      current,
      isHiddenFromHome: _coordinator.stateManager.isHiddenFromHome,
    );
    if (result != null && mounted) {
      setState(() {
        _coordinator.stateManager.categoryIds =
            result['categoryIds'] as List<int>;
        _coordinator.stateManager.isHiddenFromHome =
            result['isHiddenFromHome'] as bool;
        _coordinator.stateManager.markDirty();
      });
    }
  }

  // ==================== KEYBOARD SHORTCUTS ====================

  Map<SingleActivator, VoidCallback> _buildShortcutBindings() {
    return {
      // ─── حفظ ─────────────────────────────────────────────────────────
      AppShortcuts.save: () {
        if (!_isReadOnly) _saveNote();
      },

      // ─── حفظ كملف ────────────────────────────────────────────────────
      AppShortcuts.saveAs: () {
        if (!_isReadOnly && _currentMode == NoteMode.code) {
          final ext = _coordinator.detectedLanguage != null
              ? _coordinator.smartController
                  .getExtensionForLanguage(_coordinator.detectedLanguage!)
              : '.txt';
          _showSmartSaveDialog(ext);
        } else if (!_isReadOnly) {
          _saveAsMarkdown();
        }
      },

      // ─── تراجع ───────────────────────────────────────────────────────
      AppShortcuts.undo: () {
        if (_isReadOnly) return;
        if (_currentMode == NoteMode.code) {
          _coordinator.codeUndoController.value =
              const UndoHistoryValue(canUndo: true, canRedo: false);
        } else if (_currentMode == NoteMode.checklist) {
          _coordinator.checklistUndoRedo?.undo();
          _updateChecklistUndoRedo();
        } else {
          _coordinator.quillController?.undo();
          _updateUndoRedoState();
        }
      },

      // ─── إعادة ───────────────────────────────────────────────────────
      AppShortcuts.redo: () {
        if (_isReadOnly) return;
        if (_currentMode == NoteMode.code) {
          _coordinator.codeUndoController.value =
              const UndoHistoryValue(canUndo: false, canRedo: true);
        } else if (_currentMode == NoteMode.checklist) {
          _coordinator.checklistUndoRedo?.redo();
          _updateChecklistUndoRedo();
        } else {
          _coordinator.quillController?.redo();
          _updateUndoRedoState();
        }
      },

      // ─── إعادة (بديل Ctrl+Shift+Z) ──────────────────────────────────
      AppShortcuts.redoAlt: () {
        if (_isReadOnly) return;
        if (_currentMode == NoteMode.checklist) {
          _coordinator.checklistUndoRedo?.redo();
          _updateChecklistUndoRedo();
        } else {
          _coordinator.quillController?.redo();
          _updateUndoRedoState();
        }
      },

      // ─── إعادة تسمية (F2) ────────────────────────────────────────────
      AppShortcuts.rename: () {
        if (!_isReadOnly) _showRenameTitleDialog();
      },

      // ─── عريض ─────────────────────────────────────────────────────────
      AppShortcuts.bold: () {
        if (_isReadOnly) return;
        final quill = _coordinator.quillController;
        if (quill == null) return;
        final isActive =
            quill.getSelectionStyle().attributes.containsKey('bold');
        quill.formatSelection(
            isActive ? Attribute.clone(Attribute.bold, null) : Attribute.bold);
      },

      // ─── مائل ─────────────────────────────────────────────────────────
      AppShortcuts.italic: () {
        if (_isReadOnly) return;
        final quill = _coordinator.quillController;
        if (quill == null) return;
        final isActive =
            quill.getSelectionStyle().attributes.containsKey('italic');
        quill.formatSelection(isActive
            ? Attribute.clone(Attribute.italic, null)
            : Attribute.italic);
      },

      // ─── تحته خط ──────────────────────────────────────────────────────
      AppShortcuts.underline: () {
        if (_isReadOnly) return;
        final quill = _coordinator.quillController;
        if (quill == null) return;
        final isActive =
            quill.getSelectionStyle().attributes.containsKey('underline');
        quill.formatSelection(isActive
            ? Attribute.clone(Attribute.underline, null)
            : Attribute.underline);
      },

      // ─── يتوسطه خط ────────────────────────────────────────────────────
      AppShortcuts.strikethrough: () {
        if (_isReadOnly) return;
        final quill = _coordinator.quillController;
        if (quill == null) return;
        final isActive =
            quill.getSelectionStyle().attributes.containsKey('strike');
        quill.formatSelection(isActive
            ? Attribute.clone(Attribute.strikeThrough, null)
            : Attribute.strikeThrough);
      },

      // ─── إغلاق / عودة ─────────────────────────────────────────────────
      AppShortcuts.close: () => _handleBack(),

      // ─── لون الملاحظة ──────────────────────────────────────────────────
      AppShortcuts.settings: () {
        if (!_isReadOnly) _showColorPalette();
      },

      // ─── إدارة الملاحظة (تعمل حتى في وضع القراءة) ────────────────────
      AppShortcuts.archive: () {
        final noteId = _coordinator.savedNoteId ?? widget.note?.id;
        if (noteId != null) _handleMenuArchive();
      },
      AppShortcuts.pin: () {
        final noteId = _coordinator.savedNoteId ?? widget.note?.id;
        if (noteId != null) _handleMenuPin();
      },
      AppShortcuts.duplicate: () {
        final noteId = _coordinator.savedNoteId ?? widget.note?.id;
        if (noteId != null) _handleMenuDuplicate();
      },
      AppShortcuts.delete: () {
        final noteId = _coordinator.savedNoteId ?? widget.note?.id;
        if (noteId != null) _handleMenuDelete();
      },
    };
  }
}
