import 'package:isar/isar.dart';

import 'lib/models/note.dart';
import 'lib/models/note_version.dart';

void main() async {
  final isar = await Isar.open(
    [NoteSchema, NoteVersionSchema],
    directory: '/home/dream/Documents',
    name: 'sinan_notes',
  );

  final notes = await isar.notes.where().findAll();

  for (var note in notes) {
    await isar.noteVersions.filter().noteIdEqualTo(note.id!).findAll();
  }

  await isar.close();
}
