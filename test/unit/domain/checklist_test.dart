import 'package:flutter_test/flutter_test.dart';
import 'package:sinan_note/domain/text/checklist.dart';

void main() {
  test('items without an id get distinct ids, even in the same instant', () {
    final items = [
      for (var i = 0; i < 1000; i++)
        ChecklistItem.fromJson(const {'text': 'same line'}),
    ];
    expect(items.map((e) => e.id).toSet(), hasLength(1000));
  });

  test('an existing id is kept', () {
    expect(ChecklistItem.fromJson(const {'id': 'x', 'text': ''}).id, 'x');
  });
}
