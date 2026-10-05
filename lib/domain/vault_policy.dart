// Copyright © 2025 Apex Flow Group. All rights reserved.

/// ما ينقص كلمة سر الخزنة لتُقبل.
enum PasswordIssue { tooShort, noDigit, noSymbol, noLetter }

/// قواعد كلمة سر الخزنة: 8 أحرف فأكثر، فيها حرف لاتيني ورقم ورمز، ولا شيء
/// خارج الحروف اللاتينية والأرقام والرموز المسموحة.
abstract final class VaultPolicy {
  static const _symbols = r'''!@#$%^&*()\-_=+\[\]{};:'",./<>?\\|`~''';
  static final _digit = RegExp(r'\d');
  static final _symbol = RegExp('[$_symbols]');
  static final _letter = RegExp('[A-Za-z]');
  static final _allowed = RegExp('^[A-Za-z\\d$_symbols]*\$');

  /// أول ما ينقص، أو null إن كانت مقبولة.
  static PasswordIssue? check(String password) {
    if (password.length < 8) return PasswordIssue.tooShort;
    if (!_digit.hasMatch(password)) return PasswordIssue.noDigit;
    if (!_symbol.hasMatch(password)) return PasswordIssue.noSymbol;
    if (!_letter.hasMatch(password) || !_allowed.hasMatch(password)) {
      return PasswordIssue.noLetter;
    }
    return null;
  }

  static bool isStrongPassword(String password) => check(password) == null;
}
