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
  Future<String> exportNotesToDevice() async {
    try {
      final dbService = IsarDatabaseService();
      final notes = await dbService.getNotes();
      if (notes.isEmpty) throw Exception("لا توجد ملاحظات لتصديرها");

      final validNotes = notes.where((n) => !n.isTrashed).toList();
      if (validNotes.isEmpty) throw Exception("لا توجد ملاحظات صالحة للتصدير");

      // Create export data structure
      Map<String, dynamic> exportData = {
        'version': '2.0',
        'notes': validNotes.map((n) => n.toMap()).toList(),
      };
      
      // Add vault data if vault exists
      final vaultData = await VaultService.getVaultDataForBackup();
      if (vaultData != null) {
        exportData['vault_data'] = vaultData;
      }
      
      String jsonString = jsonEncode(exportData);

      final fileName = 'sinan_notes_${DateTime.now().millisecondsSinceEpoch}.json';
      final tempDir = await getTemporaryDirectory();
      final tempPath = join(tempDir.path, fileName);
      final tempFile = File(tempPath);
      await tempFile.writeAsString(jsonString, flush: true);

      final params = SaveFileDialogParams(
        sourceFilePath: tempPath,
        fileName: fileName,
        mimeTypesFilter: ['application/json', 'text/plain'],
      );
      final result = await FlutterFileDialog.saveFile(params: params);
      
      await tempFile.delete();
      
      if (result == null) throw Exception('تم إلغاء الحفظ');
      return 'تم حفظ ${validNotes.length} ملاحظة';
    } catch (e) {
      if (e.toString().contains('Exception:')) rethrow;
      throw Exception('فشل التصدير: ${e.toString()}');
    }
  }

  Future<String> exportNotesToPath(String directoryPath) async {
    try {
      final dbService = IsarDatabaseService();
      final notes = await dbService.getNotes();
      if (notes.isEmpty) throw Exception("لا توجد ملاحظات لتصديرها");

      final validNotes = notes.where((n) => !n.isTrashed).toList();
      if (validNotes.isEmpty) throw Exception("لا توجد ملاحظات صالحة للتصدير");

      // Create export data structure
      Map<String, dynamic> exportData = {
        'version': '2.0',
        'notes': validNotes.map((n) => n.toMap()).toList(),
      };
      
      // Add vault data if vault exists
      final vaultData = await VaultService.getVaultDataForBackup();
      if (vaultData != null) {
        exportData['vault_data'] = vaultData;
      }
      
      String jsonString = jsonEncode(exportData);

      final fileName = 'sinan_notes_${DateTime.now().millisecondsSinceEpoch}.json';
      final outputPath = join(directoryPath, fileName);
      final file = File(outputPath);
      await file.writeAsString(jsonString, flush: true);

      if (!await file.exists()) throw Exception('فشل في إنشاء الملف');

      return 'تم حفظ ${validNotes.length} ملاحظة في:\n$outputPath';
    } catch (e) {
      if (e.toString().contains('Exception:')) rethrow;
      throw Exception('فشل التصدير: ${e.toString()}');
    }
  }

  Future<void> shareNotesFile() async {
    final notes = await IsarDatabaseService().getNotes();
    if (notes.isEmpty) throw Exception("لا توجد ملاحظات لتصديرها");

    final validNotes = notes.where((n) => n.content.isNotEmpty).toList();
    if (validNotes.isEmpty) throw Exception("جميع الملاحظات فارغة");

    // Create export data structure
    Map<String, dynamic> exportData = {
      'version': '2.0',
      'notes': validNotes.map((n) => n.toMap()).toList(),
    };
    
    // Add vault data if vault exists
    final vaultData = await VaultService.getVaultDataForBackup();
    if (vaultData != null) {
      exportData['vault_data'] = vaultData;
    }
    
    String jsonString = jsonEncode(exportData);

    final directory = await getTemporaryDirectory();
    final fileName = 'apex_notes_backup_${DateTime.now().millisecondsSinceEpoch}.json';
    final file = File('${directory.path}/$fileName');

    await file.writeAsString(jsonString);

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'نسخة احتياطية من Sinan Note',
      text: 'ملف النسخ الاحتياطي لملاحظاتي',
    );
  }

  Future<int> importNotesFromDevice() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.single.path == null) {
        throw Exception("لم يتم اختيار ملف");
      }

      File file = File(result.files.single.path!);
      String jsonString = await file.readAsString();

      if (jsonString.isEmpty) throw Exception("الملف فارغ");

      final dynamic jsonData = jsonDecode(jsonString);
      
      List<dynamic> notesList;
      Map<String, dynamic>? vaultData;
      
      // Check if new format (with version and vault_data)
      if (jsonData is Map<String, dynamic>) {
        notesList = jsonData['notes'] ?? [];
        vaultData = jsonData['vault_data'];
        
        // Restore vault data if exists
        if (vaultData != null) {
          await VaultService.restoreVaultDataFromBackup(vaultData);
        }
      } else {
        // Old format (array of notes)
        notesList = jsonData;
      }
      
      if (notesList.isEmpty) throw Exception("لا توجد ملاحظات في الملف");

      List<Note> notes = notesList.map((json) => Note.fromMap(json)).toList();

      int importedCount = 0;
      for (var note in notes) {
        if (note.content.isEmpty) continue;

        Note newNote = Note(
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
        );
        await IsarDatabaseService().insertNote(newNote);
        importedCount++;
      }

      if (importedCount == 0) throw Exception("جميع الملاحظات في الملف فارغة");
      return importedCount;
    } catch (e) {
      if (e.toString().contains('Exception:')) rethrow;
      throw Exception("فشل قراءة الملف: ${e.toString()}");
    }
  }
}
