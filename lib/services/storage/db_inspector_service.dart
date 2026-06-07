// Copyright © 2025 Apex Flow Group. All rights reserved.
// DB Inspector — يعرض تقرير كامل عن SQLite

import 'dart:io';import 'package:flutter/material.dart'; import 'package:flutter/services.dart';import 'package:sinan_note/services/storage/sqlite_database_service.dart'; import 'package:sqflite/sqflite.dart';
class DbInspectorService {
  static Future<void> showReport(BuildContext context) async {
    final report = await _buildReport();
    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReportSheet(report: report),
    );
  }

  static Future<Map<String, dynamic>> _buildReport() async {
    final result = <String, dynamic>{};

    // ── SQLite (notes/categories/versions) ────────────────────────────────
    try {
      final dbService = SqliteDatabaseService();
      final notes = await dbService.getAllNotes();
      final categories = await dbService.getAllCategories();
      final deletedIds = await SqliteDatabaseService.getDeletedNoteIds();

      // عدد كل الـ versions
      int totalVersions = 0;
      for (final n in notes) {
        if (n.id != null) {
          final v = await dbService.getNoteHistory(n.id!);
          totalVersions += v.length;
        }
      }

      result['notes_summary'] = {
        'notes': notes.length,
        'locked': notes.where((n) => n.isLocked).length,
        'archived': notes.where((n) => n.isArchived).length,
        'trashed': notes.where((n) => n.isTrashed).length,
        'categories': categories.length,
        'deleted': deletedIds.length,
        'versions': totalVersions,
        'sample': notes
            .take(5)
            .map((n) => {
                  'id': n.id,
                  'title': n.title.length > 30
                      ? '${n.title.substring(0, 30)}…'
                      : n.title,
                  'type': n.noteType,
                  'locked': n.isLocked,
                })
            .toList(),
      };
    } catch (e) {
      result['notes_summary'] = {'error': e.toString()};
    }

    // ── SQLite ─────────────────────────────────────────────────────────────
    try {
      final dbPath = await _getSqlitePath();
      final exists = await File(dbPath).exists();
      if (!exists) {
        result['sqlite'] = {'error': 'File not found: $dbPath'};
      } else {
        final fileSize = await File(dbPath).length();
        final db = await openDatabase(dbPath, readOnly: true);
        final tables = await db
            .rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
        final counts = <String, int>{};
        for (final t in tables) {
          final name = t['name'] as String;
          if (name.startsWith('sqlite_')) continue;
          final r = await db.rawQuery('SELECT COUNT(*) as c FROM "$name"');
          counts[name] = (r.first['c'] as int?) ?? 0;
        }
        final sample = await db.rawQuery(
            'SELECT id, title, noteType, isLocked FROM notes LIMIT 5');
        await db.close();
        result['sqlite'] = {
          'path': dbPath,
          'size_kb': (fileSize / 1024).toStringAsFixed(1),
          'tables': counts,
          'sample': sample,
        };
      }
    } catch (e) {
      result['sqlite'] = {'error': e.toString()};
    }

    return result;
  }

  static Future<String> _getSqlitePath() => SqliteDatabaseService.getDbPath();
}

// ── Report Sheet ───────────────────────────────────────────────────────────

class _ReportSheet extends StatelessWidget {
  final Map<String, dynamic> report;
  const _ReportSheet({required this.report});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = _formatReport(report);

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, sc) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  const Icon(Icons.storage_rounded,
                      size: 18, color: Colors.orange),
                  const SizedBox(width: 8),
                  const Text('DB Inspector',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 20),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: text));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Copied'),
                          duration: Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                controller: sc,
                padding: const EdgeInsets.all(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF12121F)
                        : const Color(0xFFF6F8FA),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.08),
                    ),
                  ),
                  child: SelectableText(
                    text,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      height: 1.6,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatReport(Map<String, dynamic> r) {
    final buf = StringBuffer();
    buf.writeln('═══════════════════════════');
    buf.writeln('  DB INSPECTOR REPORT');
    buf.writeln('  ${DateTime.now().toLocal()}');
    buf.writeln('═══════════════════════════\n');

    // Isar
    buf.writeln('── NOTES SUMMARY ─────────');
    final isar = r['notes_summary'] as Map?;
    if (isar?['error'] != null) {
      buf.writeln('ERROR: ${isar!['error']}');
    } else if (isar != null) {
      buf.writeln('notes:      ${isar['notes']}');
      buf.writeln('  locked:   ${isar['locked']}');
      buf.writeln('  archived: ${isar['archived']}');
      buf.writeln('  trashed:  ${isar['trashed']}');
      buf.writeln('categories: ${isar['categories']}');
      buf.writeln('deleted:    ${isar['deleted']}');
      buf.writeln('versions:   ${isar['versions']}');
      buf.writeln('\nSample notes:');
      for (final n in (isar['sample'] as List)) {
        buf.writeln(
            '  [${n['id']}] ${n['title']} (${n['type']})${n['locked'] == true ? ' 🔒' : ''}');
      }
    }

    buf.writeln('\n── SQLITE ────────────────');
    final sqlite = r['sqlite'] as Map?;
    if (sqlite?['error'] != null) {
      buf.writeln('ERROR: ${sqlite!['error']}');
    } else if (sqlite != null) {
      buf.writeln('path:    ${sqlite['path']}');
      buf.writeln('size:    ${sqlite['size_kb']} KB');
      buf.writeln('\nTable counts:');
      for (final e in (sqlite['tables'] as Map).entries) {
        buf.writeln('  ${e.key.padRight(20)} ${e.value}');
      }
      buf.writeln('\nSample notes:');
      for (final n in (sqlite['sample'] as List)) {
        buf.writeln(
            '  [${n['id']}] ${n['title']} (${n['noteType']})${n['isLocked'] == 1 ? ' 🔒' : ''}');
      }
    }

    buf.writeln('\n═══════════════════════════');
    return buf.toString();
  }
}

