import 'package:refactoring_tool/engine/dependency_sorter.dart';
import 'package:refactoring_tool/models/core_file_entry.dart';
import 'package:test/test.dart';

void main() {
  late DependencySorter sorter;

  setUp(() {
    sorter = DependencySorter();
  });

  group('DependencySorter', () {
    test('returns empty result for empty input', () {
      final result = sorter.sort([], {});

      expect(result.sortedEntries, isEmpty);
      expect(result.circularGroups, isEmpty);
    });

    test('sorts by dependency depth ascending - zero imports first', () {
      final entries = [
        const CoreFileEntry(
          filePath: 'lib/services/auth_service.dart',
          directImportCount: 3,
          dependencyDepth: 0,
        ),
        const CoreFileEntry(
          filePath: 'lib/models/note.dart',
          directImportCount: 0,
          dependencyDepth: 0,
        ),
        const CoreFileEntry(
          filePath: 'lib/controllers/notes_controller.dart',
          directImportCount: 2,
          dependencyDepth: 0,
        ),
      ];

      final importMap = {
        'lib/models/note.dart': <String>[],
        'lib/services/auth_service.dart': [
          'lib/models/note.dart',
          'lib/controllers/notes_controller.dart',
          'lib/models/user.dart', // not a Core file in this list
        ],
        'lib/controllers/notes_controller.dart': [
          'lib/models/note.dart',
          'lib/services/auth_service.dart',
        ],
      };

      final result = sorter.sort(entries, importMap);

      // note.dart has 0 Core imports, controller has 2, service has 2
      // (service imports note + controller which are both Core)
      expect(result.sortedEntries[0].filePath, 'lib/models/note.dart');
      expect(result.sortedEntries[0].dependencyDepth, 0);

      // Both controller and service have depth 2
      expect(result.sortedEntries[1].dependencyDepth, 2);
      expect(result.sortedEntries[2].dependencyDepth, 2);
    });

    test('detects circular dependencies between two files', () {
      final entries = [
        const CoreFileEntry(
          filePath: 'lib/services/a.dart',
          directImportCount: 1,
          dependencyDepth: 0,
        ),
        const CoreFileEntry(
          filePath: 'lib/services/b.dart',
          directImportCount: 1,
          dependencyDepth: 0,
        ),
        const CoreFileEntry(
          filePath: 'lib/models/c.dart',
          directImportCount: 0,
          dependencyDepth: 0,
        ),
      ];

      final importMap = {
        'lib/services/a.dart': ['lib/services/b.dart'],
        'lib/services/b.dart': ['lib/services/a.dart'],
        'lib/models/c.dart': <String>[],
      };

      final result = sorter.sort(entries, importMap);

      // Circular dependency detected
      expect(result.circularGroups, hasLength(1));
      expect(
        result.circularGroups[0],
        containsAll(['lib/services/a.dart', 'lib/services/b.dart']),
      );

      // Both a.dart and b.dart should have circularDeps populated
      final entryA = result.sortedEntries
          .firstWhere((e) => e.filePath == 'lib/services/a.dart');
      final entryB = result.sortedEntries
          .firstWhere((e) => e.filePath == 'lib/services/b.dart');

      expect(entryA.circularDeps, contains('lib/services/b.dart'));
      expect(entryB.circularDeps, contains('lib/services/a.dart'));
    });

    test('groups circular dependency files together in output', () {
      final entries = [
        const CoreFileEntry(
          filePath: 'lib/services/a.dart',
          directImportCount: 1,
          dependencyDepth: 0,
        ),
        const CoreFileEntry(
          filePath: 'lib/services/b.dart',
          directImportCount: 1,
          dependencyDepth: 0,
        ),
        const CoreFileEntry(
          filePath: 'lib/models/c.dart',
          directImportCount: 0,
          dependencyDepth: 0,
        ),
      ];

      final importMap = {
        'lib/services/a.dart': ['lib/services/b.dart'],
        'lib/services/b.dart': ['lib/services/a.dart'],
        'lib/models/c.dart': <String>[],
      };

      final result = sorter.sort(entries, importMap);

      // Find indices of a and b in the sorted list
      final indexA = result.sortedEntries
          .indexWhere((e) => e.filePath == 'lib/services/a.dart');
      final indexB = result.sortedEntries
          .indexWhere((e) => e.filePath == 'lib/services/b.dart');

      // They should be adjacent (grouped together)
      expect((indexA - indexB).abs(), 1);
    });

    test('handles three-way circular dependency', () {
      final entries = [
        const CoreFileEntry(
          filePath: 'lib/a.dart',
          directImportCount: 1,
          dependencyDepth: 0,
        ),
        const CoreFileEntry(
          filePath: 'lib/b.dart',
          directImportCount: 1,
          dependencyDepth: 0,
        ),
        const CoreFileEntry(
          filePath: 'lib/c.dart',
          directImportCount: 1,
          dependencyDepth: 0,
        ),
      ];

      // A imports B, B imports C, C imports A (and mutual pairs exist)
      final importMap = {
        'lib/a.dart': ['lib/b.dart'],
        'lib/b.dart': ['lib/a.dart', 'lib/c.dart'],
        'lib/c.dart': ['lib/b.dart'],
      };

      final result = sorter.sort(entries, importMap);

      // A↔B and B↔C are circular pairs, merged into one group
      expect(result.circularGroups, hasLength(1));
      expect(
        result.circularGroups[0],
        containsAll(['lib/a.dart', 'lib/b.dart', 'lib/c.dart']),
      );
    });

    test('only counts imports to other Core files for depth', () {
      final entries = [
        const CoreFileEntry(
          filePath: 'lib/models/note.dart',
          directImportCount: 0,
          dependencyDepth: 0,
        ),
        const CoreFileEntry(
          filePath: 'lib/services/note_service.dart',
          directImportCount: 3,
          dependencyDepth: 0,
        ),
      ];

      // note_service imports note.dart (Core) + 2 external packages
      final importMap = {
        'lib/models/note.dart': <String>[],
        'lib/services/note_service.dart': [
          'lib/models/note.dart',
          'package:http/http.dart', // not Core
          'lib/utils/helpers.dart', // not Core (not in entries)
        ],
      };

      final result = sorter.sort(entries, importMap);

      // note_service should have depth 1 (only note.dart is Core)
      final noteService = result.sortedEntries
          .firstWhere((e) => e.filePath == 'lib/services/note_service.dart');
      expect(noteService.dependencyDepth, 1);
    });

    test('files with no imports in map get depth 0', () {
      final entries = [
        const CoreFileEntry(
          filePath: 'lib/models/note.dart',
          directImportCount: 0,
          dependencyDepth: 0,
        ),
      ];

      // File not in importMap at all
      final importMap = <String, List<String>>{};

      final result = sorter.sort(entries, importMap);

      expect(result.sortedEntries[0].dependencyDepth, 0);
      expect(result.sortedEntries[0].circularDeps, isEmpty);
    });
  });
}
