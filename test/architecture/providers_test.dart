import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// كل نوع تطلبه الواجهة من Provider يجب أن يُنشأ في نقطة التركيب (main.dart)
/// أو في `create:` محلي — وإلا انهارت الشاشة عند أول ضغطة (ProviderNotFound).
void main() {
  test('every type looked up through Provider is provided', () {
    final lookup = RegExp(
        r'(?:context\.(?:read|watch|select)|Provider\.of|Consumer\d?|Selector\d?)<(\w+)');
    final sources = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .map((f) => f.readAsStringSync())
        .toList();
    final main = File('lib/main.dart').readAsStringSync();

    final requested = {
      for (final src in sources)
        for (final m in lookup.allMatches(src)) m.group(1)!,
    };
    final missing = requested.where((type) {
      if (main.contains('$type(')) return false;
      final local = RegExp('create: \\([^)]*\\) =>\\s*$type\\(');
      return !sources.any(local.hasMatch);
    }).toList()
      ..sort();

    expect(missing, isEmpty,
        reason: 'Looked up with context.read/watch but never provided');
  });

  // Provider العادي يرفض في وضع debug ما يُستمع إليه (ChangeNotifier،
  // Listenable، Stream): التطبيق يتوقف عند التشغيل وprofile/release لا
  // يظهر فيهما شيء. هنا يُكتشف قبل الجهاز.
  test('plain Provider never holds something listenable', () {
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList();
    final sources = {
      for (final f in files) f.path.replaceAll(r'\', '/'): f.readAsStringSync()
    };

    final listenable = <String>{};
    final declaration = RegExp(
        r'class (\w+)(?:<[^>]*>)?\s+(?:extends|with|implements)[^{]*?\b(?:ChangeNotifier|Listenable|ValueNotifier|Stream)\b');
    for (final src in sources.values) {
      for (final m in declaration.allMatches(src)) {
        listenable.add(m.group(1)!);
      }
    }

    final plainCreate =
        RegExp(r'(?<!\w)Provider\(\s*create: \([^)]*\) =>\s*(\w+)\(');
    final problems = <String>[
      for (final MapEntry(key: path, value: src) in sources.entries) ...[
        for (final m in plainCreate.allMatches(src))
          if (listenable.contains(m.group(1)))
            '$path: Provider(create: ${m.group(1)}) — use ChangeNotifierProvider',
        // نوع القيمة لا يُعرف من النص، فلا يُتحقق منه: Provider(create:) بدلاً
        if (RegExp(r'(?<!\w)Provider\.value\(').hasMatch(src))
          '$path: Provider.value — its type cannot be checked; '
              'use Provider(create:) or a listenable provider',
      ],
    ];
    expect(problems, isEmpty, reason: problems.join('\n'));
  });
}
