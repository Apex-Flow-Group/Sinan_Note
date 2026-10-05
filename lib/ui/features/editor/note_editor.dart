// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:provider/provider.dart';
import 'package:sinan_note/domain/models/note.dart';
import 'package:sinan_note/domain/models/note_mode.dart';
import 'package:sinan_note/domain/versioning.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';
import 'package:sinan_note/ui/core/keyboard/app_shortcuts.dart';
import 'package:sinan_note/ui/core/keyboard/editor_command_bus.dart';
import 'package:sinan_note/ui/core/quill/quill_migration.dart';
import 'package:sinan_note/ui/core/theme/app_colors.dart';
import 'package:sinan_note/ui/core/theme/editor_palette.dart';
import 'package:sinan_note/ui/core/widgets/unified_notification_service.dart';
import 'package:sinan_note/ui/features/editor/note_editor/core/editor_build_methods.dart';
import 'package:sinan_note/ui/features/editor/note_editor/core/editor_coordinator.dart';
import 'package:sinan_note/ui/features/editor/note_editor/handlers/editor_dialog_handlers.dart';
import 'package:sinan_note/ui/features/editor/note_editor/state/editor_save_manager.dart';
import 'package:sinan_note/ui/features/editor/note_editor/view/note_readonly_view.dart';
import 'package:sinan_note/ui/features/editor/view_models/editor_view_model.dart';
import 'package:sinan_note/ui/features/editor/widgets/category_picker_sheet.dart';
import 'package:sinan_note/ui/features/notes/view_models/notes_provider.dart';

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
  final String? prebuiltDeltaJson;

  /// ملاحظة مستلمة من الخارج (مشاركة/مزامنة) — لا تُحفظ تلقائياً
  /// عند الخروج يُسأل المستخدم إن كان يريد الحفظ
  final bool isSharedPreview;

  const NoteEditorImmersive({
    super.key,
    this.note,
    this.mode = NoteMode.simple,
    this.skipAuthentication = false,
    this.originallyLocked = false,
    this.onClose,
    this.readOnly = false,
    this.prebuiltDeltaJson,
    this.isSharedPreview = false,
  });

  @override
  State<NoteEditorImmersive> createState() => _NoteEditorImmersiveState();
}

