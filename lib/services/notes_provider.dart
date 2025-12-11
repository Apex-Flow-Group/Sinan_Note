// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:io';
import 'package:flutter/widgets.dart';
import '../models/note.dart';
import 'database_service.dart';
import 'notification_service.dart';
import 'widget_service.dart';
import 'encryption_service.dart';

class NotesProvider extends ChangeNotifier with WidgetsBindingObserver {
  final DatabaseService _dbService = DatabaseService();

  // SINGLE SOURCE OF TRUTH: قائمة واحدة مركزية
  List<Note> _allNotes = [];
  List<Note> _lockedNotes = []; // SECURITY: Separate session for locked notes
  bool _isInitialDataLoaded = false; // ✅ تتبع جاهزية البيانات الأولية

  // VAULT SESSION: Temporary unlock session
  bool _isVaultUnlocked = false;
  DateTime? _vaultUnlockedAt;
  static const _sessionDuration = Duration(minutes: 5);

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

  // 🔒 SECURITY: Monitor app lifecycle for instant vault lock
  void startLifecycleMonitoring() {
    WidgetsBinding.instance.addObserver(this);
  }

  void stopLifecycleMonitoring() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 🔒 Lock vault immediately when app goes to background or becomes inactive
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      if (_isVaultUnlocked) {
        debugPrint('🔒 SECURITY: App backgrounded - Locking vault immediately');
        lockVault();
      }
    }
  }

  @override
  void dispose() {
    stopLifecycleMonitoring();
    super.dispose();
  }

  // SMART GETTERS: الفلترة في الذاكرة
  List<Note> get activeNotes => _allNotes
      .where((n) => !n.isLocked && !n.isTrashed && !n.isArchived)
      .toList();

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

  // تحميل جميع الملاحظات مرة واحدة
  Future<void> refreshAllNotes() async {
    try {
      _allNotes = await _dbService.getAllNotes();
      _isInitialDataLoaded = true; // ✅ تعيين العلم بعد اكتمال التحميل
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Failed to refresh notes: $e');
      rethrow;
    }
  }

  // للتوافق مع الكود القديم
  Future<void> loadNotes() async {
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

  // إضافة ملاحظة جديدة + Side Effects
  Future<int> addNote(Note note) async {
    // CRITICAL: Encrypt content if locked (EXCEPT Checklists - they stay as plain JSON)
    Note noteToInsert = note;
    if (note.isLocked && note.content.isNotEmpty && !note.isChecklist) {
      debugPrint('🔐 VAULT: Encrypting locked note (isChecklist=${note.isChecklist})');
      debugPrint('🔐 VAULT: Content before encryption: ${note.content.substring(0, note.content.length > 100 ? 100 : note.content.length)}...');
      
      final encryptedTitle = note.title.isNotEmpty 
          ? await EncryptionService.encrypt(note.title) 
          : '';
      final encryptedContent = await EncryptionService.encrypt(note.content);
      
      debugPrint('🔐 VAULT: Content encrypted successfully');
      
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
    
    final id = await _dbService.insertNote(noteToInsert);
    final newNote = await _dbService.getNoteById(id);
    if (newNote != null) {
      if (newNote.isLocked) {
        _lockedNotes.insert(0, newNote); // إدراج في المقدمة
      } else {
        _allNotes.insert(0, newNote); // إدراج في المقدمة
      }

      // Side Effect: جدولة التذكير
      await _handleReminderSideEffect(newNote);
    }

    notifyListeners();

    return id;
  }

  Future<int> insertNote(Note note) async {
    // Delegate to optimized addNote method
    return addNote(note);
  }

  Future<int> updateNote(Note note) async {
    // CRITICAL: Encrypt content if locked (EXCEPT Checklists - they stay as plain JSON)
    Note noteToUpdate = note;
    if (note.isLocked && note.content.isNotEmpty && !note.isChecklist) {
      // Check if already encrypted
      if (!EncryptionService.isEncrypted(note.content)) {
        debugPrint('🔄 VAULT UPDATE: Encrypting content (isChecklist=${note.isChecklist})');
        debugPrint('🔄 VAULT UPDATE: Content before: ${note.content.substring(0, note.content.length > 100 ? 100 : note.content.length)}...');
        
        final encryptedTitle = note.title.isNotEmpty 
            ? await EncryptionService.encrypt(note.title) 
            : '';
        final encryptedContent = await EncryptionService.encrypt(note.content);
        
        debugPrint('🔄 VAULT UPDATE: Content encrypted');
        
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
        _lockedNotes.removeAt(index);
        _lockedNotes.insert(0, note); // نقل للمقدمة
      }
    } else {
      final index = _allNotes.indexWhere((n) => n.id == note.id);
      if (index != -1) {
        _allNotes.removeAt(index);
        _allNotes.insert(0, note); // نقل للمقدمة
      } else {
        _allNotes.insert(0, note); // إضافة في المقدمة
      }
    }

    await _handleReminderSideEffect(note);

    notifyListeners();

    // 🔄 تحديث الويدجت إذا كانت الملاحظة مثبتة
    await WidgetService.checkAndUpdateIfPinned(note);

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
    // Side Effect: إلغاء التذكير عند الأرشفة
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
    }

    notifyListeners();

    // Side Effect: تحديث الويدجت
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
    }
    notifyListeners();
    return result;
  }

  Future<int> trashNote(int id) async {
    final note = await _dbService.getNoteById(id);
    if (note == null) return 0;

    // Side Effect: إلغاء التذكير عند الحذف
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
      }
    }

    notifyListeners();

    // Side Effect: تحديث الويدجت
    await _updateWidgetSideEffect();

    return result;
  }

  Future<int> restoreNote(int id) async {
    final result = await _dbService.restoreNote(id);
    final index = _allNotes.indexWhere((n) => n.id == id);
    if (index != -1) {
      final note = _allNotes[index];
      final restoredNote = Note(
        id: note.id,
        title: note.title,
        content: note.content,
        createdAt: note.createdAt,
        updatedAt: DateTime.now(),
        colorIndex: note.colorIndex,
        isArchived: note.isArchived,
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
      _allNotes.removeAt(index);
      _allNotes.insert(0, restoredNote); // نقل للمقدمة

      // Side Effect: إعادة جدولة التذكير عند الاستعادة
      await _handleReminderSideEffect(restoredNote);
    }

    notifyListeners();

    // Side Effect: تحديث الويدجت
    await _updateWidgetSideEffect();

    return result;
  }

  // Add or update note (unified method for saving)
  Future<int> addOrUpdateNote(Note note) async {
    if (note.id != null) {
      await updateNote(note);
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
      _lockedNotes.insert(0, updatedNote); // إدراج في المقدمة
    } else {
      _lockedNotes.removeWhere((n) => n.id == id);
      _allNotes.insert(0, updatedNote); // إدراج في المقدمة
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

        await notificationService.scheduleNotification(
          id: note.id!,
          title: note.title.isEmpty ? 'تذكير' : note.title,
          body: note.content.length > 100
              ? '${note.content.substring(0, 100)}...'
              : note.content,
          scheduledTime: note.reminderDateTime!,
          recurrenceRule: note.recurrenceRule,
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
      await WidgetService().updateWidgetData();
    } catch (e) {
      debugPrint('⚠️ Widget update error: $e');
    }
  }
}
