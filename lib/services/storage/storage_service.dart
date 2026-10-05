// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sinan_note/data/services/database/note_mapper.dart';
import 'package:sinan_note/services/storage/sqlite_database_service.dart';

class StorageService {
  // ── Export ────────────────────────────────────────────────────────────────

  /// [includeVault] = false → ملاحظات عادية فقط (نص قابل للقراءة)
  /// [includeVault] = true  → كامل مع المشفرة كـ ciphertext
  Future<Map<String, dynamic>> _buildExportData(
      {bool includeVault = false}) async {
    final dbService = SqliteDatabaseService();
    final allNotes = await dbService.getAllNotes();

    final notes = includeVault
        ? allNotes.where((n) => !n.isTrashed).toList()
        : allNotes.where((n) => !n.isTrashed && !n.isLocked).toList();

    return {
      'version': '2.0',
      'created_at': DateTime.now().toIso8601String(),
      'has_locked_notes': includeVault && allNotes.any((n) => n.isLocked),
      'notes': notes.map((n) => NoteMapper.toMap(n)).toList(),
    };
  }

  Future<String> exportNotesToDevice({bool includeVault = false}) async {
    try {
      final data = await _buildExportData(includeVault: includeVault);
      final notes = data['notes'] as List;
      if (notes.isEmpty) throw Exception('لا توجد ملاحظات لتصديرها');

      final fileName = _fileName(includeVault);
      final tempDir = await getTemporaryDirectory();
      final tempPath = join(tempDir.path, fileName);
      final tempFile = File(tempPath);
      await tempFile.writeAsString(jsonEncode(data), flush: true);

      final params = SaveFileDialogParams(
        sourceFilePath: tempPath,
        fileName: fileName,
        mimeTypesFilter: ['application/json', 'text/plain'],
      );
      final result = await FlutterFileDialog.saveFile(params: params);
      await tempFile.delete();

      if (result == null) throw Exception('تم إلغاء الحفظ');
      return 'تم حفظ ${notes.length} ملاحظة';
    } catch (e) {
      if (e.toString().contains('Exception:')) rethrow;
      throw Exception('فشل التصدير: $e');
    }
  }

  Future<String> exportNotesToPath(String directoryPath,
      {bool includeVault = false}) async {
    try {
      final data = await _buildExportData(includeVault: includeVault);
      final notes = data['notes'] as List;
      if (notes.isEmpty) throw Exception('لا توجد ملاحظات لتصديرها');

      final fileName = _fileName(includeVault);
      final outputPath = join(directoryPath, fileName);
      await File(outputPath).writeAsString(jsonEncode(data), flush: true);

      return 'تم حفظ ${notes.length} ملاحظة في:\n$outputPath';
    } catch (e) {
      if (e.toString().contains('Exception:')) rethrow;
      throw Exception('فشل التصدير: $e');
    }
  }

  Future<void> shareNotesFile({bool includeVault = false}) async {
    final data = await _buildExportData(includeVault: includeVault);
    final notes = data['notes'] as List;
    if (notes.isEmpty) throw Exception('لا توجد ملاحظات لتصديرها');

    final fileName = _fileName(includeVault);
    final tempDir = await getTemporaryDirectory();
    final file = File(join(tempDir.path, fileName));
    await file.writeAsString(jsonEncode(data));

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'نسخة احتياطية من Sinan Note',
      text: includeVault
          ? 'ملف النسخ الاحتياطي الكامل (يتضمن ملاحظات مشفرة)'
          : 'ملف النسخ الاحتياطي للملاحظات العادية',
    );
  }

  String _fileName(bool includeVault) {
    final ts = DateTime.now().millisecondsSinceEpoch;
    return includeVault ? 'sinan_notes_full_$ts.json' : 'sinan_notes_$ts.json';
  }
}
