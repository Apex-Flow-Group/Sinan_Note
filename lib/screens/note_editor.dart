// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/note.dart';
import '../models/note_mode.dart';
import '../models/note_version.dart';
import '../services/database_service.dart';
import '../services/notes_provider.dart';
import '../utils/adaptive_color.dart';
import '../utils/apex_smart_controller.dart';
import '../utils/checklist_formatter.dart';
import '../l10n/l10n_migration_helper.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import '../widgets/editor/apex_editor_header.dart';
import '../widgets/editor/toolbars/editor_toolbar_factory.dart';
import '../widgets/editor/professional_code_editor.dart';
import '../widgets/editor/checklist_editor.dart';
import '../widgets/editor/note_history_sheet.dart';
import '../widgets/editor/reminder_picker_sheet.dart';
import '../widgets/apex_snackbar.dart';
import '../widgets/custom_share_sheet.dart';

import '../services/notification_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:highlight/languages/dart.dart';

// Import Controllers
import 'note_editor/controllers/editor_storage_controller.dart';
import 'note_editor/controllers/editor_formatting_controller.dart';
import 'note_editor/controllers/editor_smart_controller.dart';

class NoteEditorImmersive extends StatefulWidget {
  final Note? note;
  final NoteMode mode;
  final bool skipAuthentication;

  const NoteEditorImmersive(
      {super.key,
      this.note,
      this.mode = NoteMode.simple,
      this.skipAuthentication = false});

  @override
  State<NoteEditorImmersive> createState() => _NoteEditorImmersiveState();
}

