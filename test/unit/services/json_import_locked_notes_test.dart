import 'package:flutter_test/flutter_test.dart';
import 'package:sinan_note/models/note.dart';
import 'package:sinan_note/screens/shared/settings/json_import_handler.dart';
import 'package:sinan_note/services/security/vault_service.dart';

import '../../test_setup.dart';

Note _locked(String title, String content) => Note(
      title: title,
      content: content,
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
      isLocked: true,
    );

void main() {
  setUpAll(initializeTestEnvironment);

  // الترتيب مقصود: التخزين الآمن الوهمي مشترك بين الاختبارات
  test('without a vault, a plaintext locked note is imported unlocked',
      () async {
    final result =
        await JsonImportHandler.secureLockedNote(_locked('t', 'secret'));
    expect(result.isLocked, isFalse);
    expect(result.content, 'secret');
  });

  test('with a vault, a plaintext locked note is stored encrypted', () async {
    await VaultService.setupVault('TestPass123!');

    final result =
        await JsonImportHandler.secureLockedNote(_locked('title', 'secret'));

    expect(result.isLocked, isTrue);
    expect(VaultService.isEncrypted(result.content), isTrue);
    expect(VaultService.isEncrypted(result.title), isTrue);
    expect(await VaultService.decryptWithMasterKey(result.content), 'secret');
  });

  test('an already encrypted locked note is kept as is, never decrypted',
      () async {
    final cipher = await VaultService.encryptWithMasterKey('secret');
    final note = _locked('t', cipher);

    final result = await JsonImportHandler.secureLockedNote(note);

    expect(result.content, cipher);
    expect(result.isLocked, isTrue);
  });

  test('unlocked notes are untouched', () async {
    final note = _locked('t', 'plain')..isLocked = false;
    expect((await JsonImportHandler.secureLockedNote(note)).content, 'plain');
  });
}
