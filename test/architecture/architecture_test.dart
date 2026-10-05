// قواعد docs/code-review-2026-10/architecture.md، مفروضة على الكود.
//
// كل قاعدة تعدّ مخالفاتها لكل ملف. baseline.json يحفظ مخالفات ما قبل إعادة
// البناء كسقّاطة (ratchet):
//   - مخالفة جديدة، أو عدد أكبر في ملف ← يفشل.
//   - عدد أقل من خط الأساس ← يفشل حتى يُحدَّث الملف، فلا يعود ما أُصلح.
// تحديث خط الأساس بعد إصلاح حقيقي فقط:
//   flutter test test/architecture --dart-define=UPDATE_ARCH_BASELINE=true

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _update = bool.fromEnvironment('UPDATE_ARCH_BASELINE');
final _baselineFile = File('test/architecture/baseline.json');

void main() {
  test('architecture rules (see docs/code-review-2026-10/architecture.md)', () {
    final violations = _scan();

    if (_update) {
      _baselineFile.writeAsStringSync(
          '${const JsonEncoder.withIndent('  ').convert(violations)}\n');
      return;
    }

    final baseline = _baselineFile.existsSync()
        ? (jsonDecode(_baselineFile.readAsStringSync()) as Map)
            .map((k, v) => MapEntry(k as String, v as int))
        : <String, int>{};

    final problems = <String>[];
    for (final MapEntry(:key, :value) in violations.entries) {
      final allowed = baseline[key] ?? 0;
      if (value > allowed) {
        problems.add('NEW   $key: $value (baseline $allowed)');
      }
    }
    for (final MapEntry(:key, :value) in baseline.entries) {
      final now = violations[key] ?? 0;
      if (now < value) {
        problems.add('FIXED $key: $now (baseline $value) — update baseline');
      }
    }

    expect(problems, isEmpty, reason: problems.join('\n'));
  });
}

// ── التصنيف ────────────────────────────────────────────────────────────────

enum _Layer { ui, viewModel, dataService, repository, domain, theme, other }

/// الطبقة حسب المسار؛ يشمل المجلدات القديمة حتى تُنقل.
_Layer _layerOf(String path) {
  bool under(String dir) => path.startsWith('lib/$dir/');
  if (under('ui/core/theme') ||
      under('core/theme') ||
      path == 'lib/core/utils/adaptive_color.dart') {
    return _Layer.theme;
  }
  if (path.contains('/view_models/') || under('controllers')) {
    return _Layer.viewModel;
  }
  if (under('ui') || under('screens') || under('widgets')) return _Layer.ui;
  if (under('data/repositories')) return _Layer.repository;
  if (under('data') || under('services')) return _Layer.dataService;
  if (under('domain') || under('models')) return _Layer.domain;
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

final _arabicLiteral = RegExp(r'''(['"])(?:(?!\1).)*[؀-ۿ](?:(?!\1).)*\1''');

final _rules = <_Rule>[
  // A1: الواجهة لا تصل لخدمات البيانات مباشرة
  _Rule('A1', (p, l) => _isUi(l),
      RegExp(r'''^import\s+'package:sinan_note/(services|data/services)/''')),
  // A2: البيانات والمجال بلا Flutter UI
  _Rule(
      'A2',
      (p, l) => _isDataOrDomain(l),
      RegExp(
          r'''^import\s+'package:flutter/(material|widgets|cupertino)\.dart'|\bBuildContext\b''')),
  // A3: المجال لا يعتمد على البيانات
  _Rule('A3', (p, l) => l == _Layer.domain,
      RegExp(r'''^import\s+'package:sinan_note/(services|data)/''')),
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
  // A6: لا حالة عامة على مستوى الملف ولا singletons بحالة
  _Rule(
      'A6',
      (p, l) => true,
      RegExp(
          r'''^final\s+(ValueNotifier|ChangeNotifier|StreamController)\b|^\s*static\s+\w+\??\s+_instance\b''')),
  // T1: الألوان من الثيم فقط
  _Rule('T1', (p, l) => l != _Layer.theme,
      RegExp(r'''\bColors\.[a-z]|\bColor\(0x''')),
  // T2: أحجام الخط من TextTheme
  _Rule('T2', (p, l) => _isUi(l), RegExp(r'''\bfontSize:\s*\d''')),
  // L1: لا نصوص للمستخدم ولا تفرّع لغة في الواجهة
  _Rule(
      'L1',
      (p, l) => _isUi(l) || l == _Layer.viewModel || l == _Layer.other,
      RegExp(
          r'''\bisAr(abic)?\b|languageCode\s*==|''' + _arabicLiteral.pattern)),
  // L2: البيانات لا تُنتج نصوصاً للمستخدم. domain/text يعالج اللغة نفسها
  // (حروف عربية في قواعد التطبيع)، وليس نصاً معروضاً.
  _Rule('L2',
      (p, l) => _isDataOrDomain(l) && !p.startsWith('lib/domain/text/'),
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
