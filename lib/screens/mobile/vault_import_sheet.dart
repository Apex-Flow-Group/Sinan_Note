// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:convert';

import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:apex_note/models/note.dart';
import 'package:flutter/material.dart';

/// Bottom sheet لاستيراد الملاحظات غير المقفلة إلى الخزنة.
///
/// يُعرض من [LockedNotesScreen._showImportSheet].
/// يسمح للمستخدم بالبحث والفلترة واختيار ملاحظات لنقلها للخزنة.
class VaultImportSheet extends StatefulWidget {
  final List<Note> unlocked;
  final Set<int> selected;
  final Future<void> Function() onConfirm;

  const VaultImportSheet({
    super.key,
    required this.unlocked,
    required this.selected,
    required this.onConfirm,
  });

  @override
  State<VaultImportSheet> createState() => _VaultImportSheetState();
}

class _VaultImportSheetState extends State<VaultImportSheet> {
  final _searchCtrl = TextEditingController();
  String? _filter; // null = الكل

  static const _filterTypes = [
    ('simple', Icons.notes_rounded, null),
    ('rich', Icons.format_color_text, null),
    ('checklist', Icons.checklist_rounded, null),
    ('code', Icons.code_rounded, null),
    ('reminder', Icons.alarm_rounded, null),
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _typeKey(Note note) {
    if (note.isChecklist || note.noteType == 'checklist') return 'checklist';
    if (note.isProfessional || note.noteType == 'code') return 'code';
    if (note.noteType == 'reminder') return 'reminder';
    if (note.noteType == 'rich') return 'rich';
    return 'simple';
  }

  (String, String) _displayInfo(Note note, AppLocalizations l10n) {
    String title = note.title.isEmpty ? l10n.untitled : note.title;
    String content;

    if (note.isChecklist) {
      try {
        final decoded = jsonDecode(note.content);
        if (decoded is Map) {
          final t = (decoded['title'] ?? '').toString().trim();
          if (t.isNotEmpty) title = t;
          final items = decoded['items'] as List? ?? [];
          content = items
              .map((i) =>
                  '${i['isDone'] == true ? '☑' : '☐'} ${i['text'] ?? ''}')
              .join('  ');
          if (content.isEmpty) content = '${items.length} items';
        } else {
          content = 'Checklist';
        }
      } catch (_) {
        content = 'Checklist';
      }
    } else {
      final raw = note.content.trim();
      if (raw.startsWith('[') || raw.startsWith('{')) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is List) {
            content = decoded.map((op) => op['insert'] ?? '').join().trim();
          } else {
            content = raw;
          }
        } catch (_) {
          content = raw;
        }
      } else {
        content = raw;
      }
    }

    return (title, content);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final query = _searchCtrl.text.trim().toLowerCase();

    // أنواع موجودة فعلاً
    final availableTypes = _filterTypes
        .where((f) => widget.unlocked.any((n) => _typeKey(n) == f.$1))
        .toList();

    final filterLabels = {
      'simple': l10n.simpleNote,
      'rich': l10n.richNoteMenu,
      'checklist': l10n.checklistNote,
      'code': l10n.codeNote,
      'reminder': l10n.reminder,
    };

    // تطبيق الفلتر والبحث
    final visible = widget.unlocked.where((n) {
      if (_filter != null && _typeKey(n) != _filter) return false;
      if (query.isEmpty) return true;
      final (title, content) = _displayInfo(n, l10n);
      return title.toLowerCase().contains(query) ||
          content.toLowerCase().contains(query);
    }).toList();

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.82,
        child: Column(
          children: [
            // ─── Handle ───────────────────────────────────────────
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ─── Title row ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.importNotes,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (widget.selected.isNotEmpty)
                    Text(
                      '${widget.selected.length} ${l10n.selected}',
                      style: TextStyle(
                          fontSize: 13,
                          color: scheme.primary,
                          fontWeight: FontWeight.w600),
                    ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // ─── Search bar ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: l10n.searchNotes,
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: scheme.onSurface.withValues(alpha: 0.07),
                ),
              ),
            ),

            // ─── Filter chips ─────────────────────────────────────
            if (availableTypes.length >= 2)
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 4, right: 4),
                      child: FilterChip(
                        label: Text(l10n.clearFilter),
                        selected: _filter == null,
                        onSelected: (_) => setState(() => _filter = null),
                        showCheckmark: false,
                        selectedColor: scheme.primary,
                        labelStyle: TextStyle(
                          color: _filter == null
                              ? scheme.onPrimary
                              : scheme.onSurface,
                          fontSize: 12,
                          fontWeight: _filter == null
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    ...availableTypes.map((f) {
                      final isActive = _filter == f.$1;
                      return Padding(
                        padding: const EdgeInsets.only(left: 4, right: 4),
                        child: FilterChip(
                          label: Text(filterLabels[f.$1] ?? f.$1),
                          avatar: Icon(f.$2,
                              size: 14,
                              color: isActive
                                  ? scheme.onPrimary
                                  : scheme.onSurface),
                          selected: isActive,
                          onSelected: (_) =>
                              setState(() => _filter = isActive ? null : f.$1),
                          showCheckmark: false,
                          selectedColor: scheme.primary,
                          labelStyle: TextStyle(
                            color:
                                isActive ? scheme.onPrimary : scheme.onSurface,
                            fontSize: 12,
                            fontWeight:
                                isActive ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),

            const Divider(height: 8),

            // ─── List ─────────────────────────────────────────────
            Expanded(
              child: visible.isEmpty
                  ? Center(
                      child: Text(l10n.noResults,
                          style: const TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: visible.length,
                      itemBuilder: (context, i) {
                        final note = visible[i];
                        final isSelected = widget.selected.contains(note.id);
                        final (title, content) = _displayInfo(note, l10n);
                        return CheckboxListTile(
                          value: isSelected,
                          onChanged: (val) => setState(() {
                            if (val == true) {
                              widget.selected.add(note.id!);
                            } else {
                              widget.selected.remove(note.id);
                            }
                          }),
                          title: Text(title,
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(content,
                              maxLines: 2, overflow: TextOverflow.ellipsis),
                          secondary: Icon(
                            _filterTypes
                                .firstWhere((f) => f.$1 == _typeKey(note),
                                    orElse: () => _filterTypes.first)
                                .$2,
                            size: 20,
                            color: scheme.onSurface.withValues(alpha: 0.5),
                          ),
                        );
                      },
                    ),
            ),

            // ─── Confirm button ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: SafeArea(
                child: ElevatedButton.icon(
                  onPressed: widget.selected.isEmpty ? null : widget.onConfirm,
                  icon: const Icon(Icons.lock),
                  label: Text(l10n.lockNotesCount(widget.selected.length)),
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48)),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
