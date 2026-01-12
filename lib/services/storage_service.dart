// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import '../config/flavor_config.dart';
import '../models/note.dart';
import 'database_service.dart';

class StorageService {
  Future<String> exportNotesToDevice() async {
    try {
      final dbService = DatabaseService();
      final notes = await dbService.getNotes();
      if (notes.isEmpty) throw Exception("لا توجد ملاحظات لتصديرها");

      final validNotes = notes.where((n) => !n.isTrashed).toList();
      if (validNotes.isEmpty) throw Exception("لا توجد ملاحظات صالحة للتصدير");

      final notesMapList = validNotes.map((n) => n.toMap()).toList();
      String jsonString = jsonEncode(notesMapList);

      final fileName =
          'sinan_notes_${DateTime.now().millisecondsSinceEpoch}.json';

      if (FlavorConfig.isGooglePlay && Platform.isAndroid) {
        // Google Play: Use scoped storage with file picker
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
      } else {
        // F-Droid or other platforms: Direct path
        Directory? directory;
        if (Platform.isAndroid) {
          final dir = Directory('/storage/emulated/0/Download/SinanNotes');
          if (!await dir.exists()) {
            await dir.create(recursive: true);
          }
          directory = dir;
        } else if (Platform.isWindows) {
          directory = await getDownloadsDirectory();
        } else {
          directory = await getApplicationDocumentsDirectory();
        }

        final outputPath = join(directory!.path, fileName);
        final file = File(outputPath);
        await file.writeAsString(jsonString, flush: true);

        if (!await file.exists()) {
          throw Exception('فشل في إنشاء الملف');
        }

        return 'تم حفظ ${validNotes.length} ملاحظة في:\n$outputPath';
      }
    } catch (e) {
      if (e.toString().contains('Exception:')) rethrow;
      throw Exception('فشل التصدير: ${e.toString()}');
    }
  }

  Future<String> exportNotesToPath(String directoryPath) async {
    try {
      final dbService = DatabaseService();
      final notes = await dbService.getNotes();
      if (notes.isEmpty) throw Exception("لا توجد ملاحظات لتصديرها");

      final validNotes = notes.where((n) => !n.isTrashed).toList();
      if (validNotes.isEmpty) throw Exception("لا توجد ملاحظات صالحة للتصدير");

      final notesMapList = validNotes.map((n) => n.toMap()).toList();
      String jsonString = jsonEncode(notesMapList);

      final fileName =
          'sinan_notes_${DateTime.now().millisecondsSinceEpoch}.json';
      final outputPath = join(directoryPath, fileName);
      final file = File(outputPath);
      await file.writeAsString(jsonString, flush: true);

      if (!await file.exists()) {
        throw Exception('فشل في إنشاء الملف');
      }

      return 'تم حفظ ${validNotes.length} ملاحظة في:\n$outputPath';
    } catch (e) {
      if (e.toString().contains('Exception:')) rethrow;
      throw Exception('فشل التصدير: ${e.toString()}');
    }
  }

  Future<void> shareNotesFile() async {
    final notes = await DatabaseService().getNotes();
    if (notes.isEmpty) throw Exception("لا توجد ملاحظات لتصديرها");

    final validNotes = notes.where((n) => n.content.isNotEmpty).toList();
    if (validNotes.isEmpty) throw Exception("جميع الملاحظات فارغة");

    final notesMapList = validNotes.map((n) => n.toMap()).toList();
    String jsonString = jsonEncode(notesMapList);

    final directory = await getTemporaryDirectory();
    final fileName =
        'apex_notes_backup_${DateTime.now().millisecondsSinceEpoch}.json';
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

      List<dynamic> jsonList = jsonDecode(jsonString);
      if (jsonList.isEmpty) throw Exception("لا توجد ملاحظات في الملف");

      List<Note> notes = jsonList.map((json) => Note.fromMap(json)).toList();

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
        await DatabaseService().insertNote(newNote);
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
