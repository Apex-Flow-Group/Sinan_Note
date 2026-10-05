import 'package:flutter_test/flutter_test.dart';
import 'package:sinan_note/domain/vault_policy.dart';

void main() {
  // الأحكام نفسها التي أعطتها القاعدة السابقة (VaultService) لهذه العيّنات.
  const verdicts = {
    'Pass123!': true,
    'pass123!': true,
    'Password': false,
    '12345678!': false,
    'Ab1!': false,
    'Abcdef1~': true,
    'كلمةسر1!': false,
    'Abc 123!': false,
    r'Abc123\x': true,
    'Abc123|x': true,
    'Abc123"x': true,
    "Abc123'x": true,
    'Abc123[x': true,
    'Abc123]x': true,
    'Abc123-x': true,
    'Abc123_x': true,
    'Abc123`x': true,
    '': false,
  };

  test('same verdicts as the previous rule', () {
    verdicts.forEach((password, strong) {
      expect(VaultPolicy.isStrongPassword(password), strong, reason: password);
    });
  });

  test('reports the first thing missing', () {
    expect(VaultPolicy.check('Ab1!'), PasswordIssue.tooShort);
    expect(VaultPolicy.check('Abcdefgh!'), PasswordIssue.noDigit);
    expect(VaultPolicy.check('Abcdefg1'), PasswordIssue.noSymbol);
    expect(VaultPolicy.check('12345678!'), PasswordIssue.noLetter);
    expect(VaultPolicy.check('Abc 123!'), PasswordIssue.noLetter);
    expect(VaultPolicy.check('Pass123!'), isNull);
  });
}
