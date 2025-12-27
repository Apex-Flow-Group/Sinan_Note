// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:async';
import 'dart:io';
import 'package:flutter/widgets.dart';
import '../models/note.dart';
import 'database_service.dart';
import 'notification_service.dart';
import 'widget_service.dart';
import 'encryption_service.dart';
import '../utils/checklist_formatter.dart';

class NotesProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();

  // SINGLE SOURCE OF TRUTH: قائمة واحدة مركزية
  List<Note> _allNotes = [];
  List<Note> _lockedNotes = []; // SECURITY: Separate session for locked notes
  bool _isInitialDataLoaded = false; // ✅ تتبع جاهزية البيانات الأولية
  bool _isLoading = false; // CRITICAL: Loading lock to prevent redundant calls

  // VAULT SESSION: Temporary unlock session
  bool _isVaultUnlocked = false;
  DateTime? _vaultUnlockedAt;
  static const _sessionDuration = Duration(minutes: 5);

  // ✅ Constructor: DO NOT load data here
  NotesProvider();

  bool get isInitialDataLoaded => _isInitialDataLoaded;

  bool get isVaultUnlocked {
    if (!_isVaultUnlocked || _vaultUnlockedAt == null) return false;
    final elapsed = DateTime.now().difference(_vaultUnlockedAt!);
    if (elapsed > _sessionDuration) {
      _isVaultUnlocked = false;
      _vaultUnlockedAt = null;
      return false;
    }
    return true;
  }

  void unlockVault() {
    _isVaultUnlocked = true;
    _vaultUnlockedAt = DateTime.now();
  }

  void lockVault() {
    _isVaultUnlocked = false;
    _vaultUnlockedAt = null;
    clearLockedSession();
    notifyListeners();
  }

  // SMART GETTERS: الفلترة في الذاكرة (NO SORTING - stability for MasonryGrid)
  List<Note> get activeNotes {
    return _allNotes
        .where((n) => !n.isLocked && !n.isTrashed && !n.isArchived)
        .toList();
  }

  List<Note> get notes => activeNotes; // للتوافق مع الكود القديم

  List<Note> get archivedNotes => _allNotes
      .where((n) => n.isArchived && !n.isTrashed && !n.isLocked)
      .toList();

  List<Note> get trashedNotes =>
      _allNotes.where((n) => n.isTrashed && !n.isLocked).toList();

  List<Note> get reminderNotes => _allNotes
      .where((n) =>
          n.reminderDateTime != null &&
          !n.isLocked &&
          !n.isTrashed &&
          n.reminderDateTime!.isAfter(DateTime.now()))
      .toList();

  List<Note> get lockedNotes => _lockedNotes; // SECURITY: Isolated access

  // WRITE-TIME SORTING: Sort _allNotes when data changes (not on read)
  // OPTIMIZATION: Debounced to prevent multiple sorts in quick succession
  Timer? _sortDebounce;
  void _sortNotes({bool immediate = false}) {
    if (immediate) {
      _performSort();
      return;
    }
    
    // Debounce: Only sort once after multiple rapid changes
    _sortDebounce?.cancel();
    _sortDebounce = Timer(const Duration(milliseconds: 50), _performSort);
  }
  
  void _performSort() {
    _allNotes.sort((a, b) {
      // 1. Pinned notes first
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      // 2. Newest first (by updatedAt)
      return b.updatedAt.compareTo(a.updatedAt);
    });
  }

  // تحميل جميع الملاحظات مرة واحدة
  Future<void> refreshAllNotes() async {
    if (_isLoading) return;
    
    _isLoading = true;
    
    try {
      _allNotes = await _dbService.getAllNotes();
      _sortNotes(immediate: true);
      _isInitialDataLoaded = true;
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // للتوافق مع الكود القديم
  Future<void> loadNotes() async {
    if (_isLoading || _isInitialDataLoaded) return;
    await refreshAllNotes();
  }

  // البحث في الذاكرة بدلاً من قاعدة البيانات
  List<Note> searchNotes(String query) {
    final lowerQuery = query.toLowerCase();
    return _allNotes
        .where((n) =>
            !n.isLocked &&
            (n.title.toLowerCase().contains(lowerQuery) ||
                n.content.toLowerCase().contains(lowerQuery)))
        .toList();
  }

  // للتوافق مع الكود القديم
  Future<List<Note>> getNotes() async {
    await refreshAllNotes();
    return activeNotes;
  }

  // SECURITY: Secure Session - Fetch locked notes on-demand
  Future<void> fetchLockedNotes() async {
    _lockedNotes = await _dbService.getLockedNotes();
    notifyListeners();
  }

  // SECURITY: Bulk decrypt locked notes for vault display
  Future<List<Note>> fetchAndDecryptLockedNotes() async {
    final encryptedNotes = await _dbService.getLockedNotes();
    final decryptedNotes = <Note>[];

    for (final note in encryptedNotes) {
      try {
        // CRITICAL: Checklists are stored as plain JSON, skip decryption
        final decryptedTitle = note.isChecklist ? note.title : await EncryptionService.decrypt(note.title);
        final decryptedContent = note.isChecklist ? note.content : await EncryptionService.decrypt(note.content);

        decryptedNotes.add(Note(
          id: note.id,
          title: decryptedTitle,
          content: decryptedContent,
          createdAt: note.createdAt,
          updatedAt: note.updatedAt,
          colorIndex: note.colorIndex,
          isArchived: note.isArchived,
          isTrashed: note.isTrashed,
          reminderDateTime: note.reminderDateTime,
          isLocked: note.isLocked,
          noteType: note.noteType,
          recurrenceRule: note.recurrenceRule,
          isCompleted: note.isCompleted,
          isProfessional: note.isProfessional,
          isPinned: note.isPinned,
          isChecklist: note.isChecklist,
        ));
      } catch (e) {
        decryptedNotes.add(note);
      }
    }

    return decryptedNotes;
  }

  // للتوافق مع الكود القديم - كلها تستدعي refreshAllNotes
  Future<void> fetchNotes() async => await refreshAllNotes();
  Future<void> fetchTrashedNotes() async => await refreshAllNotes();
  Future<void> fetchArchivedNotes() async => await refreshAllNotes();
  Future<void> fetchTrashNotes() async => await refreshAllNotes();

  // SECURITY: Secure Session - Wipe decrypted data from RAM
  void clearLockedSession({bool notify = true}) {
    _lockedNotes = [];
    if (notify) {
      notifyListeners();
    }
  }

  // إضافة ملاحظة جديدة + Side Effects (OPTIMIZED: No DB reload)
  Future<int> addNote(Note note) async {
    // CRITICAL: Encrypt content if locked (EXCEPT Checklists - they stay as plain JSON)
    Note noteToInsert = note;
    if (note.isLocked && note.content.isNotEmpty && !note.isChecklist) {
      final encryptedTitle = note.title.isNotEmpty 
          ? await EncryptionService.encrypt(note.title) 
          : '';
      final encryptedContent = await EncryptionService.encrypt(note.content);
      
      noteToInsert = Note(
        id: note.id,
        title: encryptedTitle,
        content: encryptedContent,
        createdAt: note.createdAt,
        updatedAt: note.updatedAt,
        colorIndex: note.colorIndex,
        isArchived: note.isArchived,
        isTrashed: note.isTrashed,
        reminderDateTime: note.reminderDateTime,
        isLocked: note.isLocked,
        noteType: note.noteType,
        recurrenceRule: note.recurrenceRule,
        isCompleted: note.isCompleted,
        isProfessional: note.isProfessional,
        isPinned: note.isPinned,
        isChecklist: note.isChecklist,
      );
    }
    
    // 1. Add to memory immediately
    if (note.isLocked) {
      _lockedNotes.insert(0, note);
    } else {
      _allNotes.insert(0, note);
      _performSort(); // Sort immediately (pinned first)
      _allNotes = List.from(_allNotes); // New reference
    }
    
    notifyListeners(); // 👈 UI update (0ms)
    
    // 2. DB insert in background
    final id = await _dbService.insertNote(noteToInsert);
    
    // 3. Update ID only (no reload)
    if (note.isLocked) {
      _lockedNotes = _lockedNotes.map((n) => n == note ? n.copyWith(id: id) : n).toList();
    } else {
      _allNotes = _allNotes.map((n) => n == note ? n.copyWith(id: id) : n).toList();
    }
    
    // Side Effect: جدولة التذكير
    await _handleReminderSideEffect(note.copyWith(id: id));
    
    return id;
  }

  Future<int> insertNote(Note note) async {
    // Delegate to optimized addNote method
    return addNote(note);
  }

  Future<int> updateNote(Note note, {bool silent = false}) async {
    // CRITICAL: Encrypt content if locked (EXCEPT Checklists - they stay as plain JSON)
    Note noteToUpdate = note;
    if (note.isLocked && note.content.isNotEmpty && !note.isChecklist) {
      if (!EncryptionService.isEncrypted(note.content)) {
        final encryptedTitle = note.title.isNotEmpty 
            ? await EncryptionService.encrypt(note.title) 
            : '';
        final encryptedContent = await EncryptionService.encrypt(note.content);
        
        noteToUpdate = Note(
          id: note.id,
          title: encryptedTitle,
          content: encryptedContent,
          createdAt: note.createdAt,
          updatedAt: note.updatedAt,
          colorIndex: note.colorIndex,
          isArchived: note.isArchived,
          isTrashed: note.isTrashed,
          reminderDateTime: note.reminderDateTime,
          isLocked: note.isLocked,
          noteType: note.noteType,
          recurrenceRule: note.recurrenceRule,
          isCompleted: note.isCompleted,
          isProfessional: note.isProfessional,
          isPinned: note.isPinned,
          isChecklist: note.isChecklist,
        );
      }
    }
    
    final result = await _dbService.updateNote(noteToUpdate);

    if (note.isLocked) {
      final index = _lockedNotes.indexWhere((n) => n.id == note.id);
      if (index != -1) {
        _lockedNotes[index] = note;
      }
    } else {
      final index = _allNotes.indexWhere((n) => n.id == note.id);
      if (index != -1) {
        _allNotes[index] = note;
        _performSort(); // CRITICAL: Sort immediately for pin changes
        _allNotes = List.from(_allNotes); // CRITICAL: New reference for Selector
      } else {
        _allNotes.add(note);
        _performSort(); // CRITICAL: Sort immediately
        _allNotes = List.from(_allNotes); // CRITICAL: New reference for Selector
      }
    }

    await _handleReminderSideEffect(note);

    // 🔄 تحديث الويدجت إذا كانت الملاحظة مثبتة (INSTANT SYNC)
    await WidgetService.checkAndUpdateIfPinned(note);

    // Only notify if not silent (auto-save from editor should be silent)
    if (!silent) {
      notifyListeners();
    }

    return result;

  }

  Future<int> deleteNote(int id) async {
    // Side Effect: إلغاء التذكير قبل الحذف
    await _cancelReminderSideEffect(id);

    final result = await _dbService.deleteNote(id);
    _allNotes.removeWhere((n) => n.id == id);
    _lockedNotes.removeWhere((n) => n.id == id);

    // Side Effect: Reset widget if deleted note was pinned
    await WidgetService.checkAndResetIfPinned(id);

    notifyListeners();

    // Side Effect: تحديث الويدجت
    await _updateWidgetSideEffect();

    return result;
  }

  Future<int> archiveNote(int id) async {
    await _cancelReminderSideEffect(id);

    final result = await _dbService.archiveNote(id);
    final index = _allNotes.indexWhere((n) => n.id == id);
    if (index != -1) {
      final note = _allNotes[index];
      _allNotes[index] = Note(
        id: note.id,
        title: note.title,
        content: note.content,
        createdAt: note.createdAt,
        updatedAt: DateTime.now(),
        colorIndex: note.colorIndex,
        isArchived: true,
        isTrashed: note.isTrashed,
        reminderDateTime: note.reminderDateTime,
        isLocked: note.isLocked,
        noteType: note.noteType,
        recurrenceRule: note.recurrenceRule,
        isCompleted: note.isCompleted,
        isProfessional: note.isProfessional,
        isPinned: note.isPinned,
        isChecklist: note.isChecklist,
      );
      _allNotes = List.from(_allNotes); // CRITICAL: New reference for Selector
    }

    notifyListeners();
    await _updateWidgetSideEffect();
    return result;
  }

  Future<int> unarchiveNote(int id) async {
    final result = await _dbService.unarchiveNote(id);
    final index = _allNotes.indexWhere((n) => n.id == id);
    if (index != -1) {
      final note = _allNotes[index];
      _allNotes[index] = Note(
        id: note.id,
        title: note.title,
        content: note.content,
        createdAt: note.createdAt,
        updatedAt: DateTime.now(),
        colorIndex: note.colorIndex,
        isArchived: false,
        isTrashed: note.isTrashed,
        reminderDateTime: note.reminderDateTime,
        isLocked: note.isLocked,
        noteType: note.noteType,
        recurrenceRule: note.recurrenceRule,
        isCompleted: note.isCompleted,
        isProfessional: note.isProfessional,
        isPinned: note.isPinned,
        isChecklist: note.isChecklist,
      );
      _allNotes = List.from(_allNotes); // CRITICAL: New reference for Selector
    }
    notifyListeners();
    return result;
  }

  Future<int> trashNote(int id) async {
    final note = await _dbService.getNoteById(id);
    if (note == null) return 0;

    await _cancelReminderSideEffect(id);

    final result = note.isLocked
        ? await _dbService.deleteNote(id)
        : await _dbService.trashNote(id);

    if (note.isLocked) {
      _lockedNotes.removeWhere((n) => n.id == id);
    } else {
      final index = _allNotes.indexWhere((n) => n.id == id);
      if (index != -1) {
        final n = _allNotes[index];
        _allNotes[index] = Note(
          id: n.id,
          title: n.title,
          content: n.content,
          createdAt: n.createdAt,
          updatedAt: DateTime.now(),
          colorIndex: n.colorIndex,
          isArchived: n.isArchived,
          isTrashed: true,
          reminderDateTime: n.reminderDateTime,
          isLocked: n.isLocked,
          noteType: n.noteType,
          recurrenceRule: n.recurrenceRule,
          isCompleted: n.isCompleted,
          isProfessional: n.isProfessional,
          isPinned: n.isPinned,
          isChecklist: n.isChecklist,
        );
        _allNotes = List.from(_allNotes); // CRITICAL: New reference for Selector
      }
    }

    notifyListeners();
    await _updateWidgetSideEffect();
    return result;
  }

  Future<int> restoreNote(int id) async {
    final index = _allNotes.indexWhere((n) => n.id == id);
    if (index != -1) {
      final note = _allNotes[index];
      _allNotes[index] = Note(
        id: note.id,
        title: note.title,
        content: note.content,
        createdAt: note.createdAt,
        updatedAt: DateTime.now(),
        colorIndex: note.colorIndex,
        isArchived: false,
        isTrashed: false,
        reminderDateTime: note.reminderDateTime,
        isLocked: note.isLocked,
        noteType: note.noteType,
        recurrenceRule: note.recurrenceRule,
        isCompleted: note.isCompleted,
        isProfessional: note.isProfessional,
        isPinned: note.isPinned,
        isChecklist: note.isChecklist,
      );
      _performSort(); // CRITICAL: Sort immediately
      _allNotes = List.from(_allNotes); // CRITICAL: New reference
      notifyListeners();
      
      // Async DB update in background
      _dbService.restoreNote(id).then((_) {
        _handleReminderSideEffect(_allNotes[index]);
        _updateWidgetSideEffect();
      });
    }
    return 1;
  }

  // BATCH OPERATIONS - Optimistic UI (FUNCTIONAL APPROACH)
  Future<void> trashNotes(List<int> ids) async {
    debugPrint('🗑️ trashNotes called with ${ids.length} IDs: $ids');
    
    // 1. Functional immutable update (Golden Solution)
    final before = _allNotes.length;
    _allNotes = _allNotes.map((n) => 
        ids.contains(n.id) 
            ? n.copyWith(isTrashed: true, isPinned: false, updatedAt: DateTime.now())
            : n
    ).toList();
    
    final trashedCount = _allNotes.where((n) => n.isTrashed).length;
    debugPrint('✅ Memory updated: $before notes -> $trashedCount trashed');
    
    notifyListeners(); // 👈 UI update (0ms)
    
    // 2. Silent background DB sync (NO await, NO reload)
    Future.microtask(() async {
      for (var id in ids) {
        await _dbService.trashNote(id);
        _cancelReminderSideEffect(id);
      }
      _updateWidgetSideEffect();
    });
  }

  Future<void> restoreNotes(List<int> ids) async {
    // 1. Functional immutable update
    _allNotes = _allNotes.map((n) => 
        ids.contains(n.id) 
            ? n.copyWith(isArchived: false, isTrashed: false, updatedAt: DateTime.now())
            : n
    ).toList();
    
    _performSort(); // Re-sort after restore
    notifyListeners();
    
    // 2. Silent background DB sync
    Future.microtask(() async {
      for (var id in ids) {
        await _dbService.restoreNote(id);
      }
      _updateWidgetSideEffect();
    });
  }

  Future<void> archiveNotes(List<int> ids) async {
    // 1. Functional immutable update
    _allNotes = _allNotes.map((n) => 
        ids.contains(n.id) 
            ? n.copyWith(isArchived: true, isPinned: false, updatedAt: DateTime.now())
            : n
    ).toList();
    
    notifyListeners();
    
    // 2. Silent background DB sync
    Future.microtask(() async {
      for (var id in ids) {
        await _dbService.archiveNote(id);
        _cancelReminderSideEffect(id);
      }
      _updateWidgetSideEffect();
    });
  }

  Future<void> unarchiveNotes(List<int> ids) async {
    // 1. Functional immutable update
    _allNotes = _allNotes.map((n) => 
        ids.contains(n.id) 
            ? n.copyWith(isArchived: false, updatedAt: DateTime.now())
            : n
    ).toList();
    
    notifyListeners();
    
    // 2. Silent background DB sync
    Future.microtask(() async {
      for (var id in ids) {
        await _dbService.unarchiveNote(id);
      }
    });
  }

  // Add or update note (unified method for saving)
  Future<int> addOrUpdateNote(Note note, {bool silent = false}) async {
    if (note.id != null) {
      await updateNote(note, silent: silent);
      return note.id!;
    } else {
      return await addNote(note);
    }
  }

  // SECURITY: Toggle lock status (import to vault or unlock)
  Future<void> toggleLockStatus(int id, bool lockStatus) async {
    final note = await _dbService.getNoteById(id);
    if (note == null) return;

    String finalTitle = note.title;
    String finalContent = note.content;

    if (lockStatus) {
      // Locking: Encrypt the content (EXCEPT Checklists)
      if (!note.isChecklist) {
        if (note.title.isNotEmpty) {
          finalTitle = await EncryptionService.encrypt(note.title);
        }
        if (note.content.isNotEmpty) {
          finalContent = await EncryptionService.encrypt(note.content);
        }
      }
    } else {
      // Unlocking: Decrypt the content (EXCEPT Checklists)
      if (!note.isChecklist) {
        finalTitle = await EncryptionService.decrypt(note.title);
        finalContent = await EncryptionService.decrypt(note.content);
      }
    }

    final updatedNote = Note(
      id: note.id,
      title: finalTitle,
      content: finalContent,
      createdAt: note.createdAt,
      updatedAt: DateTime.now(),
      colorIndex: note.colorIndex,
      isArchived: note.isArchived,
      isTrashed: note.isTrashed,
      isLocked: lockStatus,
      reminderDateTime: note.reminderDateTime,
      noteType: note.noteType,
      recurrenceRule: note.recurrenceRule,
      isCompleted: note.isCompleted,
      isProfessional: note.isProfessional,
      isPinned: note.isPinned,
      isChecklist: note.isChecklist,
    );

    await _dbService.updateNote(updatedNote);

    // Update in-memory lists
    if (lockStatus) {
      _allNotes.removeWhere((n) => n.id == id);
      _lockedNotes.add(updatedNote); // إضافة في النهاية
    } else {
      _lockedNotes.removeWhere((n) => n.id == id);
      _allNotes.add(updatedNote); // إضافة في النهاية
      _sortNotes(); // Sort after unlocking
    }

    notifyListeners();
  }

  // ==================== SIDE EFFECTS ====================

  /// معالجة التذكيرات (جدولة أو إلغاء)
  Future<bool> _handleReminderSideEffect(Note note) async {
    if (!Platform.isAndroid && !Platform.isIOS) return true;

    try {
      final notificationService = NotificationService();

      // إلغاء التذكير القديم أولاً
      await notificationService.cancelNotification(note.id!);

      // جدولة تذكير جديد إذا كان موجوداً ومستقبلياً
      if (note.reminderDateTime != null &&
          note.reminderDateTime!.isAfter(DateTime.now()) &&
          !note.isTrashed &&
          !note.isArchived) {
        // فحص إذن التنبيهات الدقيقة (Exact Alarms)
        final hasExactAlarmPermission =
            await notificationService.checkExactAlarmPermission();

        if (!hasExactAlarmPermission) {
          debugPrint('⚠️ Exact Alarm permission denied');
          return false; // فشل الجدولة
        }

        String notificationBody;
        if (note.isChecklist) {
          notificationBody = ChecklistFormatter.formatForSharing(note.title, note.content);
          if (notificationBody.length > 100) {
            notificationBody = '${notificationBody.substring(0, 100)}...';
          }
        } else {
          notificationBody = note.content.length > 100
              ? '${note.content.substring(0, 100)}...'
              : note.content;
        }
        
        await notificationService.scheduleNotification(
          id: note.id!,
          title: note.title.isEmpty ? 'تذكير' : note.title,
          body: notificationBody,
          scheduledTime: note.reminderDateTime!,
          recurrenceRule: note.recurrenceRule,
          payload: note.id.toString(),
        );
      }
      return true;
    } catch (e) {
      debugPrint('⚠️ Reminder side effect error: $e');
      return false;
    }
  }

  /// إلغاء التذكير
  Future<void> _cancelReminderSideEffect(int noteId) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;

    try {
      await NotificationService().cancelNotification(noteId);
    } catch (e) {
      debugPrint('⚠️ Cancel reminder error: $e');
    }
  }

  /// تحديث الويدجت (فقط عند الحاجة)
  Future<void> _updateWidgetSideEffect() async {
    if (!Platform.isAndroid) return;

    try {
      // 🛑 SKIP widget update during batch operations to prevent DB reload
      // Widget will update on next app launch or manual pin
      debugPrint('⏭️ Skipping widget update (batch operation)');
    } catch (e) {
      debugPrint('⚠️ Widget update error: $e');
    }
  }
  
  @override
  void dispose() {
    _sortDebounce?.cancel();
    super.dispose();
  }
}
