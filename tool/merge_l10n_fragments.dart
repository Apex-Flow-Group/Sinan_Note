// Copyright © 2025 Apex Flow Group. All rights reserved.

// يدمج مقاطع الترجمة في ملفات .arb.
//
// كل مقطع في lib/l10n/fragments/*.json بالصيغة:
//   { "key": { "en": "...", "ar": "...",
//              "placeholders": { "count": { "type": "int" } } } }
//
//   dart run tool/merge_l10n_fragments.dart            يدمج ويُبقي المقاطع
//   dart run tool/merge_l10n_fragments.dart --consume  يدمج ثم يحذفها
//
// يفشل إن عرّف مقطعان (أو مقطع و.arb) المفتاح نفسه بنص مختلف.

import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  final dir = Directory('lib/l10n/fragments');
  if (!dir.existsSync()) {
    stdout.writeln('No fragments.');
    return;
  }
  final fragments = dir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.json'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  final en = _Arb('lib/l10n/app_en.arb');
  final ar = _Arb('lib/l10n/app_ar.arb');
  final source = <String, String>{};
  final errors = <String>[];
  var added = 0;

  for (final file in fragments) {
    final name = file.uri.pathSegments.last;
    final entries =
        (jsonDecode(file.readAsStringSync()) as Map).cast<String, Object?>();
    for (final MapEntry(:key, :value) in entries.entries) {
      final entry = (value as Map).cast<String, Object?>();
      final enText = entry['en'] as String?;
      final arText = entry['ar'] as String?;
      if (enText == null || arText == null) {
        errors.add('$name: "$key" needs both "en" and "ar"');
        continue;
      }
      final known = en.values[key];
      if (known != null) {
        if (known != enText || ar.values[key] != arText) {
          errors.add('$name: "$key" already exists '
              '${source[key] ?? 'in app_en.arb'} with different text');
        }
        continue;
      }
      source[key] = 'in $name';
      en.values[key] = enText;
      ar.values[key] = arText;
      final placeholders = entry['placeholders'];
      if (placeholders != null) {
        en.values['@$key'] = {'placeholders': placeholders};
      }
      added++;
    }
  }

  if (errors.isNotEmpty) {
    stderr.writeln(errors.join('\n'));
    exit(1);
  }
  en.save();
  ar.save();
  if (args.contains('--consume')) dir.deleteSync(recursive: true);
  stdout.writeln('Merged $added keys from ${fragments.length} fragments.');
}

class _Arb {
  _Arb(this.path) {
    final raw = File(path).readAsStringSync();
    _crlf = raw.contains('\r\n');
    values = (jsonDecode(raw) as Map).cast<String, Object?>();
  }

  final String path;
  late final Map<String, Object?> values;
  late final bool _crlf;

  void save() {
    var out = '${const JsonEncoder.withIndent('  ').convert(values)}\n';
    if (_crlf) out = out.replaceAll('\n', '\r\n');
    File(path).writeAsStringSync(out);
  }
}
