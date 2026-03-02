// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:async';

import 'package:apex_note/core/utils/logger.dart';
import 'package:apex_note/core/utils/quill_migration.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:apex_note/models/note.dart';
import 'package:apex_note/models/note_mode.dart';
import 'package:apex_note/screens/shared/note_editor/core/editor_build_methods.dart';
import 'package:apex_note/screens/shared/note_editor/core/editor_coordinator.dart';
import 'package:apex_note/screens/shared/note_editor/handlers/editor_dialog_handlers.dart';
import 'package:apex_note/screens/shared/note_editor/state/editor_save_manager.dart';
import 'package:apex_note/services/unified_notification_service.dart';
import 'package:flutter/material.dart';

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

  const NoteEditorImmersive({
    super.key,
    this.note,
    this.mode = NoteMode.simple,
    this.skipAuthentication = false,
    this.originallyLocked = false,
    this.onClose,
  });

  @override
  State<NoteEditorImmersive> createState() => _NoteEditorImmersiveState();
}

class _NoteEditorImmersiveState extends State<NoteEditorImmersive>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  late EditorCoordinator _coordinator;
  AppLocalizations? _l10nRef;
  StreamSubscription? _quillChangesSubscription;

  @override
  bool get wantKeepAlive => true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _l10nRef = AppLocalizations.of(context);
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

    if (widget.mode == NoteMode.simple || widget.mode == NoteMode.reminder || widget.mode == NoteMode.rich) {
      _quillChangesSubscription = _coordinator.quillController!.document.changes
          .listen((_) => _onQuillContentChanged());
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

  Future<void> _saveNoteToDatabase(
      {bool forceUpdate = false, bool isManualSave = false}) async {
    AppLogger.info(
        '_saveNoteToDatabase called - forceUpdate: $forceUpdate, isManualSave: $isManualSave',
        'Editor');

    if (_coordinator.stateManager.isSaving) {
      AppLogger.warning('Already saving, skipping', 'Editor');
      return;
    }

    final isNewLockedNote =
        (_coordinator.initialLockState || widget.note?.isLocked == true) &&
            widget.note?.id == null &&
            _coordinator.savedNoteId == null;

    if (!forceUpdate &&
        !isNewLockedNote &&
        (_coordinator.savedNoteId != null || widget.note != null)) {
      if (!_coordinator.stateManager.hasChanges()) {
        AppLogger.info('No changes detected, skipping save', 'Editor');
        return;
      }
    }

    AppLogger.info('Proceeding with save...', 'Editor');
    _coordinator.stateManager.isSaving = true;

    try {
      String contentToSave = widget.mode == NoteMode.code
          ? _coordinator.codeController!.text
          : (widget.mode == NoteMode.checklist
              ? _coordinator.contentController.text
              : QuillMigration.toPlainText(_coordinator.quillController!));

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
          return;
        }
      }

      bool isContentEmpty = contentToSave.trim().isEmpty;

      if (isContentEmpty && !isNewLockedNote) {
        final noteId = _coordinator.savedNoteId ?? widget.note?.id;
        if (noteId != null) {
          await _coordinator.notesProviderRef!.trashNote(noteId);
        }
        _coordinator.stateManager.isSaving = false;
        return;
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
    } catch (e) {
      // Ignore save errors
    } finally {
      _coordinator.stateManager.isSaving = false;
    }
  }

  Future<void> _saveNote() async {
    _coordinator.autosaveTimer?.cancel();
    await _saveNoteToDatabase(isManualSave: true);

    // REMOVED: Unnecessary loadNotes() that causes race condition
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    UnifiedNotificationService().show(
      context: context,
      message: l10n!.noteSaved,
      type: NotificationType.success,
      duration: const Duration(seconds: 1),
    );
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
    _coordinator.stateManager.markDirty();
    final newHasContent =
        QuillMigration.toPlainText(_coordinator.quillController!).trim().isNotEmpty;
    if (_coordinator.stateManager.hasContent != newHasContent) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _coordinator.stateManager.hasContent = newHasContent);
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
          _coordinator.contentController.text.isNotEmpty && 
          !_coordinator.stateManager.isSaving) {
        _saveNoteToDatabase();
      }
    });
  }

  void _updateUndoRedoState() {
    if (widget.mode == NoteMode.checklist) {
      return;
    }
    final controller = widget.mode == NoteMode.code
        ? _coordinator.codeUndoController
        : _coordinator.undoController;
    setState(() {
      _coordinator.stateManager.canUndo = controller.value.canUndo;
      _coordinator.stateManager.canRedo = controller.value.canRedo;
    });
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

  // ==================== BUILD METHOD ====================

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

    return PopScope(
      canPop: widget.onClose == null && !_coordinator.stateManager.hasChanges(),
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && _coordinator.stateManager.hasChanges()) {
          await _saveNote();
          if (context.mounted) {
            if (widget.onClose != null) {
              widget.onClose!();
            } else {
              Navigator.of(context)
                  .pop(_coordinator.savedNoteId != null || widget.note != null);
            }
          }
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: _coordinator.getBackgroundColor(context),
        body: Stack(
          children: [
            // Content Area
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
            ),

            // Header
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
              onBackTap: widget.onClose,
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
                    Navigator.pop(
                        context,
                        _coordinator.savedNoteId != null ||
                            widget.note != null);
                  }
                }
              },
            ),

            // Toolbar
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
              onSmartSaveDialog: () async {
                if (_coordinator.detectedLanguage != null) {
                  final ext = _coordinator.smartController
                      .getExtensionForLanguage(_coordinator.detectedLanguage!);
                  await _showSmartSaveDialog(ext);
                }
              },
              saveNote: _saveNote,
            ),
          ],
        ),
      ),
    );
  }
}
