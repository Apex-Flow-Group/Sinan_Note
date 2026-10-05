import 'package:flutter_test/flutter_test.dart';
import 'package:sinan_note/domain/models/note.dart';
import 'package:sinan_note/domain/versioning.dart';
import 'package:sinan_note/ui/features/version_history/view_models/version_history_controller.dart';

import '../../helpers/test_data_layer.dart';
import '../../test_setup.dart';

void main() {
  setUpAll(initializeTestEnvironment);

  test('filteredNotes sorts and filters without touching the loaded list',
      () async {
    final data = await TestDataLayer.create();
    final t0 = DateTime.utc(2026);
    for (final (i, title) in ['beta', 'alpha', 'gamma'].indexed) {
      final note = await data.notes.save(Note(
          title: title,
          content: 'body',
          createdAt: t0,
          updatedAt: t0.add(Duration(days: i))));
      await data.notes.recordVersion(note.id!, VersionTrigger.manual);
    }
    final vm = VersionHistoryController(notes: data.notes);
    await vm.loadNotes();

    expect(vm.filteredNotes.map((n) => n.title), ['gamma', 'alpha', 'beta']);
    vm.sortBy = 'title';
    expect(vm.filteredNotes.map((n) => n.title), ['alpha', 'beta', 'gamma']);
    vm.searchQuery = 'gam';
    expect(vm.filteredNotes.map((n) => n.title), ['gamma']);
    expect(vm.notesWithHistory, hasLength(3));

    vm.dispose();
    await data.dispose();
  });
}
