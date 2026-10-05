// قواعد الطبقات والثيم واللغة، مفروضة على الكود: أي مخالفة تُفشل الاختبار.
// (بدأت كسقّاطة بخط أساس لمخالفات ما قبل إعادة البناء، ووصلت إلى صفر.)

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('architecture rules', () {
    final violations = _scan().entries.map((e) => '${e.key}: ${e.value}');
    expect(violations, isEmpty, reason: violations.join('\n'));
  });
}

// ── التصنيف ────────────────────────────────────────────────────────────────

enum _Layer { ui, viewModel, dataService, repository, domain, theme, other }

/// الطبقة حسب المسار.
_Layer _layerOf(String path) {
  bool under(String dir) => path.startsWith('lib/$dir/');
  if (under('ui/core/theme')) return _Layer.theme;
  if (path.contains('/view_models/')) return _Layer.viewModel;
  if (under('ui')) return _Layer.ui;
  if (under('data/repositories')) return _Layer.repository;
  if (under('data')) return _Layer.dataService;
  if (under('domain')) return _Layer.domain;
  return _Layer.other;
}

bool _isDataOrDomain(_Layer l) =>
    l == _Layer.dataService || l == _Layer.repository || l == _Layer.domain;

bool _isUi(_Layer l) => l == _Layer.ui;

// ── القواعد ────────────────────────────────────────────────────────────────

class _Rule {
  const _Rule(this.id, this.appliesTo, this.pattern);
  final String id;
  final bool Function(String path, _Layer layer) appliesTo;
  final RegExp pattern;
}

/// نص فيه حرف عربي. النص الخام (r'…') مستثنى: هو أنماط RegExp (نطاقات
/// أحرف)، لا نصوص معروضة.
final _arabicLiteral =
    RegExp(r'''(?<![rR])(['"])(?:(?!\1).)*[؀-ۿ](?:(?!\1).)*\1''');

/// نص إنجليزي معروض: `Text('…')` أو وسيط نصي للمستخدم (title, message,
/// tooltip…) فيه حرفان لاتينيان خارج الـ interpolation.
final _englishUiLiteral = RegExp(
    r'''(\bText\(\s*|\b(?:title|subtitle|message|label|hintText|labelText|tooltip|helperText|errorText|actionLabel|semanticLabel|semanticsLabel)\s*:\s*)(?:const\s+)?(['"])(?:\$\{[^}]*\}|\$\w+(?!\w)|[^'"$])*?[A-Za-z]{2}''');

