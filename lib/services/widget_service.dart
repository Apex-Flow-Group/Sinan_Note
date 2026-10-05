// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:convert';
import 'dart:io';

import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sinan_note/core/l10n/app_strings.dart';
import 'package:sinan_note/core/utils/logger.dart';
import 'package:sinan_note/domain/models/note.dart';

class WidgetService {
  static final WidgetService _instance = WidgetService._internal();
  factory WidgetService() => _instance;
  WidgetService._internal();

  /// Format note content (simple truncation)
  String _formatNoteContent(String content, int maxLength) {
    if (content.trim().isEmpty) return AppStrings.current.widgetEmptyNote;

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

    if (plainText.trim().isEmpty) return AppStrings.current.widgetEmptyNote;
    return plainText.length > maxLength
        ? '${plainText.substring(0, maxLength)}...'
        : plainText;
  }

  /// SNAPSHOT STRATEGY: Generate simple text snapshot for widget persistence
  String _generateChecklistSnapshot(String content) {
    if (content.trim().isEmpty) return AppStrings.current.widgetEmptyChecklist;

    try {
      final decoded = jsonDecode(content);
      List items = [];

      if (decoded is Map && decoded.containsKey('items')) {
        items = decoded['items'];
      } else if (decoded is List) {
        items = decoded;
      }

      if (items.isEmpty) return AppStrings.current.widgetEmptyChecklist;

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
      int noteId, String title, String content, int colorIndex,
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
        await HomeWidget.saveWidgetData<String>(
            'checklist_preview', textSnapshot); // NEW: Simple text
        await HomeWidget.saveWidgetData<int>('checklist_total', totalItems);
        await HomeWidget.saveWidgetData<int>(
            'checklist_completed', completedItems);

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
    await HomeWidget.saveWidgetData<String>(
        'checklist_title', AppStrings.current.selectList);
    await HomeWidget.saveWidgetData<String>(
        'checklist_preview', AppStrings.current.tapToSelect); // Use preview key
    await HomeWidget.saveWidgetData<int>('checklist_total', 0);
    await HomeWidget.saveWidgetData<int>('checklist_completed', 0);
  }

  /// يثبّت [note] في الويدجت المناسب: قائمة مهام أو ملاحظة.
  Future<void> pin(Note note) async {
    final id = note.id;
    if (id == null) return;
    if (note.isChecklist || note.noteType == 'checklist') {
      final stats = _parseChecklistStats(note.content);
      await updateChecklistWidget(
        id,
        note.title.isEmpty ? AppStrings.current.checklist : note.title,
        note.content,
        note.colorIndex,
        totalItems: stats['total'] ?? 0,
        completedItems: stats['completed'] ?? 0,
      );
    } else {
      await updateNoteWidget(note);
    }
  }

  Future<void> updateNoteWidget(Note note) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;

    try {
      final title =
          note.title.isEmpty ? AppStrings.current.untitled : note.title;
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
        await HomeWidget.saveWidgetData<String>(
            'title', AppStrings.current.widgetNoteDeleted);
        await HomeWidget.saveWidgetData<String>(
            'content', AppStrings.current.tapToSelect);
        await HomeWidget.saveWidgetData<int>('note_id', 0);
        await HomeWidget.updateWidget(androidName: 'NoteWidgetProvider');
      }

      if (deletedNoteId == storedChecklistId) {
        await HomeWidget.saveWidgetData<String>(
            'checklist_title', AppStrings.current.widgetListDeleted);
        await HomeWidget.saveWidgetData<String>(
            'checklist_content', AppStrings.current.tapToSelect);
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
      AppLogger.warning(
          'Skipping widget update: Invalid note ID (${note.id})', 'Widget');
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final pinnedNoteId = prefs.getInt('flutter.note_id') ?? 0;
      final pinnedChecklistId = prefs.getInt('flutter.checklist_note_id') ?? 0;

      final service = WidgetService();
      final isChecklistNote = note.isChecklist || note.noteType == 'checklist';

      // الملاحظة المقفلة لا يُكتب محتواها في الويدجت ولا في SharedPreferences
      if (note.isLocked) {
        if (note.id == pinnedNoteId || note.id == pinnedChecklistId) {
          await service.updateNoteWidget(note.copyWith(
            title: '🔒',
            content: '',
            isChecklist: false,
            noteType: 'simple',
          ));
        }
        return;
      }

      if (note.id == pinnedNoteId && !isChecklistNote) {
        await service.updateNoteWidget(note);
      } else if (note.id == pinnedChecklistId && isChecklistNote) {
        final title =
            note.title.isEmpty ? AppStrings.current.checklist : note.title;
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
}