class _NoteEditorImmersiveState extends State<NoteEditorImmersive>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver
    implements DraftSource {
  late EditorCoordinator _coordinator;
  AppLocalizations? _l10nRef;
  StreamSubscription? _quillChangesSubscription;
  late bool _isReadOnly;

  /// العنوان والمحتوى المخزّنان عند بداية جلسة التحرير الحالية.
  (String, String)? _sessionStart;

  /// المالك الوحيد لحفظ هذه الملاحظة.
  late final EditorViewModel _vm;
  late final EditorCommandBus _commands = context.read<EditorCommandBus>();

  static bool _looksLikeMarkdown(String text) => RegExp(
        r'(^#{1,6} |\*\*|__| *[-*+] | *\d+\. |^> |```|`[^`])',
        multiLine: true,
      ).hasMatch(text);
  late NoteMode _currentMode;
  Note? _currentNote;
  bool _isQuillReady = false;
  final ValueNotifier<bool> _selectionBarActive = ValueNotifier(false);

  /// يُعيد بناء الرأس وشريط الأدوات فقط (حالة التنسيق، التراجع) — لا الشاشة
  /// كلها مع كل حرف.
  final _chrome = ValueNotifier<int>(0);

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
      readOnly: widget.readOnly,
      prebuiltDeltaJson: widget.prebuiltDeltaJson,
    );

    _coordinator.initialize(context);
    _isReadOnly = widget.readOnly;
    _vm = context.read<EditorSessions>().open(
          widget.note,
          locked: widget.originallyLocked || (widget.note?.isLocked ?? false),
        )..attach(this);

    // بداية جلسة التحرير: الملاحظة كما خُزّنت عند الفتح
    final opened = widget.note;
    if (opened != null && opened.id != null && !opened.isLocked) {
      _sessionStart = _sessionKey(opened);
    }

    // للنوتات الطويلة: أعد بناء QuillController في isolate بعد أول frame
    // هذا يمنع التجمد عند فتح نوتات > 5000 حرف
    if (widget.mode == NoteMode.simple ||
        widget.mode == NoteMode.reminder ||
        widget.mode == NoteMode.rich) {
      // أول 20 سطر جاهزة فوراً — المحرر يفتح بدون تجمد
      _isQuillReady = true;
      if (!_isReadOnly) {
        // وضع التحرير: نبني Quill الكامل بعد أول frame
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await _coordinator.initializeQuillAsync();
          if (mounted) {
            _quillChangesSubscription?.cancel();
            _quillChangesSubscription =
                _coordinator.quillController!.document.changes.listen((_) {
              _onQuillContentChanged();
              _updateUndoRedoState();
            });
            _coordinator.quillController!.addListener(_onQuillSelectionChanged);
            setState(() {});
          }
        });
      }
      // وضع القراءة: quillController الكامل جاهز من initialize() — لا شيء إضافي
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
    _commands.addUniqueListener(_onEditorCommand);
    // سجّل هذا المحرر كالمحرر النشط
    final myId = widget.note?.id;
    if (myId != null) {
      _commands.registerEditor(myId, hashCode);
    }

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
    _commands.removeUniqueListener(_onEditorCommand);
    // ألغِ تسجيل هذا المحرر
    _commands.unregisterEditor(widget.note?.id);
    // End version control session to save history (fire-and-forget)
    _endVersionSession();
    _quillChangesSubscription?.cancel();
    _coordinator.quillController?.removeListener(_onQuillSelectionChanged);
    _selectionBarActive.dispose();
    _chrome.dispose();
    WidgetsBinding.instance.removeObserver(this);
    // ما كُتب ولم يُحفظ بعد (الحفظ التلقائي المعلّق): يُلتقط الآن ويُكتب
    _coordinator.autosaveTimer?.cancel();
    if (!_isReadOnly) unawaited(_vm.save());
    _vm.dispose();
    _coordinator.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // حفظ المحتوى فوراً قبل أي شيء آخر — متزامناً حتى التشفير، فإقفال
      // الخزنة في الحدث نفسه يأتي بعده. النسخة بعد اكتمال الحفظ.
      _coordinator.autosaveTimer?.cancel();
      if (!_isReadOnly) {
        unawaited(_saveNoteToDatabase().then((_) => _endVersionSession()));
      }
    }
  }

  /// نهاية جلسة تحرير: نسخة واحدة إن تغيّرت الملاحظة المخزّنة منذ فُتحت
  /// (والسياسة في المستودع تقرر إن كان التغيير ذا معنى). المقفلة لا نسخ لها.
  Future<void> _endVersionSession() async {
    final noteId = _coordinator.savedNoteId ?? widget.note?.id;
    final start = _sessionStart;
    if (noteId == null || start == null || _coordinator.initialLockState) {
      return;
    }
    final provider = _coordinator.notesProviderRef;
    final stored = provider?.cachedNote(noteId);
    if (provider == null || stored == null) return;
    final now = _sessionKey(stored);
    if (now == start) return;
    _sessionStart = now;
    await provider.recordVersion(noteId, VersionTrigger.sessionEnd);
  }

  static (String, String) _sessionKey(Note note) => (note.title, note.content);

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
    if (_vm.noteId != null) await _saveNoteToDatabase(isManualSave: true);
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

  /// يحفظ ما في المحرر إن تغيّر ([forceUpdate]: حتى لو لم يتغيّر).
  Future<bool> _saveNoteToDatabase(
      {bool forceUpdate = false, bool isManualSave = false}) async {
    final wasNew = _vm.noteId == null;
    final saved = await _vm.save(manual: isManualSave, force: forceUpdate);
    _coordinator.savedNoteId = _vm.noteId;
    if (wasNew && _vm.noteId != null && mounted) setState(() {});
    return saved;
  }

  Future<void> _saveNote() async {
    _coordinator.autosaveTimer?.cancel();
    final saved =
        await _saveNoteToDatabase(forceUpdate: true, isManualSave: true);
    if (!mounted) return;
    if (saved) {
      _showSaved();
    } else {
      _showSaveError();
    }
  }

  Future<void> _saveAsMarkdown() async {
    final saved = await _vm.saveAs((d) => NoteDraft(
          title: d.title,
          content: '```\n${_rawText()}\n```',
          isEmpty: d.isEmpty,
          colorIndex: d.colorIndex,
          reminderDateTime: d.reminderDateTime,
          recurrenceRule: d.recurrenceRule,
          noteType: 'markdown',
          isChecklist: d.isChecklist,
          isProfessional: d.isProfessional,
          categoryIds: d.categoryIds,
          isHiddenFromHome: d.isHiddenFromHome,
        ));
    if (!mounted) return;
    if (saved) {
      UnifiedNotificationService().show(
        context: context,
        message: AppLocalizations.of(context)!.savedAsMarkdownSuccess,
        type: NotificationType.success,
      );
    } else {
      _showSaveError();
    }
  }

  Future<void> _saveWithExtension(String extension) async {
    final language = _coordinator.detectedLanguage;
    final saved = await _vm.saveAs((d) => NoteDraft(
          title: d.title,
          content: _rawText(),
          isEmpty: d.isEmpty,
          colorIndex: d.colorIndex,
          reminderDateTime: d.reminderDateTime,
          recurrenceRule: d.recurrenceRule,
          noteType: language == null
              ? _currentMode.name
              : _coordinator.smartController.mapLanguageToNoteType(language),
          isChecklist: d.isChecklist,
          isProfessional: d.isProfessional,
          categoryIds: d.categoryIds,
          isHiddenFromHome: d.isHiddenFromHome,
        ));
    if (!mounted) return;
    if (saved) {
      UnifiedNotificationService().show(
        context: context,
        message: AppLocalizations.of(context)!.savedSuccessfully,
        type: NotificationType.success,
      );
    } else {
      _showSaveError();
    }
  }

  /// النص كما في المتحكم (الكود أو النص الخام) — لتحويلات "حفظ باسم".
  String _rawText() => _currentMode == NoteMode.code
      ? _coordinator.codeController!.text
      : _coordinator.contentController.text;

  // ── DraftSource ───────────────────────────────────────────────────────────

  @override
  NoteDraft? takeDraft({required bool force}) {
    final state = _coordinator.stateManager;
    final newVaultNote = _vm.noteId == null && _vm.isLocked;
    if (!force && !newVaultNote && !state.hasChanges()) return null;

    final usesQuill =
        _currentMode != NoteMode.code && _currentMode != NoteMode.checklist;
    final quill = _coordinator.quillController;
    // المستند الكامل لم يُحمّل بعد (معاينة أول 20 سطراً): حفظه يقطع الملاحظة
    if (usesQuill &&
        (quill == null || !_coordinator.isQuillFullyLoaded) &&
        (widget.note?.content.isNotEmpty ?? false)) {
      return null;
    }

    final existing = _currentNote ?? widget.note;
    final content = switch (_currentMode) {
      NoteMode.code => _coordinator.codeController!.text,
      NoteMode.checklist => _coordinator.contentController.text,
      _ => quill == null ? '' : QuillMigration.toDeltaJson(quill),
    };
    final isEmpty = switch (_currentMode) {
      NoteMode.checklist =>
        EditorSaveManager.isContentEmpty(content, NoteMode.checklist),
      NoteMode.code => content.trim().isEmpty,
      _ => quill == null || QuillMigration.toPlainText(quill).trim().isEmpty,
    };
    final draft = NoteDraft(
      title: _coordinator.getCurrentTitle(_l10nRef?.newNoteTitle ?? 'New Note'),
      content: content,
      isEmpty: isEmpty,
      colorIndex: state.colorIndex,
      reminderDateTime: state.reminderDateTime,
      recurrenceRule: state.recurrenceRule,
      noteType: EditorSaveManager.determineNoteType(
        mode: _currentMode,
        detectedLanguage: _coordinator.detectedLanguage,
        isLanguageManuallySelected: _coordinator.isLanguageManuallySelected,
        existingNoteType: existing?.noteType,
        smartController: _coordinator.smartController,
      ),
      isChecklist: _currentMode == NoteMode.checklist,
      isProfessional:
          existing?.isProfessional ?? (_currentMode == NoteMode.code),
      categoryIds: List.of(state.categoryIds),
      isHiddenFromHome: state.isHiddenFromHome,
    );
    state.updateSnapshot();
    return draft;
  }

  @override
  void restoreDraft() => _coordinator.stateManager.markDirty();

  void _showSaved() {
    UnifiedNotificationService().show(
      context: context,
      message: AppLocalizations.of(context)!.noteSaved,
      type: NotificationType.success,
      duration: const Duration(seconds: 1),
    );
  }

  /// فشل الحفظ: يُعرض ويبقى المحرر مفتوحاً بالتعديلات.
  void _showSaveError() {
    if (_vm.error == null) return;
    UnifiedNotificationService().show(
      context: context,
      message: AppLocalizations.of(context)!.saveFailedKeepEditing,
      type: NotificationType.error,
    );
  }

  // ==================== LIFECYCLE METHODS ====================

  void _attachListeners() {
    _coordinator.contentController.addListener(_onContentChanged);
    _coordinator.undoController.addListener(_updateUndoRedoState);
    if (_currentMode == NoteMode.code && !_isReadOnly) {
      _coordinator.codeController!.addListener(_onContentChanged);
      _coordinator.codeUndoController.addListener(_updateUndoRedoState);
    }
    _updateUndoRedoState();
  }

  /// Initialize Quill controller when transitioning from readOnly to edit mode
  void _initQuillForEdit() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _coordinator.initializeQuillAsync();
      if (mounted) {
        _quillChangesSubscription?.cancel();
        if (_coordinator.quillController != null) {
          _quillChangesSubscription =
              _coordinator.quillController!.document.changes.listen((_) {
            _onQuillContentChanged();
            _updateUndoRedoState();
          });
          _coordinator.quillController!.addListener(_onQuillSelectionChanged);
        }
        setState(() {});
      }
    });
  }

  // ════════════════════ CONTENT CHANGE HANDLER (UNIFIED) ════════════════════

  /// معالج موحّد لتغييرات المحتوى — يُستخدم لكل الأنواع (Quill, Code, Plain)
  void _handleContentChange({
    required String currentText,
    Duration autosaveDelay = const Duration(milliseconds: 600),
  }) {
    if (_coordinator.stateManager.isLoading) return;
    if (_isReadOnly) return;

    _coordinator.stateManager.markDirty();

    final newHasContent = currentText.trim().isNotEmpty;
    if (_coordinator.stateManager.hasContent != newHasContent) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _coordinator.stateManager.hasContent = newHasContent);
        }
      });
    }

    _coordinator.autosaveTimer?.cancel();
    _coordinator.autosaveTimer = Timer(autosaveDelay, () {
      if (mounted && currentText.trim().isNotEmpty) _saveNoteToDatabase();
    });
  }

  void _onQuillContentChanged() {
    _handleContentChange(
      currentText: QuillMigration.toPlainText(_coordinator.quillController!),
      autosaveDelay: const Duration(milliseconds: 800),
    );
  }

  void _onContentChanged() {
    final currentText = _currentMode == NoteMode.code
        ? _coordinator.codeController!.text
        : _coordinator.contentController.text;
    _handleContentChange(
      currentText: currentText,
      autosaveDelay: const Duration(milliseconds: 500),
    );
  }

  /// يُعاد استدعاؤه عند تغيير الـ cursor/selection في Quill
  /// لتحديث حالة أزرار التنسيق (Bold/Italic/H1/إلخ) في الـ toolbar
  void _onQuillSelectionChanged() {
    if (mounted) _chrome.value++;
  }

  void _updateUndoRedoState() {
    if (_currentMode == NoteMode.checklist || !mounted) return;
    final bool canUndo, canRedo;
    if (_currentMode == NoteMode.code) {
      canUndo = _coordinator.codeUndoController.value.canUndo;
      canRedo = _coordinator.codeUndoController.value.canRedo;
    } else {
      final quill = _coordinator.quillController;
      if (quill == null) return;
      canUndo = quill.document.history.hasUndo;
      canRedo = quill.document.history.hasRedo;
    }
    final state = _coordinator.stateManager;
    if (state.canUndo == canUndo && state.canRedo == canRedo) return;
    state
      ..canUndo = canUndo
      ..canRedo = canRedo;
    _chrome.value++;
  }

  void _updateChecklistUndoRedo() {
    final history = _coordinator.checklistUndoRedo;
    final state = _coordinator.stateManager;
    if (history == null || !mounted) return;
    if (state.canUndo == history.canUndo && state.canRedo == history.canRedo) {
      return;
    }
    // الأزرار تتبع الحالة؛ إعادة البناء فقط حين تتغير
    setState(() {
      state.canUndo = history.canUndo;
      state.canRedo = history.canRedo;
    });
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

    _coordinator.autosaveTimer?.cancel();

    // ملاحظة مستلمة من الخارج — اسأل المستخدم قبل الحفظ
    if (widget.isSharedPreview && !_vm.isClosed) {
      final shouldSave = await _showSaveSharedNoteDialog();
      if (!mounted) return;
      if (shouldSave == true) {
        final saved =
            await _saveNoteToDatabase(forceUpdate: true, isManualSave: true);
        if (!mounted) return;
        if (!saved && _vm.error != null) return _showSaveError();
        if (saved) _showSaved();
      }
      _close(shouldSave == true);
      return;
    }

    if (!_vm.isClosed) {
      await _saveNoteToDatabase(isManualSave: true);
      if (!mounted) return;
      if (_vm.error != null) return _showSaveError();
      await _endVersionSession();
      if (!mounted) return;
      if (_vm.takeSavedFlag()) _showSaved();
    }
    _close(_vm.noteId != null);
  }

  void _close(bool result) {
    if (!mounted) return;
    if (widget.onClose != null) {
      widget.onClose!();
    } else {
      Navigator.of(context).pop(result);
    }
  }

  Future<bool?> _showSaveSharedNoteDialog() async {
    final l10n = AppLocalizations.of(context)!;
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.save),
        content: Text(l10n.saveThisNoteQuestion),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.discardChanges),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
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
            // المستند الكامل (لا معاينة أول 20 سطراً) قبل أي تحرير أو حفظ
            if (_currentMode == NoteMode.simple ||
                _currentMode == NoteMode.rich ||
                _currentMode == NoteMode.reminder) {
              _initQuillForEdit();
            }
          } else {
            if (_coordinator.stateManager.customTitle == null &&
                widget.note != null &&
                widget.note!.title.isNotEmpty &&
                widget.note!.title != 'Untitled') {
              _coordinator.stateManager.customTitle = widget.note!.title;
            }
            // Initialize Quill async if it was skipped in readOnly mode
            if (_currentMode == NoteMode.simple ||
                _currentMode == NoteMode.rich ||
                _currentMode == NoteMode.reminder) {
              _initQuillForEdit();
            }
          }
          setState(() => _isReadOnly = false);
          // ربط listener الكود عند الانتقال من القراءة إلى التحرير
          if (_currentMode == NoteMode.code &&
              _coordinator.codeController != null) {
            _coordinator.codeController!.addListener(_onContentChanged);
            _coordinator.codeUndoController.addListener(_updateUndoRedoState);
          }
        },
        onSave: ({bool isManualSave = false}) =>
            _saveNoteToDatabase(isManualSave: isManualSave),
      );
    }

    // وضع التعديل — المحرر الكامل
    // إذا لم يكتمل بناء QuillController بعد — نعرض skeleton بسيط
    if (!_isQuillReady && !_isReadOnly) {
      return Scaffold(
        backgroundColor: _coordinator.getBackgroundColor(context),
        body: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: _coordinator.getBackgroundColor(context).computeLuminance() >
                    0.5
                ? EditorPalette.faintOnLight
                : EditorPalette.faintOnDark,
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
            ValueListenableBuilder<int>(
              valueListenable: _chrome,
              builder: (context, _, __) => EditorBuildMethods.buildHeader(
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
                  if (_currentMode == NoteMode.rich &&
                      _looksLikeMarkdown(text)) {
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
                    ctrl.replaceText(offset, deleteLen, text,
                        TextSelection.collapsed(offset: offset + text.length));
                  }
                },
                onSaveTap: () async {
                  if (_currentMode == NoteMode.code &&
                      _coordinator.detectedLanguage != null) {
                    final ext = _coordinator.smartController
                        .getExtensionForLanguage(
                            _coordinator.detectedLanguage!);
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
            ),
            ValueListenableBuilder<int>(
              valueListenable: _chrome,
              builder: (context, _, __) => EditorBuildMethods.buildToolbar(
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
                        .getExtensionForLanguage(
                            _coordinator.detectedLanguage!);
                    await _showSmartSaveDialog(ext);
                  }
                },
                saveNote: _saveNote,
                onArchive: _archive,
                onDelete: _delete,
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
    final finalTextColor =
        isDarkBg ? EditorPalette.inkOnDark : EditorPalette.inkOnLight;
    final finalHintColor =
        isDarkBg ? EditorPalette.hintOnDark : EditorPalette.hintOnLight;
    final screenWidth = MediaQuery.of(context).size.width;
    final sidePadding = screenWidth > 600 ? 16.0 : screenWidth * 0.05;

    final base = _coordinator.getBackgroundColor(context);
    final isDarkBase = base.computeLuminance() < 0.5;
    final scrolled = Color.alphaBlend(
      isDarkBase
          ? EditorPalette.tintOnDark.withValues(alpha: 0.08)
          : EditorPalette.tintOnLight.withValues(alpha: 0.06),
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
    final cmd = _commands.lastCommand;
    if (cmd == null) return;

    // تحقق أن هذا المحرر هو المحرر النشط
    final myId = _coordinator.savedNoteId ?? widget.note?.id;
    final activeId = _commands.activeNoteId;
    final activeHash = _commands.activeEditorHash;
    if (myId == null || (activeId != null && myId != activeId)) return;
    if (activeHash != null && hashCode != activeHash) return;

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
        _archive();
      case EditorCommand.pin:
        _togglePin();
      case EditorCommand.duplicate:
        _duplicate();
      case EditorCommand.delete:
        _delete();
      case EditorCommand.category:
        _pickCategory();
    }
  }

  /// أرشفة الملاحظة (بعد حفظ ما فيها) مع snackbar تراجع
  Future<void> _archive() async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final provider = Provider.of<NotesProvider>(context, listen: false);
    final id = _vm.noteId;
    if (!await _vm.archive()) return _showSaveError();
    if (!mounted || id == null) return;
    UnifiedNotificationService().showWithUndo(
      context: context,
      message: l10n.movedToArchive,
      type: NotificationType.success,
      actionKey: 'menu_archive_$id',
      onExecute: () {},
      onUndo: () async => await provider.unarchiveNote(id),
      undoLabel: l10n.undo,
    );
    _close(true);
  }

  Future<void> _togglePin() async {
    final pinned = await _vm.togglePinned();
    if (pinned == null || !mounted) return _showSaveError();
    final l10n = AppLocalizations.of(context)!;
    UnifiedNotificationService().show(
      context: context,
      message: pinned ? l10n.pin : l10n.unpin,
      type: NotificationType.success,
      duration: const Duration(seconds: 2),
    );
  }

  /// تكرار الملاحظة (بعد حفظ ما فيها) مع snackbar
  Future<void> _duplicate() async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final copy = await _vm.duplicate(copyLabel: l10n.noteCopy);
    if (!mounted) return;
    if (copy == null) return _showSaveError();
    UnifiedNotificationService().show(
      context: context,
      message: l10n.noteCopied,
      type: NotificationType.success,
      duration: const Duration(seconds: 2),
    );
  }

  /// حذف الملاحظة — bottom sheet تأكيد مع snackbar تراجع
  Future<void> _delete() async {
    final noteId = _vm.noteId;
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
                  color: context.scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Icon(Icons.delete_outline_rounded,
                  size: 48, color: context.colors.danger),
              const SizedBox(height: 12),
              Text(
                l10n.deleteNote,
                style: context.text.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.deleteConfirm,
                textAlign: TextAlign.center,
                style: TextStyle(color: context.colors.muted),
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
                        backgroundColor: context.colors.danger,
                        foregroundColor: context.scheme.onError,
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
    if (!await _vm.trash()) return _showSaveError();
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
    _close(true);
  }

  /// فتح منتقي الكتالوج
  Future<void> _pickCategory() async {
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
          _coordinator.codeUndoController.undo();
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
          _coordinator.codeUndoController.redo();
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
        if (_currentMode == NoteMode.code) {
          _coordinator.codeUndoController.redo();
        } else if (_currentMode == NoteMode.checklist) {
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
      AppShortcuts.archive: _archive,
      AppShortcuts.pin: _togglePin,
      AppShortcuts.duplicate: _duplicate,
      AppShortcuts.delete: _delete,
    };
  }
}
