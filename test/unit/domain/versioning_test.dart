import 'package:flutter_test/flutter_test.dart';
import 'package:sinan_note/domain/models/note_version.dart';
import 'package:sinan_note/domain/versioning.dart';

void main() {
  NoteVersion version(String title, String content) => NoteVersion(
      noteId: 1, title: title, content: content, timestamp: DateTime.utc(2026));

  bool record(VersionTrigger trigger, NoteVersion? last, String title,
          String content) =>
      VersionPolicy.shouldRecord(
          trigger: trigger, last: last, title: title, content: content);

  final long = 'word ' * 100; // 500 حرف

  test('the first version is always recorded', () {
    for (final trigger in VersionTrigger.values) {
      expect(record(trigger, null, 't', 'c'), isTrue, reason: trigger.name);
    }
  });

  test('identical to the last version: only a forced version is recorded', () {
    final last = version('t', 'c');
    expect(record(VersionTrigger.manual, last, 't', 'c'), isFalse);
    expect(record(VersionTrigger.sessionEnd, last, 't', 'c'), isFalse);
    expect(record(VersionTrigger.forced, last, 't', 'c'), isTrue);
  });

  test('a manual save records any change', () {
    expect(record(VersionTrigger.manual, version('t', long), 't', '${long}x'),
        isTrue);
  });

  test('a session end needs 20 characters and 5% of change', () {
    final last = version('t', long);
    expect(record(VersionTrigger.sessionEnd, last, 't', '${long}tiny'), isFalse,
        reason: 'under 20 characters');
    expect(
        record(VersionTrigger.sessionEnd, version('t', long * 10), 't',
            '${long * 10}${'x' * 30}'),
        isFalse,
        reason: 'under 5%');
    expect(record(VersionTrigger.sessionEnd, last, 't', '$long${'x' * 40}'),
        isTrue);
    expect(
        record(VersionTrigger.sessionEnd, version('t', 'short'), 'x' * 30,
            'short'),
        isTrue,
        reason: 'a title change counts');
  });

  test('stored action names are the ones previous versions wrote', () {
    expect(VersionTrigger.manual.action, 'manual_save');
    expect(VersionTrigger.sessionEnd.action, 'session_end');
  });
}
