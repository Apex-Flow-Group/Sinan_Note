// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:convert';
import 'dart:io';

import 'package:apex_note/models/note.dart';
import 'package:apex_note/services/security/vault_service.dart';
import 'package:apex_note/services/storage/isar_database_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class StorageService {
  // ── Export ────────────────────────────────────────────────────────────────

  /// [includeVault] = false → ملاحظات عادية فقط (نص قابل للقراءة)
  /// [includeVault] = true  → كامل مع المشفرة كـ ciphertext
  Future<Map<String, dynamic>> _buildExportData({bool includeVault = false}) async {
    final dbService = IsarDatabaseService();
    final allNotes = await dbService.getAllNotes();

    final notes = includeVault
        ? allNotes.where((n) => !n.isTrashed).toList()
        : allNotes.where((n) => !n.isTrashed && !n.isLocked).toList();

    return {
      'version': '2.0',
      'created_at': DateTime.now().toIso8601String(),
      'has_locked_notes': includeVault && allNotes.any((n) => n.isLocked),
      'notes': notes.map((n) => n.toMap()).toList(),
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

  Future<String> exportNotesToPath(String directoryPath, {bool includeVault = false}) async {
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
          ? 'ملف النسخ الاحتياطي الكامل (يحتوي ملاحظات مشفرة)'
          : 'ملف النسخ الاحتياطي للملاحظات العادية',
    );
  }

  String _fileName(bool includeVault) {
    final ts = DateTime.now().millisecondsSinceEpoch;
    return includeVault
        ? 'sinan_notes_full_$ts.json'
        : 'sinan_notes_$ts.json';
  }

  // ── Import ────────────────────────────────────────────────────────────────

  Future<int> importNotesFromDevice() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.single.path == null) {
      throw Exception('لم يتم اختيار ملف');
    }

    final file = File(result.files.single.path!);
    final jsonString = await file.readAsString();
    if (jsonString.isEmpty) throw Exception('الملف فارغ');

    final dynamic jsonData = jsonDecode(jsonString);
    List<dynamic> notesList;

    if (jsonData is Map<String, dynamic>) {
      notesList = jsonData['notes'] ?? [];
    } else {
      notesList = jsonData;
    }

    if (notesList.isEmpty) throw Exception('لا توجد ملاحظات في الملف');

    // لو الملف يحتوي مشفرة وعنده مفتاح → يفك تلقائياً
    final hasKey = await VaultService.isVaultSetup();
    final notes = <Note>[];
    for (final map in notesList) {
      final note = Note.fromMap(map);
      if (note.isLocked && hasKey && VaultService.isEncrypted(note.content)) {
        try {
          final decTitle = await VaultService.decryptWithMasterKey(note.title);
          final decContent = await VaultService.decryptWithMasterKey(note.content);
          notes.add(note.copyWith(title: decTitle, content: decContent));
        } catch (_) {
          notes.add(note); // يستعيدها مشفرة لو فشل الفك
        }
      } else {
        notes.add(note);
      }
    }

    int count = 0;
    for (final note in notes) {
      if (note.content.isEmpty) continue;
      await IsarDatabaseService().insertNote(Note(
        title: note.title,
        content: note.content,
        createdAt: note.createdAt,
        updatedAt: DateTime.now(),
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
        categoryIds: note.categoryIds,
        isHiddenFromHome: note.isHiddenFromHome,
      ));
      count++;
    }

    if (count == 0) throw Exception('جميع الملاحظات في الملف فارغة');
    return count;
  }
}
