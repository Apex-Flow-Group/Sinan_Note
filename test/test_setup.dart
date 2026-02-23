// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Initialize all test dependencies
void initializeTestEnvironment() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences mock
  SharedPreferences.setMockInitialValues({});

  // Setup method channel mocks for platform-specific features
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (MethodCall methodCall) async {
      if (methodCall.method == 'getApplicationDocumentsDirectory') {
        return '/tmp/test_documents';
      }
      if (methodCall.method == 'getTemporaryDirectory') {
        return '/tmp/test_temp';
      }
      return null;
    },
  );
}
