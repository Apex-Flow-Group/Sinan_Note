// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:convert';

import 'package:apex_note/core/utils/note_content_utils.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:apex_note/models/note.dart';
import 'package:apex_note/services/storage/sqlite_database_service.dart';
import 'package:apex_note/services/unified_notification_service.dart';
import 'package:apex_note/services/widget_service.dart';
import 'package:flutter/material.dart';

class WidgetSelectionScreen extends StatefulWidget {
  final String widgetType; // 'note' or 'checklist'
  final int currentNoteId; // النوت الحالية المثبتة

  const WidgetSelectionScreen({
    super.key,
    this.widgetType = 'note',
    this.currentNoteId = 0,
  });

  @override
  State<WidgetSelectionScreen> createState() => _WidgetSelectionScreenState();
}

class _WidgetSelectionScreenState extends State<WidgetSelectionScreen> {
  List<Note> notes = [];
  List<Note> filteredNotes = [];
  bool isLoading = true;
  String searchQuery = '';
  String filterType = 'all'; // 'all', 'pinned', 'recent'

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final dbService = SqliteDatabaseService();
    final allNotes = await dbService.getAllNotes();
    setState(() {
      if (widget.widgetType == 'checklist') {
        notes = allNotes
            .where((n) =>
                n.isLocked == false &&
                n.isTrashed == false &&
                n.isArchived == false &&
                (n.isChecklist == true || n.noteType == 'checklist'))
            .toList();
      } else {
        notes = allNotes
            .where((n) =>
                n.isLocked == false &&
                n.isTrashed == false &&
                n.isArchived == false &&
                n.isChecklist != true &&
                n.noteType != 'checklist')
            .toList();
      }
      _applyFilter();
      isLoading = false;
    });
  }

  void _applyFilter() {
    List<Note> result = List.from(notes);

    // فلتر البحث
    if (searchQuery.isNotEmpty) {
      result = result.where((note) {
        final title = note.title.toLowerCase();
        final content = note.content.toLowerCase();
        final query = searchQuery.toLowerCase();
        return title.contains(query) || content.contains(query);
      }).toList();
    }

    // فلتر النوع
    if (filterType == 'pinned') {
      result = result.where((n) => n.isPinned).toList();
    } else if (filterType == 'recent') {
      result.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      result = result.take(10).toList();
    } else {
      // all: مثبتة أولاً ثم الأحدث
      result.sort((a, b) {
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        return b.updatedAt.compareTo(a.updatedAt);
      });
    }

    setState(() {
      filteredNotes = result;
    });
  }

  Future<void> _selectNoteForWidget(Note note) async {
    if (widget.widgetType == 'checklist') {
      final stats = _parseChecklistStats(note.content);
      await WidgetService().updateChecklistWidget(
        note.id ?? 0,
        note.title.isEmpty ? 'Checklist' : note.title,
        note.content,
        note.colorIndex,
        totalItems: stats['total'] ?? 0,
        completedItems: stats['completed'] ?? 0,
      );
    } else {
      await WidgetService().updateNoteWidget(note);
    }

    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final title = note.title.isEmpty
        ? (widget.widgetType == 'checklist' ? l10n.checklist : l10n.note)
        : note.title;

    UnifiedNotificationService().show(
      context: context,
      message: '${l10n.widgetPinned} "$title"',
      type: NotificationType.success,
    );

    Navigator.pop(context);
  }

  Map<String, int> _parseChecklistStats(String content) {
    try {
      final decoded = content.isNotEmpty
          ? (content.startsWith('[') || content.startsWith('{')
              ? _parseJson(content)
              : <dynamic>[])
          : <dynamic>[];

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

  dynamic _parseJson(String content) {
    try {
      return const JsonDecoder().convert(content);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.widgetType == 'checklist'
            ? (isArabic ? 'اختر قائمة للتثبيت' : 'Select Checklist')
            : (isArabic ? 'اختر ملاحظة للتثبيت' : 'Select Note')),
        centerTitle: true,
        actions: [
          // فلتر النوع
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                filterType = value;
                _applyFilter();
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'all',
                child: Row(
                  children: [
                    Icon(Icons.list,
                        color: filterType == 'all'
                            ? Theme.of(context).colorScheme.primary
                            : null),
                    const SizedBox(width: 8),
                    Text(isArabic ? 'الكل' : 'All'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'pinned',
                child: Row(
                  children: [
                    Icon(Icons.push_pin,
                        color: filterType == 'pinned'
                            ? Theme.of(context).colorScheme.primary
                            : null),
                    const SizedBox(width: 8),
                    Text(isArabic ? 'مثبتة' : 'Pinned'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'recent',
                child: Row(
                  children: [
                    Icon(Icons.access_time,
                        color: filterType == 'recent'
                            ? Theme.of(context).colorScheme.primary
                            : null),
                    const SizedBox(width: 8),
                    Text(isArabic ? 'الأحدث' : 'Recent'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // شريط البحث
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: isArabic ? 'بحث...' : 'Search...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            searchQuery = '';
                            _applyFilter();
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                  _applyFilter();
                });
              },
            ),
          ),

          // عداد النتائج
          if (!isLoading && filteredNotes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Text(
                    isArabic
                        ? 'عدد النتائج: ${filteredNotes.length}'
                        : 'Results: ${filteredNotes.length}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                      fontSize: 13,
                    ),
                  ),
                  if (widget.currentNoteId > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isArabic ? 'مثبت حالياً' : 'Currently Pinned',
                        style: TextStyle(
                          fontSize: 11,
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

          // قائمة النتائج
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredNotes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              searchQuery.isNotEmpty
                                  ? Icons.search_off
                                  : Icons.note_add_outlined,
                              size: 80,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              searchQuery.isNotEmpty
                                  ? (isArabic
                                      ? 'لا توجد نتائج'
                                      : 'No results found')
                                  : l10n.noNotesAvailable,
                              style: const TextStyle(
                                  fontSize: 18, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredNotes.length,
                        itemBuilder: (context, index) {
                          final note = filteredNotes[index];
                          final isCurrentlyPinned =
                              note.id == widget.currentNoteId;

                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            elevation: isCurrentlyPinned ? 4 : 1,
                            color: isCurrentlyPinned
                                ? Theme.of(context)
                                    .colorScheme
                                    .primaryContainer
                                    .withValues(alpha: 0.3)
                                : null,
                            child: ListTile(
                              leading: Icon(
                                note.isPinned ? Icons.push_pin : Icons.note,
                                color: isCurrentlyPinned
                                    ? Theme.of(context).colorScheme.primary
                                    : (note.isPinned ? Colors.orange : null),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      note.title.isNotEmpty
                                          ? note.title
                                          : (isArabic
                                              ? 'بدون عنوان'
                                              : 'Untitled'),
                                      style: TextStyle(
                                        fontWeight: isCurrentlyPinned
                                            ? FontWeight.bold
                                            : FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  if (isCurrentlyPinned)
                                    Icon(
                                      Icons.check_circle,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      size: 20,
                                    ),
                                ],
                              ),
                              subtitle: Text(
                                NoteContentUtils.toDisplayText(note.content),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Icon(
                                Icons.chevron_right,
                                color: isCurrentlyPinned
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey,
                              ),
                              onTap: () => _selectNoteForWidget(note),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
