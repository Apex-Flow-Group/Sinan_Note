// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/services/security/vault_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VaultService Tests', () {
    setUp(() async {
      // Clear vault before each test
      await VaultService.clearVault();
    });

    test('setupVault should generate recovery code', () async {
      const password = 'test123456';
      final recoveryCode = await VaultService.setupVault(password);

      expect(recoveryCode, isNotEmpty);
      expect(recoveryCode, startsWith('SN-'));
      expect(recoveryCode.split('-').length, equals(4));
    });

    test('isVaultSetup should return true after setup', () async {
      expect(await VaultService.isVaultSetup(), isFalse);

      await VaultService.setupVault('test123456');

      expect(await VaultService.isVaultSetup(), isTrue);
    });

    test('unlockWithPassword should work with correct password', () async {
      const password = 'test123456';
      await VaultService.setupVault(password);

      final success = await VaultService.unlockWithPassword(password);

      expect(success, isTrue);
    });

    test('unlockWithPassword should fail with wrong password', () async {
      await VaultService.setupVault('test123456');

      final success = await VaultService.unlockWithPassword('wrongpassword');

      expect(success, isFalse);
    });

    test('recoverWithCode should work with correct recovery code', () async {
      const password = 'test123456';
      final recoveryCode = await VaultService.setupVault(password);

      final success = await VaultService.recoverWithCode(recoveryCode);

      expect(success, isTrue);
    });

    test('recoverWithCode should fail with wrong recovery code', () async {
      await VaultService.setupVault('test123456');

      final success = await VaultService.recoverWithCode('SN-XXXX-YYYY-ZZZZ');

      expect(success, isFalse);
    });

    test('changePassword should work after recovery', () async {
      const oldPassword = 'test123456';
      final recoveryCode = await VaultService.setupVault(oldPassword);

      // Recover with code
      await VaultService.recoverWithCode(recoveryCode);

      // Change password (empty old password after recovery)
      const newPassword = 'newpassword123';
      final success = await VaultService.changePassword('', newPassword);

      expect(success, isTrue);

      // Verify new password works
      final unlocked = await VaultService.unlockWithPassword(newPassword);
      expect(unlocked, isTrue);
    });

    test('biometric settings should persist', () async {
      await VaultService.setupVault('test123456');

      expect(await VaultService.isBiometricEnabled(), isFalse);

      await VaultService.setBiometricEnabled(true);
      expect(await VaultService.isBiometricEnabled(), isTrue);

      await VaultService.setBiometricEnabled(false);
      expect(await VaultService.isBiometricEnabled(), isFalse);
    });

    test('recovery code format should be valid', () async {
      final recoveryCode = await VaultService.setupVault('test123456');

      // Format: SN-XXXX-XXXX-XXXX
      final parts = recoveryCode.split('-');
      expect(parts.length, equals(4));
      expect(parts[0], equals('SN'));
      expect(parts[1].length, equals(4));
      expect(parts[2].length, equals(4));
      expect(parts[3].length, equals(4));

      // Should only contain alphanumeric (no confusing chars)
      final validChars = RegExp(r'^[A-Z0-9]+$');
      expect(validChars.hasMatch(parts[1]), isTrue);
      expect(validChars.hasMatch(parts[2]), isTrue);
      expect(validChars.hasMatch(parts[3]), isTrue);
    });
  });
}
