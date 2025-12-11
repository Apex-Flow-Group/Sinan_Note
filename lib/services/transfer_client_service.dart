// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'database_service.dart';

class TransferException implements Exception {
  final String message;
  final String code;
  TransferException(this.message, this.code);
  @override
  String toString() => message;
}

class TransferClientService {
  final Dio _dio = Dio();

  TransferClientService() {
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.options.sendTimeout = const Duration(seconds: 30);
  }

  String? _tempDbPath;

  Future<int> checkLocalNotesCount() async {
    try {
      final db = await DatabaseService().database;
      final result = await db
          .rawQuery('SELECT COUNT(*) as count FROM notes WHERE isTrashed = 0');
      return result.first['count'] as int;
    } catch (e) {
      return 0;
    }
  }

  Future<void> downloadToTemp(String ip, String port, String token,
      {required Function(double) onProgress}) async {
    final baseUrl = 'http://$ip:$port';

    try {
      // 1. اختبار الاتصال
      try {
        final ping = await _dio.get('$baseUrl/ping');
        if (ping.statusCode != 200) {
          throw TransferException('السيرفر يرفض الاتصال', 'SERVER_REFUSED');
        }
      } on DioException catch (e) {
        String errorMsg = 'تعذر الاتصال: ';
        if (e.type == DioExceptionType.connectionTimeout) {
          errorMsg += 'انتهت مهلة الاتصال. تأكد من نفس الشبكة';
        } else if (e.type == DioExceptionType.connectionError) {
          errorMsg +=
              'خطأ في الشبكة. تأكد من:\n• نفس الواي فاي\n• إيقاف بيانات الهاتف\n• IP: $ip';
        } else {
          errorMsg += e.message ?? 'خطأ غير معروف';
        }
        throw TransferException(errorMsg, 'CONNECTION_FAILED');
      } catch (e) {
        throw TransferException('خطأ: ${e.toString()}', 'CONNECTION_FAILED');
      }

      // 2. التحميل للملف المؤقت
      final dbFolder = await getDatabasesPath();
      _tempDbPath = join(dbFolder, 'notes_incoming.db');

      try {
        await _dio.download(
          '$baseUrl/download-db',
          _tempDbPath!,
          queryParameters: {'token': token},
          onReceiveProgress: (received, total) {
            if (total != -1) onProgress(received / total);
          },
        );
      } on DioException catch (e) {
        if (e.response?.statusCode == 403) {
          throw TransferException('رمز الأمان غير صحيح', 'INVALID_TOKEN');
        }
        throw TransferException(
            'انقطع الاتصال أثناء التحميل', 'DOWNLOAD_INTERRUPTED');
      }

      // 3. التحقق من سلامة الملف
      final tempFile = File(_tempDbPath!);

      if (!await tempFile.exists()) {
        throw TransferException('فشل حفظ الملف', 'FILE_WRITE_ERROR');
      }

      final size = await tempFile.length();
      if (size < 100) {
        throw TransferException(
            'الملف صغير جداً أو تالف', 'CORRUPTED_FILE_SIZE');
      }

      final headerBytes = await tempFile.openRead(0, 16).first;
      final headerString = String.fromCharCodes(headerBytes);
      if (!headerString.startsWith('SQLite format')) {
        throw TransferException(
            'الملف ليس قاعدة بيانات صالحة', 'INVALID_FILE_HEADER');
      }
    } catch (e) {
      if (_tempDbPath != null) {
        final f = File(_tempDbPath!);
        if (await f.exists()) await f.delete();
        _tempDbPath = null;
      }

      if (e is TransferException) rethrow;
      throw TransferException(e.toString(), 'UNKNOWN_ERROR');
    }
  }

  Future<bool> testConnection(String code) async {
    try {
      final parts = code.split(':');
      if (parts.length != 3) return false;
      final response = await _dio.get('http://${parts[0]}:${parts[1]}/ping');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<void> mergeDatabase() async {
    if (_tempDbPath == null) {
      throw TransferException('لا يوجد ملف للدمج', 'NO_TEMP_FILE');
    }

    try {
      final dbFolder = await getDatabasesPath();
      final currentDbPath = join(dbFolder, 'notes.db');

      final currentDb = await openDatabase(currentDbPath);
      final incomingDb = await openDatabase(_tempDbPath!);

      try {
        final incomingNotes = await incomingDb.query('notes');

        for (var note in incomingNotes) {
          final exists = await currentDb.query(
            'notes',
            where: 'title = ? AND content = ? AND createdAt = ?',
            whereArgs: [note['title'], note['content'], note['createdAt']],
          );

          if (exists.isEmpty) {
            await currentDb.insert('notes', {
              ...note,
              'id': null,
            });
          }
        }
      } finally {
        await incomingDb.close();
        await currentDb.close();
      }

      await File(_tempDbPath!).delete();
      _tempDbPath = null;
    } catch (e) {
      throw TransferException('فشل الدمج: ${e.toString()}', 'MERGE_FAILED');
    }
  }

  Future<void> replaceWithIncoming() async {
    if (_tempDbPath == null) {
      throw TransferException('لا يوجد ملف للاستبدال', 'NO_TEMP_FILE');
    }

    try {
      final dbService = DatabaseService();
      await dbService.closeDB();

      final dbFolder = await getDatabasesPath();
      final currentDbPath = join(dbFolder, 'notes.db');
      final backupPath = join(dbFolder, 'notes_backup.db');

      final currentDb = File(currentDbPath);
      final tempFile = File(_tempDbPath!);

      if (await currentDb.exists()) {
        await currentDb.copy(backupPath);
      }

      try {
        await tempFile.copy(currentDbPath);
        await tempFile.delete();
        if (await File(backupPath).exists()) {
          await File(backupPath).delete();
        }
        _tempDbPath = null;
        await dbService.reopenDatabase();
      } catch (e) {
        if (await File(backupPath).exists()) {
          await File(backupPath).copy(currentDbPath);
        }
        throw TransferException('فشل الاستبدال', 'REPLACE_FAILED');
      }
    } catch (e) {
      throw TransferException(
          'فشل الاستبدال: ${e.toString()}', 'REPLACE_FAILED');
    }
  }

  Future<void> cancelTransfer() async {
    _dio.close(force: true);
    if (_tempDbPath != null) {
      final f = File(_tempDbPath!);
      if (await f.exists()) await f.delete();
      _tempDbPath = null;
    }
  }

  Future<void> dispose() async {
    await cancelTransfer();
  }
}
