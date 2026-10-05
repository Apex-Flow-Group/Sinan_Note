import 'package:flutter_test/flutter_test.dart';
import 'package:sinan_note/domain/categories.dart';
import 'package:sinan_note/domain/models/note.dart';

import '../../helpers/test_data_layer.dart';
import '../../test_setup.dart';

void main() {
  late TestDataLayer data;
  final t0 = DateTime.utc(2026);

  setUpAll(initializeTestEnvironment);
  setUp(() async => data = await TestDataLayer.create());
  tearDown(() => data.dispose());

  Note note(String title, List<int> categories, {bool hidden = false}) => Note(
      title: title,
      content: 'c',
      createdAt: t0,
      updatedAt: t0,
      categoryIds: categories,
      isHiddenFromHome: hidden);

  test('defaults are seeded once, in the given language', () async {
    await data.categories.seedDefaults(['عمل', 'شخصي']);
    expect(data.categories.categories.map((c) => c.name), ['عمل', 'شخصي']);

    for (final c in [...data.categories.categories]) {
      await data.categories.delete(c.id);
    }
    await data.categories.seedDefaults(['Work']);
    expect(data.categories.categories, isEmpty,
        reason: 'what the user deleted does not come back');
  });

  test('names are unique regardless of case; the policy explains refusals',
      () async {
    expect(await data.categories.add('Work'), isNull);
    expect(await data.categories.add(' work '), CategoryIssue.duplicate);
    expect(await data.categories.add(''), CategoryIssue.empty);
    expect(await data.categories.add('x' * 21), CategoryIssue.tooLong);
    final id = data.categories.categories.single.id;
    expect(await data.categories.rename(id, 'WORK'), isNull,
        reason: 'renaming to its own name in another case');
  });

  test('deleting a category removes it from its notes, locked ones included',
      () async {
    await data.vault.setUp('Pass123!');
    await data.categories.add('A');
    await data.categories.add('B');
    final [a, b] = data.categories.categories;
    final open = await data.notes.save(note('open', [a.id, b.id]));
    final only = await data.notes.save(note('only', [a.id], hidden: true));
    final locked = await data.notes
        .save(note('locked', [a.id]).copyWith(isLocked: true));
    data.vault.lock();

    await data.categories.delete(a.id);

    expect(data.notes.cached(open.id!)!.categoryIds, [b.id]);
    expect(data.notes.cached(only.id!)!.categoryIds, isEmpty);
    expect(data.notes.cached(only.id!)!.isHiddenFromHome, isFalse,
        reason: 'without a category it shows on home again');
    final row = await data.db
        .query('notes', where: 'id = ?', whereArgs: [locked.id]);
    expect(row.single['categoryIds'], '');
    expect((await data.tombstones.read()).deletesCategory('a'), isTrue);
  });

  test('duplicates left by previous versions are merged into the first',
      () async {
    final first = await data.db
        .insert('categories', {'name': 'Ideas', 'sortOrder': 0});
    final dupe = await data.db
        .insert('categories', {'name': 'ideas', 'sortOrder': 1});
    final n = await data.notes.save(note('n', [dupe]));

    await data.categories.load();

    expect(data.categories.categories.map((c) => c.id), [first]);
    expect(data.notes.cached(n.id!)!.categoryIds, [first]);
  });

  test('ensureNamed creates only what is missing, once per name', () async {
    await data.categories.add('Work');
    final ids = await data.categories.ensureNamed(['work', 'Ideas', 'IDEAS']);
    expect(data.categories.categories.map((c) => c.name), ['Work', 'Ideas']);
    expect(ids['Ideas'], ids['IDEAS']);
  });
}
