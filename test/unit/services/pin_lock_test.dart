import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sinan_note/data/services/security/unified_lock_service.dart';

import '../../test_setup.dart';

void main() {
  setUpAll(initializeTestEnvironment);
  setUp(() => const FlutterSecureStorage().deleteAll());

  test('a PIN verifies; a wrong one does not', () async {
    final lock = UnifiedLockService();
    await lock.setPin('2468');
    expect(await lock.verifyPin('2468'), isTrue);
    expect(await lock.verifyPin('1357'), isFalse);
  });

  test('every PIN gets its own random salt', () async {
    const storage = FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    );
    final salts = <String?>{};
    for (var i = 0; i < 5; i++) {
      await UnifiedLockService().setPin('1111');
      salts.add(await storage.read(key: 'unified_lock_pin_salt'));
    }
    expect(salts, hasLength(5));
  });
}