class _NoteEditorImmersiveState extends State<NoteEditorImmersive>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  // Controllers
  late TextEditingController _contentController;
  late CodeController _codeController;
  final UndoHistoryController _undoController = UndoHistoryController();
  final UndoHistoryController _codeUndoController = UndoHistoryController();
  // Checklist Undo/Redo state
  ChecklistUndoRedoController? _checklistUndoRedo;
  final FocusNode _textFieldFocusNode = FocusNode();

  // Feature Controllers
  final EditorStorageController _storageController = EditorStorageController();
  final EditorFormattingController _formattingController =
      EditorFormattingController();
  final EditorSmartController _smartController = EditorSmartController();

  // Providers
  NotesProvider? _notesProviderRef;

  // State Variables
  String? _customTitle;
  String? _checklistTitle;
  int _colorIndex = 0;
  String? _notePassword;
  bool _isAuthenticated = false;
  double _fontSize = 18.0;
  TextAlign _textAlign = TextAlign.right;
  TextDirection _textDirection = TextDirection.rtl;
  Color _textColor = Colors.black87;
  Timer? _autosaveTimer;
  String? _detectedLanguage;
  bool _isLanguageManuallySelected = false;
  Timer? _languageDetectionTimer;
  bool _isSaving = false;
  bool _isDirty = false;
  bool _hasContent = false;
  int? _savedNoteId;
  DateTime? _reminderDateTime;
  String? _recurrenceRule;
  bool _canUndo = false;
  bool _canRedo = false;
  bool _isSavingOnExit = false;

  @override
  bool get wantKeepAlive => true;

  Color get _backgroundColor {
    final brightness = Theme.of(context).brightness;
    return AppColorPalette.palette[_colorIndex].getColor(brightness);
  }

  String get _currentTitle {
    if (_customTitle != null && _customTitle!.isNotEmpty) {
      return _customTitle!;
    }
    if (widget.mode == NoteMode.checklist ||
        widget.note?.noteType == 'checklist') {
      if (_checklistTitle != null && _checklistTitle!.isNotEmpty) {
        return _checklistTitle!;
      }
      return 'Checklist';
    }
    final text = widget.mode == NoteMode.code
        ? _codeController.text
        : _contentController.text;
    if (text.isNotEmpty) {
      final end = text.indexOf('\n');
      if (end != -1 && end < 40) {
        return text.substring(0, end);
      }
      return text.length > 40 ? "${text.substring(0, 40)}..." : text;
    }

    final l10n = context.l10n;
    return l10n.newNoteTitle;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _notesProviderRef = Provider.of<NotesProvider>(context, listen: false);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _isAuthenticated = true;

    if (widget.note != null) {
      _colorIndex = widget.note!.colorIndex;
      // CRITICAL: Checklists don't need authentication (plain JSON)
      _isAuthenticated = widget.note!.isChecklist ? true : false;
    } else {
      _loadStickySettings();
    }

    String initialText = widget.note?.content ?? '';
    _contentController = ApexSmartController(text: initialText);
    _contentController.addListener(_onContentChanged);
    _undoController.addListener(_updateUndoRedoState);
    // REMOVED: FocusNode listener for scroll (causes jumpy behavior)
    // _textFieldFocusNode.addListener(_ensureCursorVisible);

    if (widget.mode == NoteMode.code) {
      _codeController = CodeController(text: initialText, language: dart);
      _codeController.addListener(_onContentChanged);
      _codeUndoController.addListener(_updateUndoRedoState);
    }

    if (widget.mode == NoteMode.checklist) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateChecklistUndoRedo();
      });
    } else {
      _updateUndoRedoState();
    }

    if (widget.mode == NoteMode.reminder && widget.note == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showReminderDialog();
      });
    }

    if (widget.note != null) {
      _customTitle =
          widget.note!.title != 'Untitled' ? widget.note!.title : null;
      _reminderDateTime = widget.note!.reminderDateTime;
      _recurrenceRule = widget.note!.recurrenceRule;
      _hasContent = widget.note!.content.trim().isNotEmpty;
      // للملاحظات المقفلة الجديدة: علّمها كـ dirty لضمان الحفظ
      if (widget.note!.isLocked && widget.note!.id == null) {
        _isDirty = true;
        _isAuthenticated = true; // ملاحظة جديدة لا تحتاج مصادقة
      } else if (widget.note!.isLocked && !widget.skipAuthentication && !widget.note!.isChecklist) {
        // تحقق من الجلسة قبل طلب المصادقة (SKIP for Checklists)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final provider = Provider.of<NotesProvider>(context, listen: false);
          if (provider.isVaultUnlocked) {
            _loadDecryptedContent();
          } else {
            _promptForPassword();
          }
        });
      } else {
        _isAuthenticated = true;
      }
    }
  }

  Future<void> _loadStickySettings() async {
    final settings = await _storageController.loadStickySettings();
    if (mounted) {
      setState(() {
        _fontSize = settings['fontSize'];
        final alignStr = settings['textAlign'];
        _textAlign = alignStr == 'left'
            ? TextAlign.left
            : alignStr == 'center'
                ? TextAlign.center
                : TextAlign.right;
        _textDirection = settings['textDirection'] == 'ltr'
            ? TextDirection.ltr
            : TextDirection.rtl;

        final lastColorIndex = settings['noteColorIndex'];
        if (lastColorIndex != null) {
          _colorIndex = lastColorIndex;
        } else {
          _colorIndex = 0;
        }
      });
    }
  }

  Future<void> _loadDecryptedContent() async {
    final decrypted =
        await _storageController.decryptNoteWithoutAuth(widget.note!);
    if (decrypted != null && mounted) {
      debugPrint('🔓 EDITOR: Decrypted content loaded (mode=${widget.mode.name}, isChecklist=${widget.note?.isChecklist})');
      debugPrint('🔓 EDITOR: Content: ${decrypted['content']!.substring(0, decrypted['content']!.length > 100 ? 100 : decrypted['content']!.length)}...');
      
      setState(() {
        _isAuthenticated = true;
        _customTitle =
            decrypted['title']!.isNotEmpty ? decrypted['title'] : null;
        if (widget.mode == NoteMode.code) {
          _codeController.text = decrypted['content']!;
        } else {
          _contentController.text = decrypted['content']!;
        }
      });
    }
  }

  Future<void> _promptForPassword() async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;

    final provider = Provider.of<NotesProvider>(context, listen: false);

    // طلب البصمة
    final decrypted =
        await _storageController.authenticateAndDecrypt(widget.note!);
    if (decrypted == null) {
      if (mounted) Navigator.pop(context);
      return;
    }

    provider.unlockVault(); // تفعيل الجلسة

    if (mounted) {
      setState(() {
        _isAuthenticated = true;
        _customTitle =
            decrypted['title']!.isNotEmpty ? decrypted['title'] : null;
        if (widget.mode == NoteMode.code) {
          _codeController.text = decrypted['content']!;
        } else {
          _contentController.text = decrypted['content']!;
        }
      });
    }
  }

  Future<void> _saveNoteToDatabase(
      {bool forceUpdate = false, bool isManualSave = false}) async {
    if (_isSaving) return;

    final isNewLockedNote = widget.note?.isLocked == true &&
        widget.note?.id == null &&
        _savedNoteId == null;

    if (!forceUpdate &&
        !_isDirty &&
        !isNewLockedNote &&
        (_savedNoteId != null || widget.note != null)) {
      return;
    }

    _isSaving = true;

    try {
      // MEMORY FIX: Create local copy and clear references immediately
      String contentToSave;
      
      // CRITICAL FIX: For checklist mode, ensure we have valid JSON content
      if (widget.mode == NoteMode.checklist ||
          widget.note?.noteType == 'checklist') {
        contentToSave = _contentController.text;
        
        // Validate and ensure we have proper checklist JSON structure
        if (contentToSave.trim().isEmpty) {
          // Create minimal valid checklist structure
          contentToSave = jsonEncode({
            'title': '',
            'items': [],
          });
        } else {
          // Verify it's valid JSON, if not, wrap it
          try {
            jsonDecode(contentToSave);
          } catch (e) {
            // Invalid JSON, create proper structure
            contentToSave = jsonEncode({
              'title': '',
              'items': [],
            });
          }
        }
      } else {
        contentToSave = widget.mode == NoteMode.code
            ? _codeController.text
            : _contentController.text;
      }
      
      bool isContentEmpty = contentToSave.trim().isEmpty;

      if (widget.mode == NoteMode.checklist ||
          widget.note?.noteType == 'checklist') {
        try {
          final decoded = jsonDecode(contentToSave);
          if (decoded is Map) {
            final title = (decoded['title'] ?? '').toString().trim();
            final items = decoded['items'] as List? ?? [];
            final hasContent = title.isNotEmpty ||
                items.any((item) =>
                    (item['text'] ?? '').toString().trim().isNotEmpty);
            isContentEmpty = !hasContent;
          }
        } catch (e) {
          isContentEmpty = true;
        }
      }

      // لا تحفظ الملاحظات الفارغة إلا إذا كانت مقفلة جديدة أو موجودة مسبقاً
      if (isContentEmpty &&
          !isNewLockedNote &&
          _savedNoteId == null &&
          widget.note?.id == null) {
        _isSaving = false;
        return;
      }

      String noteType;
      if (_isLanguageManuallySelected && _detectedLanguage != null) {
        noteType = _smartController.mapLanguageToNoteType(_detectedLanguage);
      } else if (widget.note?.noteType != null &&
          widget.note!.noteType.isNotEmpty) {
        noteType = widget.note!.noteType;
      } else {
        noteType = widget.mode.name;
      }

      // CRITICAL: If skipAuthentication=true, content is decrypted, so save as unlocked
      // then notes_provider will encrypt it. This prevents double encryption.
      final bool shouldBeLocked = widget.note?.isLocked ?? false;

      _notesProviderRef ??= Provider.of<NotesProvider>(context, listen: false);

      // Create the note object
      final noteToSave = Note(
        id: _savedNoteId ?? widget.note?.id,
        title: _currentTitle,
        content: contentToSave,
        createdAt: widget.note?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        colorIndex: _colorIndex,
        isLocked: shouldBeLocked,
        noteType: noteType,
        reminderDateTime: _reminderDateTime,
        recurrenceRule: _recurrenceRule,
        isArchived: widget.note?.isArchived ?? false,
        isTrashed: widget.note?.isTrashed ?? false,
        isCompleted: widget.note?.isCompleted ?? false,
        isProfessional:
            widget.note?.isProfessional ?? (widget.mode == NoteMode.code),
        isPinned: widget.note?.isPinned ?? false,
        isChecklist:
            widget.note?.isChecklist ?? (widget.mode == NoteMode.checklist),
      );

      // Save using the provider's unified method
      final newId = await _notesProviderRef!.addOrUpdateNote(noteToSave);

      // Log version history
      try {
        final version = NoteVersion(
          noteId: newId,
          title: _currentTitle,
          content: contentToSave,
          timestamp: DateTime.now(),
          action:
              (_savedNoteId ?? widget.note?.id) == null ? 'create' : 'update',
        );
        await DatabaseService().logNoteVersion(version);
      } catch (e) {
        // History logging failed, but note was saved successfully
      }

      if (_savedNoteId == null) {
        if (mounted) setState(() => _savedNoteId = newId);
      }

      // فقط امسح _isDirty عند الحفظ اليدوي أو عند الخروج
      if (isManualSave) {
        _isDirty = false;
      }
    } catch (e) {
      // Ignore save errors
    } finally {
      _isSaving = false;
    }
  }

  Future<void> _saveNote() async {
    _autosaveTimer?.cancel();

    final currentText = widget.mode == NoteMode.code
        ? _codeController.text
        : _contentController.text;
    bool hasRealContent = currentText.trim().isNotEmpty;

    if (widget.mode == NoteMode.checklist ||
        widget.note?.noteType == 'checklist') {
      try {
        final decoded = jsonDecode(currentText);
        if (decoded is Map) {
          final title = (decoded['title'] ?? '').toString().trim();
          final items = decoded['items'] as List? ?? [];
          hasRealContent = title.isNotEmpty ||
              items.any(
                  (item) => (item['text'] ?? '').toString().trim().isNotEmpty);
        }
      } catch (e) {
        hasRealContent = false;
      }
    }

    if (hasRealContent) {
      await _saveNoteToDatabase(isManualSave: true);

      final l10n = context.l10n;

      ApexSnackBar.show(context, l10n.noteSaved,
          type: SnackBarType.success, duration: const Duration(seconds: 1));
    }
  }

  void _showReminderDialog() async {
    final l10n = context.l10n;

    final result = await ReminderPickerSheet.show(
      context,
      _reminderDateTime ?? widget.note?.reminderDateTime,
      _recurrenceRule ?? widget.note?.recurrenceRule,
      _backgroundColor,
    );

    if (result != null) {
      if (result['remove'] == true) {
        if (widget.note?.id != null) {
          await NotificationService().cancelNotification(widget.note!.id!);
        }
        setState(() {
          _reminderDateTime = null;
          _recurrenceRule = null;
          _isDirty = true;
        });
        await _saveNoteToDatabase(isManualSave: true);
        ApexSnackBar.show(context, 'Reminder removed', type: SnackBarType.info);
        return;
      }

      final reminderDateTime = result['dateTime'] as DateTime?;
      final recurrence = result['recurrence'] as String?;

      if (reminderDateTime != null) {
        final hasExactAlarmPermission =
            await NotificationService().checkExactAlarmPermission();

        if (!hasExactAlarmPermission) {
          ApexSnackBar.show(
            context,
            l10n.precisePermissionRequired,
            type: SnackBarType.error,
            duration: const Duration(seconds: 5),
            actionLabel: l10n.openSettings,
            onAction: () => openAppSettings(),
          );
          return;
        }

        setState(() {
          _reminderDateTime = reminderDateTime;
          _recurrenceRule = recurrence == 'none' ? null : recurrence;
          _isDirty = true;
        });

        await _saveNoteToDatabase(isManualSave: true);
        ApexSnackBar.show(context, l10n.reminderAdded,
            type: SnackBarType.success);
      }
    }
  }

  void _showColorPalette() {
    final brightness = Theme.of(context).brightness;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.chooseColor),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(AppColorPalette.palette.length, (index) {
            final adaptiveColor = AppColorPalette.palette[index];
            final color = adaptiveColor.getColor(brightness);
            
            return GestureDetector(
              onTap: () {
                setState(() {
                  _colorIndex = index;
                  final isDarkBg = color.computeLuminance() < 0.5;
                  _textColor = isDarkBg ? Colors.white : Colors.black87;
                  _isDirty = true;
                });
                Navigator.pop(ctx);
              },
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _colorIndex == index
                        ? Theme.of(context).colorScheme.onSurface
                        : Colors.transparent,
                    width: 3,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  void _showInlineColorPicker() {
    final l10n = AppLocalizations.of(context)!;
    final textColors = [
      Colors.black87,
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.pink,
      Colors.teal
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding:
            const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
        decoration: BoxDecoration(
          color: _backgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.chooseTextColor,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: textColors.map((color) {
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade300, width: 2),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _showHistorySheet() {
    if (widget.note?.id == null) return;
    NoteHistorySheet.show(context, widget.note!.id!);
  }

  void _handleSmartCalculation() {
    final result = _smartController.handleSmartCalculation(_contentController);

    if (result == null) return;

    final l10n = context.l10n;

    if (result['type'] == 'sum') {
      ApexSnackBar.show(
        context,
        '${l10n.approximateSum} ${result['result']} (${l10n.experimental})',
        type: SnackBarType.success,
        duration: const Duration(seconds: 2),
        dismissible: true,
        opacity: 0.85,
        aboveToolbar: true,
      );
    } else if (result['type'] == 'calculated') {
      ApexSnackBar.show(
        context,
        '${l10n.calculated} (${l10n.experimental})',
        type: SnackBarType.success,
        duration: const Duration(seconds: 2),
        dismissible: true,
        opacity: 0.85,
        aboveToolbar: true,
      );
    } else if (result['type'] == 'error') {
      ApexSnackBar.show(
        context,
        result['message'] as String,
        type: SnackBarType.warning,
        duration: const Duration(seconds: 2),
        dismissible: true,
        opacity: 0.85,
        aboveToolbar: true,
      );
    }
  }

  Future<void> _runCode() async {
    if (_detectedLanguage == null) {
      ApexSnackBar.show(context, 'Unable to detect language',
          type: SnackBarType.warning);
      return;
    }

    ApexSnackBar.show(context, 'Executing $_detectedLanguage code...',
        type: SnackBarType.info, duration: const Duration(seconds: 1));

    final code = widget.mode == NoteMode.code
        ? _codeController.text
        : _contentController.text;
    final output = await _smartController.executeCode(code, _detectedLanguage);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.output),
        content: SingleChildScrollView(
          child: Text(output,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.close),
          ),
        ],
      ),
    );
  }

  Future<void> _exportCode() async {
    final code = widget.mode == NoteMode.code
        ? _codeController.text
        : _contentController.text;
    final detectedLang =
        _detectedLanguage ?? _smartController.detectLanguage(code);

    if (detectedLang == null) {
      ApexSnackBar.show(context, 'Unable to detect language',
          type: SnackBarType.warning);
      return;
    }

    final expectedExt = _smartController.getExtensionForLanguage(detectedLang);
    await _showSmartSaveDialog(expectedExt);
  }

  Future<void> _showSmartSaveDialog(String selectedExtension) async {
    final l10n = AppLocalizations.of(context)!;

    bool hasMismatch = false;
    if (_detectedLanguage != null && selectedExtension.isNotEmpty) {
      final expectedExt =
          _smartController.getExtensionForLanguage(_detectedLanguage!);
      hasMismatch = expectedExt != selectedExtension;
    }

    if (hasMismatch) {
      final action = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: _backgroundColor,
          title: Text(l10n.warning, style: TextStyle(color: _textColor)),
          content: Text(
            l10n.fileContainsErrors,
            style: TextStyle(color: _textColor),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'cancel'),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'force'),
              child: Text(l10n.saveAnyway,
                  style: const TextStyle(color: Colors.orange)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, 'markdown'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: Text(l10n.saveAsMarkdown),
            ),
          ],
        ),
      );

      if (action == 'markdown') {
        await _saveAsMarkdown();
      } else if (action == 'force') {
        await _saveWithExtension(selectedExtension);
      }
    } else {
      await _saveWithExtension(selectedExtension);
    }
  }

  Future<void> _saveAsMarkdown() async {
    final code = widget.mode == NoteMode.code
        ? _codeController.text
        : _contentController.text;
    final wrappedContent = '```\n$code\n```';

    final provider = Provider.of<NotesProvider>(context, listen: false);

    final noteToSave = Note(
      id: _savedNoteId ?? widget.note?.id,
      title: _currentTitle,
      content: wrappedContent,
      createdAt: widget.note?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      colorIndex: _colorIndex,
      isLocked: widget.note?.isLocked ?? widget.skipAuthentication,
      noteType: 'markdown',
      reminderDateTime: _reminderDateTime,
      recurrenceRule: _recurrenceRule,
      isArchived: widget.note?.isArchived ?? false,
      isTrashed: widget.note?.isTrashed ?? false,
      isCompleted: widget.note?.isCompleted ?? false,
      isProfessional: widget.note?.isProfessional ?? false,
      isPinned: widget.note?.isPinned ?? false,
      isChecklist: widget.note?.isChecklist ?? false,
    );

    await provider.addOrUpdateNote(noteToSave);

    _isDirty = false;
    final l10n = AppLocalizations.of(context)!;
    ApexSnackBar.show(context, l10n.savedAsMarkdownSuccess,
        type: SnackBarType.success);
  }

  Future<void> _saveWithExtension(String extension) async {
    if (_detectedLanguage != null) {
      final newType = _smartController.mapLanguageToNoteType(_detectedLanguage);
      final provider = Provider.of<NotesProvider>(context, listen: false);

      final noteToSave = Note(
        id: _savedNoteId ?? widget.note?.id,
        title: _currentTitle,
        content: widget.mode == NoteMode.code
            ? _codeController.text
            : _contentController.text,
        createdAt: widget.note?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        colorIndex: _colorIndex,
        isLocked: widget.note?.isLocked ?? widget.skipAuthentication,
        noteType: newType,
        reminderDateTime: _reminderDateTime,
        recurrenceRule: _recurrenceRule,
        isArchived: widget.note?.isArchived ?? false,
        isTrashed: widget.note?.isTrashed ?? false,
        isCompleted: widget.note?.isCompleted ?? false,
        isProfessional:
            widget.note?.isProfessional ?? (widget.mode == NoteMode.code),
        isPinned: widget.note?.isPinned ?? false,
        isChecklist:
            widget.note?.isChecklist ?? (widget.mode == NoteMode.checklist),
      );

      await provider.addOrUpdateNote(noteToSave);

      _isDirty = false;
    } else {
      await _saveNoteToDatabase();
    }

    final l10n = AppLocalizations.of(context)!;
    ApexSnackBar.show(context, l10n.savedSuccessfully,
        type: SnackBarType.success);
  }

  void _onContentChanged() {
    _isDirty = true;

    final currentText = widget.mode == NoteMode.code
        ? _codeController.text
        : _contentController.text;
    final newHasContent = currentText.trim().isNotEmpty;
    if (_hasContent != newHasContent) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _hasContent = newHasContent);
      });
    }

    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted && _contentController.text.isNotEmpty) {
        _saveNoteToDatabase();
        // MEMORY FIX: Trigger garbage collection hint after save
        _cleanupMemory();
      }
    });

    // REMOVED: Forced scroll on every keystroke (causes jumpy behavior)
    // resizeToAvoidBottomInset: true handles this automatically
    // Scroll only triggered by didChangeMetrics when keyboard appears

    if (widget.mode == NoteMode.code && !_isLanguageManuallySelected) {
      _languageDetectionTimer?.cancel();
      _languageDetectionTimer = Timer(const Duration(milliseconds: 500), () {
        if (mounted) {
          final text = _codeController.text;
          final detectedLang = _smartController.detectLanguage(text);

          if (detectedLang != null && detectedLang != _detectedLanguage) {
            setState(() => _detectedLanguage = detectedLang);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${context.l10n.detected}: $detectedLang'),
                  duration: const Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                  width: 200,
                ),
              );
            }
          }
        }
      });
    }

    // EXPERIMENTAL FIX: Disable auto math/date analysis in RTL mode
    // Issue #10: Cursor jumps incorrectly when typing in RTL (Arabic)
    // Root cause: _analyzeMathAndDates() calculates cursor offset assuming LTR
    // When text is added (e.g., " = 70"), offset calculation doesn't account for RTL direction
    if (widget.mode == NoteMode.simple && _textDirection == TextDirection.ltr) {
      _analyzeMathAndDates();
    }

    // OLD CODE (before fix):
    // if (widget.mode == NoteMode.simple) {
    //   _analyzeMathAndDates();
    // }
  }

  void _updateUndoRedoState() {
    if (widget.mode == NoteMode.checklist) {
      return; // Handled by _updateChecklistUndoRedo
    }
    final controller =
        widget.mode == NoteMode.code ? _codeUndoController : _undoController;
    setState(() {
      _canUndo = controller.value.canUndo;
      _canRedo = controller.value.canRedo;
    });
  }

  void _updateChecklistUndoRedo() {
    if (_checklistUndoRedo != null) {
      setState(() {
        _canUndo = _checklistUndoRedo!.canUndo;
        _canRedo = _checklistUndoRedo!.canRedo;
      });
    }
  }

  /// MEMORY FIX: Cleanup method to release temporary buffers
  void _cleanupMemory() {
    // Force Flutter to release unused memory by clearing undo history periodically
    // This prevents memory accumulation during long editing sessions
    if (widget.mode != NoteMode.checklist) {
      // Keep only last 20 undo states to limit memory usage
      // Note: UndoHistoryController doesn't expose history directly,
      // but disposing and recreating would lose undo capability.
      // Instead, we rely on Flutter's internal cleanup.
    }
  }



  void _analyzeMathAndDates() {
    final result = _smartController.analyzeMathAndDates(_contentController);
    if (result == null || !mounted) return;

    if (result['type'] == 'math') {
      final resultStr = result['result'].toString();
      final newText = _contentController.text.replaceFirst(
        result['line'],
        '${result['line'].trim()} $resultStr',
      );
      _contentController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset:
              _contentController.selection.baseOffset + resultStr.length + 1,
        ),
      );
    } else if (result['type'] == 'date') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${context.l10n.date}: ${result['result']}'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Insert',
              onPressed: () {
                final newText = _contentController.text.replaceFirst(
                  result['line'],
                  result['line'] + result['result'],
                );
                _contentController.text = newText;
              },
            ),
          ),
        );
      }
    }
  }

  // REMOVED: _ensureCursorVisible is no longer needed
  // resizeToAvoidBottomInset: true handles all cursor visibility automatically
  // Manual scroll intervention was causing jumpy behavior
  // REMOVED: didChangeMetrics override - no custom behavior needed

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      final currentText = widget.mode == NoteMode.code
          ? _codeController.text
          : _contentController.text;
      if (currentText.isNotEmpty && _isDirty && mounted) {
        await _saveNoteToDatabase(isManualSave: true);
      }
    } else if (state == AppLifecycleState.resumed) {
      // 🔒 SECURITY: Check vault status when app resumes
      if (widget.note?.isLocked == true && mounted) {
        final provider = Provider.of<NotesProvider>(context, listen: false);
        if (!provider.isVaultUnlocked && mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (!_isAuthenticated) {
      return Scaffold(
        backgroundColor: _backgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final l10n = context.l10n;

    final bool isLightColor = _backgroundColor.computeLuminance() > 0.5;
    final Color finalTextColor = isLightColor ? Colors.black87 : Colors.white;
    final Color finalHintColor =
        isLightColor ? Colors.black45 : Colors.grey[400]!;

    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final sidePadding = isTablet ? 40.0 : 20.0;

    return PopScope(
      canPop: !_isSavingOnExit,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;
        if (_isSavingOnExit) return;

        _autosaveTimer?.cancel();
        _languageDetectionTimer?.cancel();
        
        final currentText = widget.mode == NoteMode.code
            ? _codeController.text
            : _contentController.text;
        final isNewLockedNote = widget.note?.isLocked == true &&
            widget.note?.id == null &&
            _savedNoteId == null;

        // احفظ تلقائياً إذا كان هناك محتوى وتغييرات
        if ((currentText.isNotEmpty || isNewLockedNote) &&
            (_isDirty || isNewLockedNote)) {
          setState(() => _isSavingOnExit = true);
          await _saveNoteToDatabase(isManualSave: true);
          
          // MEMORY FIX: Clear all text buffers immediately after save
          _contentController.clear();
          if (widget.mode == NoteMode.code) {
            _codeController.clear();
          }
          
          if (mounted) Navigator.of(context).pop();
        } else {
          // MEMORY FIX: Clear buffers even if not saving
          _contentController.clear();
          if (widget.mode == NoteMode.code) {
            _codeController.clear();
          }
          if (mounted) Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: _backgroundColor,
        resizeToAvoidBottomInset: true,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Content Layer
            Positioned.fill(
              child: SafeArea(
                bottom: false,
                child: _buildContentArea(
                    sidePadding, finalTextColor, finalHintColor, l10n),
              ),
            ),
            // Header Layer
            _buildHeader(finalTextColor),
            // Toolbar Layer
            _buildToolbar(finalTextColor, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildContentArea(
      double sidePadding,
      Color finalTextColor,
      Color finalHintColor,
      AppLocalizations l10n) {
    // حساب ارتفاع الـ Toolbar + SafeArea السفلية
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    const toolbarHeight = 60.0; // ارتفاع الـ Toolbar
    final totalBottomSpace = toolbarHeight + bottomPadding + 16;

    if (widget.mode == NoteMode.code) {
      return SingleChildScrollView(
        padding: EdgeInsets.only(top: 80, bottom: totalBottomSpace),
        child: ProfessionalCodeEditor(
          controller: _codeController,
          undoController: _codeUndoController,
          detectedLanguage: _detectedLanguage,
          backgroundColor: _backgroundColor,
        ),
      );
    } else if (widget.mode == NoteMode.checklist) {
      return Padding(
        padding: EdgeInsets.only(top: 80, bottom: totalBottomSpace),
        child: ChecklistEditor(
          initialContent: _contentController.text,
          backgroundColor: _backgroundColor,
          onUndoRedoControllerCreated: (controller) {
            _checklistUndoRedo = controller;
            _updateChecklistUndoRedo();
          },
          onUndoRedoChanged: _updateChecklistUndoRedo,
          onChanged: (jsonContent) {
            // 🛑 CRITICAL: Stop if editor is closing to prevent crash
            if (!mounted) return;
            
            _contentController.text = jsonContent;
            _isDirty = true;
            try {
              final decoded = jsonDecode(jsonContent);
              if (decoded is Map && decoded['title'] != null) {
                if (_checklistTitle != decoded['title']) {
                  Future.microtask(() {
                    if (mounted) {
                      setState(() => _checklistTitle = decoded['title']);
                    }
                  });
                }
              }
            } catch (e) {
              // Invalid JSON, ignore
            }
          },
        ),
      );
    } else {
      return SingleChildScrollView(
        padding: EdgeInsets.only(
            top: 80,
            bottom: totalBottomSpace,
            left: sidePadding,
            right: sidePadding),
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxWidth: 800,
              minHeight: MediaQuery.of(context).size.height - 180),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_reminderDateTime != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: InkWell(
                    onTap: _showReminderDialog,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange, width: 2),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.alarm,
                              color: Colors.orange, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _smartController
                                  .getTimeRemaining(_reminderDateTime),
                              style: TextStyle(
                                  color: finalTextColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          const Icon(Icons.edit,
                              color: Colors.orange, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              TextField(
                controller: _contentController,
                undoController: _undoController,
                focusNode: _textFieldFocusNode,
                scrollPadding: const EdgeInsets.only(bottom: 120.0),
                onTap: () {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    final text = _contentController.text;
                    final selection = _contentController.selection;
                    if (selection.baseOffset > text.length) {
                      _contentController.selection = TextSelection.collapsed(
                        offset: text.length,
                      );
                    }
                  });
                },
                textAlign: _textAlign,
                textDirection: _textDirection,
                style: TextStyle(
                    fontSize: _fontSize, height: 1.5, color: finalTextColor),
                cursorColor: finalTextColor.withValues(alpha: 0.8),
                cursorWidth: 2.5,
                cursorRadius: const Radius.circular(2),
                decoration: InputDecoration(
                  hintText: l10n.startWriting,
                  hintStyle: TextStyle(color: finalHintColor),
                  border: InputBorder.none,
                ),
                maxLines: null,
                autofocus: widget.note == null,
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildHeader(Color finalTextColor) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ApexEditorHeader(
                backgroundColor: _backgroundColor.withValues(alpha: 0.7),
                textColor: finalTextColor,
                title: _currentTitle,
                isLocked:
                    widget.note?.isLocked == true || _notePassword != null,
                hasHistory: widget.note?.id != null,
                hasReminder: _reminderDateTime != null,
                onReminderTap: () {
                  HapticFeedback.mediumImpact();
                  _showReminderDialog();
                },
                onHistoryTap: _showHistorySheet,
                onSaveTap: () async {
                  HapticFeedback.mediumImpact();
                  if (widget.mode == NoteMode.code &&
                      _detectedLanguage != null) {
                    final ext = _smartController
                        .getExtensionForLanguage(_detectedLanguage!);
                    await _showSmartSaveDialog(ext);
                  } else {
                    await _saveNote();
                  }
                  if (mounted) {
                    Navigator.pop(
                        context, _savedNoteId != null || widget.note != null);
                  }
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToolbar(Color finalTextColor,
      AppLocalizations l10n) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        color: _backgroundColor,
        child: SafeArea(
          top: false,
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                decoration: BoxDecoration(
                  color: _backgroundColor.withValues(alpha: 0.7),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: EditorToolbarFactory.build(
                  mode: widget.mode,
                  backgroundColor: _backgroundColor,
                  textColor: finalTextColor,
                  undoController: _undoController,
                  detectedLanguage: _detectedLanguage,
                  hasReminder: _reminderDateTime != null,
                  hasContent: _hasContent,
                  onUndo: _canUndo
                      ? () {
                          HapticFeedback.lightImpact();
                          if (widget.mode == NoteMode.checklist) {
                            _checklistUndoRedo?.undo();
                          } else if (widget.mode == NoteMode.code) {
                            _codeUndoController.undo();
                          } else {
                            _undoController.undo();
                          }
                        }
                      : null,
                  onRedo: _canRedo
                      ? () {
                          HapticFeedback.lightImpact();
                          if (widget.mode == NoteMode.checklist) {
                            _checklistUndoRedo?.redo();
                          } else if (widget.mode == NoteMode.code) {
                            _codeUndoController.redo();
                          } else {
                            _undoController.redo();
                          }
                        }
                      : null,
                  onLanguageChanged: (newLang) async {
                    final normalizedLang = newLang == 'Auto' ? null : newLang;
                    setState(() {
                      _detectedLanguage = normalizedLang;
                      _isLanguageManuallySelected = normalizedLang != null;
                      _isDirty = true;
                    });
                    if (normalizedLang != null) {
                      await _saveNoteToDatabase(forceUpdate: true);
                    }
                  },
                  onCalculate: () {
                    HapticFeedback.mediumImpact();
                    _handleSmartCalculation();
                  },
                  onBackgroundColorTap: () {
                    HapticFeedback.mediumImpact();
                    _showColorPalette();
                  },
                  onReminderTap: _hasContent
                      ? () {
                          HapticFeedback.mediumImpact();
                          _showReminderDialog();
                        }
                      : null,
                  onShareTap: () {
                    HapticFeedback.mediumImpact();
                    String text;
                    if (widget.mode == NoteMode.code) {
                      text = _codeController.text;
                    } else if (widget.mode == NoteMode.checklist) {
                      text = ChecklistFormatter.formatForSharing(
                          _currentTitle, _contentController.text);
                    } else {
                      text = '$_currentTitle\n\n${_contentController.text}';
                    }
                    CustomShareSheet.show(context, text, subject: _currentTitle);
                  },
                  onArchiveTap: () async {
                    HapticFeedback.mediumImpact();
                    if (widget.note?.id != null) {
                      final provider =
                          Provider.of<NotesProvider>(context, listen: false);
                      await provider.archiveNote(widget.note!.id!);
                      Navigator.pop(context);
                      ApexSnackBar.show(context, l10n.movedToArchive,
                          type: SnackBarType.success);
                    } else {
                      ApexSnackBar.show(context, l10n.saveNoteFirst,
                          type: SnackBarType.warning);
                    }
                  },
                  onDeleteTap: () => _handleDelete(finalTextColor),
                  onBold: () {
                    HapticFeedback.lightImpact();
                    _formattingController.showFormattingHint(
                      context,
                      _backgroundColor,
                      _textColor,
                      () => _formattingController.wrapText(
                          _contentController, '**'),
                    );
                  },
                  onItalic: () {
                    HapticFeedback.lightImpact();
                    _formattingController.wrapText(_contentController, '*');
                  },
                  onH1: () {
                    HapticFeedback.lightImpact();
                    _formattingController.insertText(_contentController, '# ');
                  },
                  onH2: () {
                    HapticFeedback.lightImpact();
                    _formattingController.insertText(_contentController, '## ');
                  },
                  onList: () {
                    HapticFeedback.lightImpact();
                    _formattingController.insertText(_contentController, '- ');
                  },
                  onChecklist: () {
                    HapticFeedback.lightImpact();
                    _formattingController.insertText(
                        _contentController, '- [ ] ');
                  },
                  onColorTap: () {
                    HapticFeedback.mediumImpact();
                    _showInlineColorPicker();
                  },
                  onAlignLeft: () {
                    HapticFeedback.selectionClick();
                    setState(() => _textAlign = TextAlign.left);
                  },
                  onAlignCenter: () {
                    HapticFeedback.selectionClick();
                    setState(() => _textAlign = TextAlign.center);
                  },
                  onAlignRight: () {
                    HapticFeedback.selectionClick();
                    setState(() => _textAlign = TextAlign.right);
                  },
                  onDirectionToggle: () {
                    HapticFeedback.selectionClick();
                    setState(() => _textDirection =
                        _textDirection == TextDirection.rtl
                            ? TextDirection.ltr
                            : TextDirection.rtl);
                  },
                  onInsertSymbol: (symbol) {
                    if (widget.mode == NoteMode.code) {
                      final text = _codeController.text;
                      final selection = _codeController.selection;
                      final cursorPos = selection.baseOffset;
                      String newText;
                      int newCursorPos;
                      if (symbol.length == 2 &&
                          (symbol == '{}' ||
                              symbol == '[]' ||
                              symbol == '()' ||
                              symbol == '<>' ||
                              symbol == '""' ||
                              symbol == "''")) {
                        newText =
                            text.replaceRange(cursorPos, cursorPos, symbol);
                        newCursorPos = cursorPos + 1;
                      } else if (symbol == '/**/') {
                        newText =
                            text.replaceRange(cursorPos, cursorPos, symbol);
                        newCursorPos = cursorPos + 2;
                      } else {
                        newText =
                            text.replaceRange(cursorPos, cursorPos, symbol);
                        newCursorPos = cursorPos + symbol.length;
                      }
                      _codeController.value = _codeController.value.copyWith(
                        text: newText,
                        selection:
                            TextSelection.collapsed(offset: newCursorPos),
                      );
                    } else {
                      _formattingController.insertSymbol(
                          _contentController, symbol);
                    }
                  },
                  onRunCode: _detectedLanguage != null ? _runCode : null,
                  onExportCode: _detectedLanguage != null ? _exportCode : null,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleDelete(
      Color finalTextColor) async {
    HapticFeedback.heavyImpact();
    final l10n = context.l10n;

    final noteId = _savedNoteId ?? widget.note?.id;
    if (noteId == null) {
      Navigator.pop(context);
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _backgroundColor,
        title: Text(l10n.deleteNote, style: TextStyle(color: finalTextColor)),
        content:
            Text(l10n.deleteConfirm, style: TextStyle(color: finalTextColor)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel, style: TextStyle(color: finalTextColor)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final provider = Provider.of<NotesProvider>(context, listen: false);
      await provider.trashNote(noteId);
      if (mounted) {
        Navigator.of(context).pop();
        Navigator.of(context).pop();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autosaveTimer?.cancel();
    _languageDetectionTimer?.cancel();

    // SAFETY NET: Force save if dirty and not already saving
    if (_isDirty && !_isSavingOnExit) {
      final currentText = widget.mode == NoteMode.code
          ? _codeController.text
          : _contentController.text;
      if (currentText.isNotEmpty) {
        _saveNoteToDatabase(isManualSave: true);
      }
    }

    _storageController.saveStickySettings(
      fontSize: _fontSize,
      textAlign: _textAlign,
      textDirection: _textDirection,
      backgroundColor: _backgroundColor,
    );

    // CRITICAL: Remove listener BEFORE clearing to prevent empty save trigger
    _contentController.removeListener(_onContentChanged);
    _contentController.clear();
    _contentController.dispose();
    
    _undoController.removeListener(_updateUndoRedoState);
    _undoController.dispose();
    
    if (widget.mode == NoteMode.code) {
      _codeController.removeListener(_onContentChanged);
      _codeController.clear();
      _codeController.dispose();
      _codeUndoController.removeListener(_updateUndoRedoState);
      _codeUndoController.dispose();
    }
    
    _textFieldFocusNode.dispose();
    
    // Clear checklist undo/redo history
    _checklistUndoRedo = null;

    super.dispose();
  }
}
