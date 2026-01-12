// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:io';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'database_service.dart';
import 'apex_error_manager.dart';

class TransferService {
  HttpServer? _server;
  static const int _port = 8765;

  Future<String?> getLocalIpAddress() async {
    try {
      final interfaces = await NetworkInterface.list();

      // Priority 1: Look for wlan0 (Android) or en0 (iOS)
      for (var interface in interfaces) {
        if (interface.name == 'wlan0' || interface.name == 'en0') {
          for (var addr in interface.addresses) {
            if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
              return addr.address;
            }
          }
        }
      }

      // Priority 2: Look for 192.168.x.x addresses
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 &&
              !addr.isLoopback &&
              addr.address.startsWith('192.168.')) {
            return addr.address;
          }
        }
      }

      // Priority 3: Any non-loopback IPv4 (excluding 100.x carrier NAT)
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 &&
              !addr.isLoopback &&
              !addr.address.startsWith('100.')) {
            return addr.address;
          }
        }
      }

      // Fallback: Return first available IPv4 (even if 100.x)
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            return addr.address;
          }
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  Future<String?> startServer() async {
    return await ApexErrorManager.monitorCritical(() async {
      final ip = await getLocalIpAddress();
      if (ip == null) throw Exception('لا يمكن الحصول على عنوان IP');

      final dbPath = join(await getDatabasesPath(), 'notes.db');
      final dbFile = File(dbPath);
      if (!await dbFile.exists()) {
        await DatabaseService().database;
      }

      final router = Router();

      router.get('/download-db', (shelf.Request request) async {
        try {
          final bytes = await dbFile.readAsBytes();
          return shelf.Response.ok(bytes, headers: {
            'Content-Type': 'application/octet-stream',
            'Content-Disposition': 'attachment; filename="notes.db"',
            'Content-Length': bytes.length.toString(),
          });
        } catch (e) {
          return shelf.Response.internalServerError(body: 'خطأ: $e');
        }
      });

      router.get('/ping', (shelf.Request request) {
        return shelf.Response.ok('Sinan Transfer Server');
      });

      _server = await shelf_io.serve(router.call, ip, _port);
      return 'http://$ip:$_port';
    }, 'Transfer_StartServer');
  }

  Future<void> stopServer() async {
    await _server?.close(force: true);
    _server = null;
  }

  Future<bool> downloadDatabase(String serverUrl) async {
    return await ApexErrorManager.monitorCritical(() async {
      final dbService = DatabaseService();
      await dbService.closeDB();

      final dio = Dio();
      final dbPath = join(await getDatabasesPath(), 'notes.db');
      final tempPath = join(await getDatabasesPath(), 'notes_temp.db');

      try {
        await dio.download('$serverUrl/download-db', tempPath,
            options: Options(
              receiveTimeout: const Duration(seconds: 30),
              sendTimeout: const Duration(seconds: 30),
            ));

        final tempFile = File(tempPath);
        if (!await tempFile.exists()) throw Exception('فشل التحميل');

        final dbFile = File(dbPath);
        if (await dbFile.exists()) await dbFile.delete();
        await tempFile.rename(dbPath);
        await dbService.reopenDatabase();

        return true;
      } catch (e) {
        final tempFile = File(tempPath);
        if (await tempFile.exists()) await tempFile.delete();
        rethrow;
      }
    }, 'Transfer_Download');
  }

  Future<bool> testConnection(String serverUrl) async {
    try {
      final dio = Dio();
      final response = await dio.get(
        '$serverUrl/ping',
        options: Options(
          receiveTimeout: const Duration(seconds: 5),
          sendTimeout: const Duration(seconds: 5),
        ),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
