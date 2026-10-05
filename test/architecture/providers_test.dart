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
      final local = RegExp('create: \\([^)]*\\) => $type\\(');
      return !sources.any(local.hasMatch);
    }).toList()
      ..sort();

    expect(missing, isEmpty,
        reason: 'Looked up with context.read/watch but never provided');
  });
}
