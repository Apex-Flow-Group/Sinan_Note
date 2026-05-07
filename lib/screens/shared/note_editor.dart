// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:async';

import 'package:apex_note/core/utils/quill_migration.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:apex_note/models/note.dart';
import 'package:apex_note/models/note_mode.dart';
import 'package:apex_note/screens/shared/note_editor/core/editor_build_methods.dart';
import 'package:apex_note/screens/shared/note_editor/core/editor_coordinator.dart';
import 'package:apex_note/screens/shared/note_editor/handlers/editor_dialog_handlers.dart';
import 'package:apex_note/screens/shared/note_editor/state/editor_save_operations.dart';
import 'package:apex_note/screens/shared/note_editor/view/note_readonly_view.dart';
import 'package:apex_note/services/unified_notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

    _coordinator = EditorCoordinator(
      note: widget.note,
      mode: widget.mode,
      skipAuthentication: widget.skipAuthentication,
      originallyLocked: widget.originallyLocked,
    );

    _coordinator.initialize(context);
    _coordinator.initialize(context);
    _isReadOnly = widget.readOnly;
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
      // تحديث الـ toolbar عند تغيير الـ selection (لإظهار حالة Bold/Italic/إلخ)
      _coordinator.quillController!.addListener(_onQuillSelectionChanged);
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
    _coordinator.quillController?.removeListener(_onQuillSelectionChanged);
    _selectionBarActive.dispose();
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
      {bool forceUpdate = false, bool isManualSave = false}) {
    return EditorSaveOperations.saveToDatabase(
      coordinator: _coordinator,
      mode: widget.mode,
      existingNote: widget.note,
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
        mode: widget.mode,
        existingNote: widget.note,
        l10n: _l10nRef,
        isMounted: () => mounted,
        onSavedNewId: () {
          if (mounted) setState(() {});
        },
      );

  Future<void> _saveAsMarkdown() => EditorSaveOperations.saveAsMarkdown(
        context: context,
        coordinator: _coordinator,
        mode: widget.mode,
        existingNote: widget.note,
        l10n: _l10nRef,
      );

  Future<void> _saveWithExtension(String extension) =>
      EditorSaveOperations.saveWithExtension(
        context: context,
        coordinator: _coordinator,
        mode: widget.mode,
        existingNote: widget.note,
        l10n: _l10nRef,
        extension: extension,
      );

  // ==================== LIFECYCLE METHODS ====================

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
        mode: widget.mode,
        coordinator: _coordinator,
        sidePadding: sidePadding,
        heroTag: widget.heroTag,
        onClose: widget.onClose,
        onEnterEdit: () {
          // ── ضمان تحميل العنوان قبل دخول وضع التعديل ──────────────────
          // في وضع العرض customTitle قد يكون null (مشتق من المحتوى)
          // نحمّله صراحةً من note.title حتى لا يُعتبر محذوفاً عند الحفظ
          if (_coordinator.stateManager.customTitle == null &&
              widget.note != null &&
              widget.note!.title.isNotEmpty &&
              widget.note!.title != 'Untitled') {
            _coordinator.stateManager.customTitle = widget.note!.title;
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
                if (_coordinator.quillController != null) {
                  final data = await Clipboard.getData(Clipboard.kTextPlain);
                  final text = data?.text;
                  if (text != null && text.isNotEmpty) {
                    final ctrl = _coordinator.quillController!;
                    final sel = ctrl.selection;
                    final offset =
                        sel.isCollapsed ? sel.extentOffset : sel.start;
                    final deleteLen = sel.isCollapsed ? 0 : sel.end - sel.start;
                    ctrl.replaceText(offset, deleteLen, text, null);
                  }
                }
              },
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
            EditorBuildMethods.buildToolbar(
              context: context,
              coordinator: _coordinator,
              finalTextColor: finalTextColor,
              mode: widget.mode,
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
    );
  }
}
