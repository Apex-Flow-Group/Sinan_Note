// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import '../services/widget_service.dart';
import '../services/database_service.dart';
import '../models/note.dart';

class WidgetSelectionScreen extends StatefulWidget {
  final String widgetType; // 'note' or 'checklist'

  const WidgetSelectionScreen({super.key, this.widgetType = 'note'});

  @override
  State<WidgetSelectionScreen> createState() => _WidgetSelectionScreenState();
}

class _WidgetSelectionScreenState extends State<WidgetSelectionScreen> {
  List<Note> notes = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final dbService = DatabaseService();
    final allNotes = await dbService.getAllNotes();
    setState(() {
      if (widget.widgetType == 'checklist') {
        notes = allNotes
            .where((n) =>
                !n.isLocked && !n.isTrashed && !n.isArchived && 
                (n.isChecklist == true || n.noteType == 'checklist'))
            .toList();
      } else {
        notes = allNotes
            .where((n) =>
                !n.isLocked && !n.isTrashed && !n.isArchived && 
                n.isChecklist != true && n.noteType != 'checklist')
            .toList();
      }
      isLoading = false;
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              'تم تثبيت "${note.title.isEmpty ? 'الملاحظة' : note.title}" في الويدجت ✅')),
    );

    Navigator.pop(context);
  }

  Map<String, int> _parseChecklistStats(String content) {
    try {
      final decoded = content.isNotEmpty ? 
          (content.startsWith('[') || content.startsWith('{') ? 
              _parseJson(content) : <dynamic>[]) : <dynamic>[];
      
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

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.widgetType == 'checklist'
            ? 'اختر قائمة للتثبيت'
            : 'اختر ملاحظة للتثبيت'),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : notes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.note_add_outlined,
                          size: 80, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(l10n.noNotesAvailable,
                          style: const TextStyle(
                              fontSize: 18, color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: notes.length,
                  itemBuilder: (context, index) {
                    final note = notes[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: ListTile(
                        title: Text(
                          note.title.isNotEmpty ? note.title : "بدون عنوان",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          note.content,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(Icons.push_pin_outlined,
                            color: Colors.blue),
                        onTap: () => _selectNoteForWidget(note),
                      ),
                    );
                  },
                ),
    );
  }
}
