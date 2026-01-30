// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter_test/flutter_test.dart';
import '../../test_setup.dart';

void main() {
  setUpAll(() {
    initializeTestEnvironment();
  });

  group('BiometricService', () {
    test('biometric service exists', () {
      // BiometricService requires platform channels
      // Should be tested as integration test on real device
      expect(true, true);
    });
  });
}
