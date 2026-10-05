import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sinan_note/domain/models/note.dart';
import 'package:sinan_note/ui/features/editor/view_models/editor_view_model.dart';

import '../../helpers/test_data_layer.dart';
import '../../test_setup.dart';

/// محرر وهمي: ما "على الشاشة" وهل تغيّر منذ آخر أخذ.
class FakeEditor implements DraftSource {
  FakeEditor(this.current);

  NoteDraft current;
  bool dirty = false;
  int takes = 0;

  void type(String content) {
    current = NoteDraft(
      title: current.title,
      content: content,
      isEmpty: content.trim().isEmpty && current.title.trim().isEmpty,
      colorIndex: current.colorIndex,
    );
    dirty = true;
  }

  void recolor(int index) {
    current = NoteDraft(
        title: current.title,
        content: current.content,
        isEmpty: current.isEmpty,
        colorIndex: index);
    dirty = true;
  }

  @override
  NoteDraft? takeDraft({required bool force}) {
    if (!dirty && !force) return null;
    takes++;
    dirty = false;
    return current;
  }

  @override
  void restoreDraft() => dirty = true;
}

void main() {
  late TestDataLayer data;
  final t0 = DateTime.utc(2026);

  setUpAll(initializeTestEnvironment);
  setUp(() async => data = await TestDataLayer.create());
  tearDown(() => data.dispose());

  Future<Note> stored(String content) => data.notes.save(Note(
      title: 'title', content: content, createdAt: t0, updatedAt: t0));

  (EditorViewModel, FakeEditor) open(Note? note) {
    final vm = EditorViewModel(notes: data.notes, note: note);
    final editor = FakeEditor(note == null
        ? const NoteDraft(title: '', content: '', isEmpty: true)
        : NoteDraft.of(note));
    vm.attach(editor);
    return (vm, editor);
  }

  test('nothing changed: nothing written', () async {
    final note = await stored('body');
    final (vm, _) = open(note);
    final writes = data.notes.localWrites.value;
    expect(await vm.save(), isFalse);
    expect(data.notes.localWrites.value, writes);
  });

  test('a new note is created once and then updated', () async {
    final (vm, editor) = open(null);
    editor.type('first');
    await vm.save();
    final id = vm.noteId!;
    editor.type('second');
    await vm.save();
    expect(vm.noteId, id);
    expect(data.notes.notes.single.content, 'second');
  });

  test('saves requested during a save are not dropped, and coalesce',
      () async {
    final note = await stored('v0');
    final (vm, editor) = open(note);
    editor.type('v1');
    final first = vm.save();
    await Future<void>.delayed(Duration.zero); // الأول بدأ وأخذ v1
    editor.type('v2');
    final second = vm.save();
    editor.type('v3');
    final third = vm.save();
    await Future.wait([first, second, third]);

    expect(data.notes.cached(note.id!)!.content, 'v3');
  });

  test('pinned while open: a later save does not unpin', () async {
    final note = await stored('body');
    final (vm, editor) = open(note);
    await data.notes.togglePinned(note.id!);
    editor.type('edited');
    await vm.save();
    final now = data.notes.cached(note.id!)!;
    expect(now.isPinned, isTrue);
    expect(now.content, 'edited');
  });

  test('a colour changed elsewhere survives; the edited field wins', () async {
    final note = await stored('body');
    final (vm, editor) = open(note);
    await data.notes.updateMeta(note.id!, colorIndex: 5);
    editor.type('edited');
    await vm.save();
    expect(data.notes.cached(note.id!)!.colorIndex, 5);

    editor.recolor(2);
    await vm.save();
    expect(data.notes.cached(note.id!)!.colorIndex, 2);
  });

  test('trash ends the session: leaving afterwards does not restore it',
      () async {
    final note = await stored('body');
    final (vm, editor) = open(note);
    editor.type('last words');
    expect(await vm.trash(), isTrue);

    editor.type('typed after');
    expect(await vm.save(manual: true), isFalse);
    final row = await data.notes.find(note.id!);
    expect(row!.isTrashed, isTrue);
    expect(row.content, 'last words', reason: 'saved before trashing');
  });

  test('trashed elsewhere while open: the editor does not bring it back',
      () async {
    final note = await stored('body');
    final (vm, editor) = open(note);
    await data.notes.trash([note.id!]);
    editor.type('edited');
    expect(await vm.save(), isFalse);
    expect((await data.notes.find(note.id!))!.isTrashed, isTrue);
    expect(vm.isClosed, isTrue);
  });

  test('emptying a note moves it to the trash', () async {
    final note = await stored('body');
    final (vm, editor) = open(note);
    editor.current = const NoteDraft(title: '', content: '', isEmpty: true);
    editor.dirty = true;
    await vm.save();
    expect((await data.notes.find(note.id!))!.isTrashed, isTrue);
  });

  test('a failed save keeps the edit pending and is reported', () async {
    await data.vault.setUp('Pass123!');
    final vm = EditorViewModel(notes: data.notes, locked: true);
    final editor = FakeEditor(
        const NoteDraft(title: 'secret', content: 'x', isEmpty: false));
    vm.attach(editor);
    editor.dirty = true;
    data.vault.lock();

    expect(await vm.save(), isFalse);
    expect(vm.error, isNotNull);
    expect(editor.dirty, isTrue, reason: 'still unsaved, nothing lost');
    expect(await vm.archive(), isFalse, reason: 'nothing archived');
  });

  test('closing right after typing: the edit captured now is written',
      () async {
    final note = await stored('v0');
    final (vm, editor) = open(note);
    editor.type('typed just before closing');
    final saving = vm.save();
    vm.attach(_Gone()); // المحرر أُغلق: لا متحكمات بعد الآن
    await saving;
    expect(data.notes.cached(note.id!)!.content, 'typed just before closing');
  });

  test('flush waits for every pending write', () async {
    final note = await stored('v0');
    final (vm, editor) = open(note);
    editor.type('v1');
    unawaited(vm.save());
    await vm.flush();
    expect(data.notes.cached(note.id!)!.content, 'v1');
  });

  test('the saved flag reports writes once', () async {
    final (vm, editor) = open(null);
    editor.type('x');
    await vm.save();
    expect(vm.takeSavedFlag(), isTrue);
    expect(vm.takeSavedFlag(), isFalse);
  });

}

class _Gone implements DraftSource {
  @override
  NoteDraft? takeDraft({required bool force}) =>
      throw StateError('editor disposed');
  @override
  void restoreDraft() {}
}
