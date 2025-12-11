// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:io';
import 'dart:math';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

class LocalServerService {
  HttpServer? _server;
  String? _securityToken;
  static const int defaultPort = 8765;

  String generateSecurityToken() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    return List.generate(8, (index) => chars[random.nextInt(chars.length)])
        .join();
  }

  Future<String> startFileServer(File dbFile, {int port = defaultPort}) async {
    if (_server != null) {
      throw Exception('Server already running');
    }

    if (!await dbFile.exists()) {
      throw Exception('Database file not found');
    }

    _securityToken = generateSecurityToken();
    final router = Router();

    router.get('/download-db', (shelf.Request request) async {
      try {
        final token = request.url.queryParameters['token'];

        if (token == null || token != _securityToken) {
          return shelf.Response.forbidden(
              'Access Denied: Invalid or missing security token');
        }

        final bytes = await dbFile.readAsBytes();
        return shelf.Response.ok(
          bytes,
          headers: {
            'Content-Type': 'application/octet-stream',
            'Content-Disposition': 'attachment; filename="notes.db"',
            'Content-Length': bytes.length.toString(),
            'Access-Control-Allow-Origin': '*',
          },
        );
      } catch (e) {
        return shelf.Response.internalServerError(
            body: 'Error reading file: $e');
      }
    });

    router.get('/ping', (shelf.Request request) {
      return shelf.Response.ok('Sinan Transfer Server Active');
    });

    final ip = await _getLocalIpAddress();
    if (ip == null) {
      throw Exception(
          'Cannot get local IP address. Make sure WiFi is enabled.');
    }

    _server = await shelf_io.serve(
      router.call,
      ip,
      port,
    );

    return 'http://$ip:$port/download-db?token=$_securityToken';
  }

  Future<void> stopServer() async {
    await _server?.close(force: true);
    _server = null;
    _securityToken = null;
  }

  String? get securityToken => _securityToken;

  Future<String?> _getLocalIpAddress() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );

      // البحث عن IP محلي فقط (شبكات خاصة)
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (!addr.isLoopback) {
            final ip = addr.address;
            // 192.168.x.x (Class C private)
            if (ip.startsWith('192.168.')) {
              return ip;
            }
            // 10.x.x.x (Class A private)
            if (ip.startsWith('10.')) {
              return ip;
            }
            // 172.16.x.x - 172.31.x.x (Class B private)
            if (ip.startsWith('172.')) {
              final parts = ip.split('.');
              if (parts.length == 4) {
                final second = int.tryParse(parts[1]);
                if (second != null && second >= 16 && second <= 31) {
                  return ip;
                }
              }
            }
          }
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  bool get isRunning => _server != null;
}
