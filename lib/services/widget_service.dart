// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:convert';
import 'dart:io';

import 'package:apex_note/controllers/settings/settings_provider.dart';
import 'package:apex_note/core/utils/logger.dart';
import 'package:apex_note/models/note.dart';
import 'package:apex_note/services/storage/isar_database_service.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WidgetService {
  static final WidgetService _instance = WidgetService._internal();
  factory WidgetService() => _instance;
  WidgetService._internal();

  final IsarDatabaseService _dbService = IsarDatabaseService();

  Future<void> updateWidgetData() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;

    try {
      // 1. فحص النوت المثبتة أولاً
      final prefs = await SharedPreferences.getInstance();
      final savedNoteId = prefs.getInt('flutter.note_id') ?? 0;
      
      if (savedNoteId > 0) {
        final specificNote = await _dbService.getNoteById(savedNoteId);
        if (specificNote != null && 
            !specificNote.isLocked && 
            !specificNote.isTrashed && 
            !specificNote.isArchived &&
            !specificNote.isChecklist &&
            specificNote.noteType != 'checklist') {
          await updateNoteWidget(specificNote);
          AppLogger.success('Note widget updated with pinned note ID: $savedNoteId', 'Widget');
          return; // ✅ استخدام النوت المثبتة
        }
      }
      
      // 2. فقط إذا لم توجد نوت مثبتة، استخدم المزامنة العامة
      final notes = await _dbService.getAllNotes();
      
      // STRICT FILTER: Only NON-checklist notes (pinned first, then recent)
      final validNotes = notes.where((note) =>
          !note.isLocked &&
          !note.isTrashed &&
          !note.isArchived &&
          !note.isChecklist &&
          note.noteType != 'checklist'
      ).toList();

      // Sort: Pinned first, then by modified date
      validNotes.sort((a, b) {
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        return b.updatedAt.compareTo(a.updatedAt);
      });

      if (validNotes.isNotEmpty) {
        final note = validNotes.first;
        final title = note.title.isEmpty ? (await _getUntitledText()) : note.title;
        final content = _formatNoteContent(note.content, 200);

        await HomeWidget.saveWidgetData<String>('title', title);
        await HomeWidget.saveWidgetData<String>('content', content);
        await HomeWidget.saveWidgetData<int>('note_id', note.id ?? 0);
      } else {
        await HomeWidget.saveWidgetData<String>('title', await _getSelectNoteText());
        await HomeWidget.saveWidgetData<String>('content', await _getTapToSelectText());
        await HomeWidget.saveWidgetData<int>('note_id', 0);
      }

      await HomeWidget.updateWidget(androidName: 'NoteWidgetProvider');
      
      AppLogger.success('Note widget updated with general sync', 'Widget');
    } catch (e) {
      AppLogger.error('Note widget update failed', 'Widget', e);
    }
  }

  Future<void> updateChecklistWidgetData() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;

    try {
      // 1. فحص القائمة المثبتة أولاً
      final prefs = await SharedPreferences.getInstance();
      final savedChecklistId = prefs.getInt('flutter.checklist_note_id') ?? 0;
      
      if (savedChecklistId > 0) {
        final specificChecklist = await _dbService.getNoteById(savedChecklistId);
        if (specificChecklist != null && 
            !specificChecklist.isLocked && 
            !specificChecklist.isTrashed && 
            !specificChecklist.isArchived &&
            (specificChecklist.isChecklist || specificChecklist.noteType == 'checklist')) {
          final title = specificChecklist.title.isEmpty ? 'Checklist' : specificChecklist.title;
          final stats = _parseChecklistStats(specificChecklist.content);
          
          await updateChecklistWidget(
            specificChecklist.id ?? 0,
            title,
            specificChecklist.content,
            specificChecklist.colorIndex,
            totalItems: stats['total'] ?? 0,
            completedItems: stats['completed'] ?? 0,
          );
          AppLogger.success('Checklist widget updated with pinned list ID: $savedChecklistId', 'Widget');
          return; // ✅ استخدام القائمة المثبتة
        }
      }
      
      // 2. فقط إذا لم توجد قائمة مثبتة، استخدم المزامنة العامة
      final notes = await _dbService.getAllNotes();
      
      // STRICT FILTER: ONLY checklists (pinned first, then recent)
      final validChecklists = notes.where((note) =>
          !note.isLocked &&
          !note.isTrashed &&
          !note.isArchived &&
          (note.isChecklist || note.noteType == 'checklist')
      ).toList();

      // Sort: Pinned first, then by modified date
      validChecklists.sort((a, b) {
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        return b.updatedAt.compareTo(a.updatedAt);
      });

      if (validChecklists.isNotEmpty) {
        final checklist = validChecklists.first;
        final title = checklist.title.isEmpty ? 'Checklist' : checklist.title;
        final stats = _parseChecklistStats(checklist.content);

        await updateChecklistWidget(
          checklist.id ?? 0,
          title,
          checklist.content,
          checklist.colorIndex,
          totalItems: stats['total'] ?? 0,
          completedItems: stats['completed'] ?? 0,
        );
      } else {
        await _resetChecklistWidget();
      }
      
      AppLogger.success('Checklist widget updated with general sync', 'Widget');
    } catch (e) {
      AppLogger.error('Checklist widget update failed', 'Widget', e);
    }
  }

  /// Format note content (simple truncation)
  String _formatNoteContent(String content, int maxLength) {
    if (content.trim().isEmpty) return 'Empty note';
    
    // إذا كان Delta JSON → استخرج النص العادي
    String plainText = content;
    if (content.trimLeft().startsWith('[')) {
      try {
        final List ops = jsonDecode(content) as List;
        final buffer = StringBuffer();
        for (final op in ops) {
          if (op is Map && op['insert'] is String) {
            buffer.write(op['insert']);
          }
        }
        plainText = buffer.toString().trimRight();
      } catch (_) {}
    }
    
    if (plainText.trim().isEmpty) return 'Empty note';
    return plainText.length > maxLength
        ? '${plainText.substring(0, maxLength)}...'
        : plainText;
  }

  /// SNAPSHOT STRATEGY: Generate simple text snapshot for widget persistence
  String _generateChecklistSnapshot(String content) {
    if (content.trim().isEmpty) return 'Empty checklist';
    
    try {
      final decoded = jsonDecode(content);
      List items = [];

      if (decoded is Map && decoded.containsKey('items')) {
        items = decoded['items'];
      } else if (decoded is List) {
        items = decoded;
      }

      if (items.isEmpty) return 'Empty checklist';

      // Generate persistent text snapshot (max 5 items for widget)
      return items.take(5).map((item) {
        final text = item['text'] ?? '';
        final isDone = item['isDone'] ?? false;
        return isDone ? '☑ $text' : '☐ $text';
      }).join('\n');
    } catch (e) {
      return _formatNoteContent(content, 150);
    }
  }


  /// Parse checklist statistics
  Map<String, int> _parseChecklistStats(String content) {
    try {
      final decoded = jsonDecode(content);
      List items = [];

      if (decoded is Map && decoded.containsKey('items')) {
        items = decoded['items'];
      } else if (decoded is List) {
        items = decoded;
      }

      final total = items.length;
      final completed = items.where((item) => item['isDone'] == true).length;

      return {'total': total, 'completed': completed};
    } catch (e) {
      return {'total': 0, 'completed': 0};
    }
  }

  Future<void> updateChecklistWidget(
      int noteId, 
      String title, 
      String content, 
      int colorIndex,
      {int totalItems = 0, int completedItems = 0}) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;

    try {
      if (noteId == 0) {
        await _resetChecklistWidget();
      } else {
        // 🎯 SNAPSHOT STRATEGY: Generate persistent text snapshot
        final textSnapshot = _generateChecklistSnapshot(content);

        // 🔥 CRITICAL: Save simple text snapshot for persistence
        await HomeWidget.saveWidgetData<int>('checklist_note_id', noteId);
        await HomeWidget.saveWidgetData<String>('checklist_title', title);
        await HomeWidget.saveWidgetData<String>('checklist_preview', textSnapshot); // NEW: Simple text
        await HomeWidget.saveWidgetData<int>('checklist_total', totalItems);
        await HomeWidget.saveWidgetData<int>('checklist_completed', completedItems);
        
        // حفظ في SharedPreferences أيضاً للتأكد (مثل NoteWidget)
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('flutter.checklist_note_id', noteId);
        await prefs.setString('flutter.checklist_title', title);
        await prefs.setString('flutter.checklist_preview', textSnapshot);
        await prefs.setInt('flutter.checklist_total', totalItems);
        await prefs.setInt('flutter.checklist_completed', completedItems);
      }

      await HomeWidget.updateWidget(androidName: 'ChecklistWidgetProvider');
    } catch (e) {
      AppLogger.error('Checklist widget update failed', 'Widget', e);
    }
  }

  Future<void> _resetChecklistWidget() async {
    await HomeWidget.saveWidgetData<int>('checklist_note_id', 0);
    await HomeWidget.saveWidgetData<String>('checklist_title', await _getSelectListText());
    await HomeWidget.saveWidgetData<String>('checklist_preview', await _getTapToSelectText()); // Use preview key
    await HomeWidget.saveWidgetData<int>('checklist_total', 0);
    await HomeWidget.saveWidgetData<int>('checklist_completed', 0);
  }

  Future<void> updateNoteWidget(Note note) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;

    try {
      final title = note.title.isEmpty ? (await _getUntitledText()) : note.title;
      final content = _formatNoteContent(note.content, 200);

      await HomeWidget.saveWidgetData<String>('title', title);
      await HomeWidget.saveWidgetData<String>('content', content);
      await HomeWidget.saveWidgetData<int>('note_id', note.id ?? 0);
      
      // حفظ في SharedPreferences أيضاً للتأكد
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('flutter.note_id', note.id ?? 0);
      await prefs.setString('flutter.title', title);
      await prefs.setString('flutter.content', content);

      await HomeWidget.updateWidget(androidName: 'NoteWidgetProvider');
    } catch (e) {
      AppLogger.error('Note widget update failed', 'Widget', e);
    }
  }

  Future<void> initialize() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;

    try {
      await HomeWidget.setAppGroupId('group.com.apexflow.app.sinan_note');
      await HomeWidget.registerInteractivityCallback(_widgetBackgroundCallback);
    } catch (e) {
      // Widget initialization failed
    }
  }

  static Future<void> checkAndResetIfPinned(int deletedNoteId) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final storedNoteId = prefs.getInt('flutter.note_id') ?? 0;
      final storedChecklistId = prefs.getInt('flutter.checklist_note_id') ?? 0;

      if (deletedNoteId == storedNoteId) {
        await HomeWidget.saveWidgetData<String>('title', 'Note Deleted');
        await HomeWidget.saveWidgetData<String>('content', 'Tap to select +');
        await HomeWidget.saveWidgetData<int>('note_id', 0);
        await HomeWidget.updateWidget(androidName: 'NoteWidgetProvider');
      }

      if (deletedNoteId == storedChecklistId) {
        await HomeWidget.saveWidgetData<String>(
            'checklist_title', 'List Deleted');
        await HomeWidget.saveWidgetData<String>(
            'checklist_content', 'Tap to select +');
        await HomeWidget.saveWidgetData<int>('checklist_note_id', 0);
        await HomeWidget.updateWidget(androidName: 'ChecklistWidgetProvider');
      }
    } catch (e) {
      // Widget reset failed
    }
  }

  /// Auto-update widget when pinned note is modified
  static Future<void> checkAndUpdateIfPinned(Note note) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;

    // 🛑 CRITICAL FIX: Skip if note ID is invalid
    if (note.id == null || note.id == 0) {
      AppLogger.warning('Skipping widget update: Invalid note ID (${note.id})', 'Widget');
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final pinnedNoteId = prefs.getInt('flutter.note_id') ?? 0;
      final pinnedChecklistId = prefs.getInt('flutter.checklist_note_id') ?? 0;

      final service = WidgetService();
      final isChecklistNote = note.isChecklist || note.noteType == 'checklist';

      if (note.id == pinnedNoteId && !isChecklistNote) {
        await service.updateNoteWidget(note);
      } else if (note.id == pinnedChecklistId && isChecklistNote) {
        final title = note.title.isEmpty ? 'Checklist' : note.title;
        final stats = service._parseChecklistStats(note.content);
        await service.updateChecklistWidget(
          note.id!,
          title,
          note.content,
          note.colorIndex,
          totalItems: stats['total'] ?? 0,
          completedItems: stats['completed'] ?? 0,
        );
      }
    } catch (e) {
      AppLogger.error('Widget update on note change failed', 'Widget', e);
    }
  }

  // Helper methods for localized text
  static Future<String> _getUntitledText() async {
    final settings = SettingsProvider();
    await settings.ensureInitialized();
    return settings.locale?.languageCode == 'ar' ? 'بدون عنوان' : 'Untitled';
  }

  static Future<String> _getSelectNoteText() async {
    final settings = SettingsProvider();
    await settings.ensureInitialized();
    return settings.locale?.languageCode == 'ar'
        ? 'اختر ملاحظة'
        : 'Select Note';
  }

  static Future<String> _getTapToSelectText() async {
    final settings = SettingsProvider();
    await settings.ensureInitialized();
    return settings.locale?.languageCode == 'ar'
        ? 'اضغط هنا للتحديد +'
        : 'Tap to select +';
  }

  static Future<String> _getSelectListText() async {
    final settings = SettingsProvider();
    await settings.ensureInitialized();
    return settings.locale?.languageCode == 'ar' ? 'اختر قائمة' : 'Select List';
  }
}

/// Background callback for widget actions
@pragma('vm:entry-point')
void _widgetBackgroundCallback(Uri? uri) async {
  if (uri?.host == 'deleteNote') {
    final noteId = int.tryParse(uri?.queryParameters['id'] ?? '');
    if (noteId != null) {
      final dbService = IsarDatabaseService();
      await dbService.deleteNote(noteId);
      await WidgetService().updateWidgetData();
    }
  }
}
