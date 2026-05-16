// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void initializeTestEnvironment() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // تهيئة SQLite لبيئة الاختبار (Windows/Linux/macOS)
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  SharedPreferences.setMockInitialValues({});

  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  // path_provider
  messenger.setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (call) async {
      if (call.method == 'getApplicationDocumentsDirectory') {
        return '/tmp/test_documents';
      }
      if (call.method == 'getTemporaryDirectory') return '/tmp/test_temp';
      return null;
    },
  );

  // flutter_secure_storage
  final Map<String, String> secureStorage = {};
  messenger.setMockMethodCallHandler(
    const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
    (call) async {
      switch (call.method) {
        case 'write':
          secureStorage[call.arguments['key']] = call.arguments['value'];
          return null;
        case 'read':
          return secureStorage[call.arguments['key']];
        case 'delete':
          secureStorage.remove(call.arguments['key']);
          return null;
        case 'readAll':
          return Map<String, String>.from(secureStorage);
        case 'deleteAll':
          secureStorage.clear();
          return null;
        case 'containsKey':
          return secureStorage.containsKey(call.arguments['key']);
        default:
          return null;
      }
    },
  );

  // local_auth
  messenger.setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/local_auth'),
    (call) async {
      if (call.method == 'isDeviceSupported') return true;
      if (call.method == 'canCheckBiometrics') return true;
      if (call.method == 'getAvailableBiometrics') return ['fingerprint'];
      if (call.method == 'authenticate') return true;
      return null;
    },
  );

  // flutter_local_notifications
  messenger.setMockMethodCallHandler(
    const MethodChannel('dexterous.com/flutter/local_notifications'),
    (call) async => null,
  );

  // permission_handler
  messenger.setMockMethodCallHandler(
    const MethodChannel('flutter.baseflow.com/permissions/methods'),
    (call) async {
      if (call.method == 'checkPermissionStatus') return 1; // granted
      if (call.method == 'requestPermissions') return {call.arguments[0]: 1};
      return null;
    },
  );
}