final _rules = <_Rule>[
  // A1: الواجهة لا تصل لخدمات البيانات مباشرة
  _Rule('A1', (p, l) => _isUi(l),
      RegExp(r'''^import\s+'package:sinan_note/data/services/''')),
  // A2: البيانات والمجال بلا Flutter UI
  _Rule(
      'A2',
      (p, l) => _isDataOrDomain(l),
      RegExp(
          r'''^import\s+'package:flutter/(material|widgets|cupertino)\.dart'|\bBuildContext\b''')),
  // A3: المجال لا يعتمد على البيانات
  _Rule('A3', (p, l) => l == _Layer.domain,
      RegExp(r'''^import\s+'package:sinan_note/data/''')),
  // A4: الـ Views لا تستدعي Repository
  _Rule('A4', (p, l) => _isUi(l),
      RegExp(r'''^import\s+'package:sinan_note/data/repositories/''')),
  // A5: جدول notes يكتبه NotesRepository وحده (ومخطط القاعدة وترحيلاته)
  _Rule(
      'A5',
      (p, l) =>
          p != 'lib/data/repositories/notes_repository.dart' &&
          !p.startsWith('lib/data/services/database/'),
      RegExp(
          r'''\.(insert|update|delete)\(\s*'notes'|(INSERT INTO|UPDATE|DELETE FROM)\s+notes\b''')),
  // A7: البيانات والمجال لا تعرف الواجهة (ولا main.dart)
  _Rule('A7', (p, l) => _isDataOrDomain(l),
      RegExp(r'''\bimport\s+'package:sinan_note/(main\.dart'|ui/)''')),
  // A6: لا حالة عامة: لا notifiers على مستوى الملف، ولا singletons، ولا
  // حقول static قابلة للتغيير. الاستثناء الوحيد AppStrings: نقطة إعداد
  // واحدة يعيّنها main للنصوص خارج شجرة الويدجت.
  _Rule(
      'A6',
      (p, l) => p != 'lib/data/services/app_strings.dart',
      RegExp(
          // static [final|late final] Type [_]instance — كان النمط يفوّت final
          r'''^final\s+(ValueNotifier|ChangeNotifier|StreamController)\b|^\s*static\s+(?:late\s+)?(?:final\s+)?\w+\??\s+_?instance\b|'''
          // static Type name = / ; (ليس const ولا final ولا getter)
          r'''^\s*static\s+(?!const\b|final\b|get\b)(?:late\s+)?[\w<>?,() ]+?\s+_?[a-z]\w*\s*(?:=(?!>)|;)''')),
  // T1: الألوان من الثيم فقط
  _Rule('T1', (p, l) => l != _Layer.theme,
      RegExp(r'''\bColors\.(?!transparent\b)[a-z]|\bColor\(0x''')),
  // T3: لا ThemeData.primaryColor (قديم: في الداكن هو لون السطح لا اللون
  // الأساسي) — colorScheme.primary
  _Rule('T3', (p, l) => l != _Layer.theme, RegExp(r'''\.primaryColor\b''')),
  // T2: أحجام الخط من TextTheme
  _Rule('T2', (p, l) => _isUi(l), RegExp(r'''\bfontSize:\s*\d''')),
  // L1: لا نصوص للمستخدم ولا تفرّع لغة في الواجهة
  _Rule(
      'L1',
      (p, l) => _isUi(l) || l == _Layer.viewModel || l == _Layer.other,
      RegExp(
          // (?:abic) لا تلتقط: مجموعة ملتقطة هنا كانت تُزيح ترقيم \1 في نمط
          // النص العربي فلا يُلتقط إلا نص يبدأ بحرف عربي
          r'''\bisAr(?:abic)?\b|languageCode\s*==|'''
          '${_arabicLiteral.pattern}|${_englishUiLiteral.pattern}')),
  // L2: البيانات لا تُنتج نصوصاً للمستخدم. domain/text يعالج اللغة نفسها
  // (حروف عربية في قواعد التطبيع)، وليس نصاً معروضاً.
  _Rule('L2', (p, l) => _isDataOrDomain(l) && !p.startsWith('lib/domain/text/'),
      _arabicLiteral),
  // D1: لا يُخزَّن اتجاه النص في المستندات
  _Rule(
      'D1',
      (p, l) => true,
      RegExp(
          r'''\bAttribute\.rtl\b|\bDirectionAttribute\b|\bfixDeltaDirections\b|\bbuildDeltaWithDirections\b''')),
];

// ── الفحص ──────────────────────────────────────────────────────────────────

Map<String, int> _scan() {
  final counts = <String, int>{};
  final files = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .map((f) => f.path.replaceAll(r'\', '/'))
      .where((p) => !p.startsWith('lib/generated/'))
      .toList()
    ..sort();

  for (final path in files) {
    final layer = _layerOf(path);
    final lines = File(path).readAsLinesSync();
    for (final rule in _rules) {
      if (!rule.appliesTo(path, layer)) continue;
      var n = 0;
      for (final raw in lines) {
        final line = raw.startsWith('﻿') ? raw.substring(1) : raw;
        final trimmed = line.trimLeft();
        if (trimmed.startsWith('//')) continue;
        final code = _stripTrailingComment(line);
        n += rule.pattern.allMatches(code).length;
      }
      if (n > 0) counts['${rule.id}|$path'] = n;
    }
  }
  return Map.fromEntries(
      counts.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
}

/// يحذف تعليق آخر السطر إن لم يكن داخل نص.
String _stripTrailingComment(String line) {
  String? quote;
  for (var i = 0; i < line.length - 1; i++) {
    final c = line[i];
    if (quote != null) {
      if (c == r'\') {
        i++;
      } else if (c == quote) {
        quote = null;
      }
    } else if (c == "'" || c == '"') {
      quote = c;
    } else if (c == '/' && line[i + 1] == '/') {
      return line.substring(0, i);
    }
  }
  return line;
}
