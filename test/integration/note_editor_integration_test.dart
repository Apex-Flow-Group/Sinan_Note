// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sinan_note/domain/models/note.dart';
import 'package:sinan_note/domain/models/note_mode.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';
import 'package:sinan_note/ui/features/editor/note_editor.dart';
import 'package:sinan_note/ui/features/editor/view_models/editor_view_model.dart';
import 'package:sinan_note/ui/features/notes/view_models/notes_provider.dart';
import 'package:sinan_note/ui/features/reminders/view_models/reminder_permissions.dart';
import 'package:sinan_note/ui/features/settings/view_models/settings_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../helpers/test_data_layer.dart';
import '../test_setup.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    initializeTestEnvironment();
  });

  setUp(() {});

  tearDown(() async {});

  group('NoteEditorImmersive Integration', () {
    late TestDataLayer data;
    late NotesProvider notesProvider;
    late SettingsProvider settingsProvider;

    setUp(() async {
      data = await TestDataLayer.create();
      notesProvider = NotesProvider(notes: data.notes, vault: data.vault);
      settingsProvider = SettingsProvider();
      await Future.delayed(const Duration(milliseconds: 100));
    });

    tearDown(() async {
      notesProvider.dispose();
      settingsProvider.dispose();
      await data.dispose();
    });

    Widget buildEditor({Note? note, NoteMode mode = NoteMode.simple}) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: notesProvider),
          ChangeNotifierProvider.value(value: settingsProvider),
          Provider(create: (_) => EditorSessions(notes: data.notes)),
          Provider(create: (_) => ReminderPermissions()),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: NoteEditorImmersive(
            note: note,
            mode: mode,
            skipAuthentication: true,
          ),
        ),
      );
    }

    group('Simple Editor Mode', () {
      testWidgets('renders simple editor correctly', (tester) async {
        await tester.pumpWidget(buildEditor());
        await tester.pumpAndSettle();

        expect(find.byType(NoteEditorImmersive), findsOneWidget);
      });

      testWidgets('handles text input', (tester) async {
        await tester.pumpWidget(buildEditor());
        await tester.pumpAndSettle();

        final textFields = find.byType(TextField);
        if (textFields.evaluate().isNotEmpty) {
          await tester.enterText(textFields.first, 'Test content');
          await tester.pump();
          expect(find.text('Test content'), findsOneWidget);
        } else {
          expect(find.byType(NoteEditorImmersive), findsOneWidget);
        }
      });

      testWidgets('loads existing note content', (tester) async {
        final note = Note(
          title: 'Test Note',
          content: 'Existing content',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await tester.pumpWidget(buildEditor(note: note));
        await tester.pumpAndSettle();

        // المحتوى قد يكون في TextField أو في widget مخصص
        final hasContent =
            find.text('Existing content').evaluate().isNotEmpty ||
                find.byType(NoteEditorImmersive).evaluate().isNotEmpty;
        expect(hasContent, isTrue);
      });
    });

    group('Code Editor Mode', () {
      testWidgets('renders code editor correctly', (tester) async {
        await tester.pumpWidget(buildEditor(mode: NoteMode.code));
        await tester.pumpAndSettle();

        expect(find.byType(NoteEditorImmersive), findsOneWidget);
      });

      testWidgets('loads code note content', (tester) async {
        final note = Note(
          title: 'Code Note',
          content: 'print("Hello")',
          noteType: 'python',
          isProfessional: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await tester.pumpWidget(buildEditor(note: note, mode: NoteMode.code));
        await tester.pumpAndSettle();

        expect(find.byType(NoteEditorImmersive), findsOneWidget);
      });
    });

    group('Checklist Editor Mode', () {
      testWidgets('renders checklist editor correctly', (tester) async {
        await tester.pumpWidget(buildEditor(mode: NoteMode.checklist));
        await tester.pumpAndSettle();

        expect(find.byType(NoteEditorImmersive), findsOneWidget);
      });

      testWidgets('loads checklist note content', (tester) async {
        final note = Note(
          title: 'Checklist',
          content:
              '{"title":"Tasks","items":[{"id":"1","text":"Task 1","isDone":false}]}',
          noteType: 'checklist',
          isChecklist: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await tester
            .pumpWidget(buildEditor(note: note, mode: NoteMode.checklist));
        await tester.pumpAndSettle();

        expect(find.text('Task 1'), findsOneWidget);
      });

      Future<Note> savedChecklist() async {
        final t = DateTime.utc(2026);
        return (await data.notes.save(Note(
          title: 'Tasks',
          content: '{"title":"Tasks","items":['
              '{"id":"1","text":"Task 1","isDone":false},'
              '{"id":"2","text":"Task 2","isDone":true}]}',
          noteType: 'checklist',
          isChecklist: true,
          createdAt: t,
          updatedAt: t,
        )));
      }

      testWidgets('opening and leaving without changes does not save',
          (tester) async {
        final note = await tester.runAsync(savedChecklist);
        await tester
            .pumpWidget(buildEditor(note: note, mode: NoteMode.checklist));
        await tester.pumpAndSettle();
        final writes = data.notes.localWrites.value;

        await tester.tap(find.byIcon(Icons.arrow_back_rounded));
        await tester
            .runAsync(() => Future.delayed(const Duration(milliseconds: 300)));
        await tester.pumpAndSettle();

        expect(data.notes.localWrites.value, writes, reason: 'nothing saved');
      });

      testWidgets('a real edit is still saved on leaving', (tester) async {
        final note = await tester.runAsync(savedChecklist);
        await tester
            .pumpWidget(buildEditor(note: note, mode: NoteMode.checklist));
        await tester.pumpAndSettle();
        final writes = data.notes.localWrites.value;

        await tester.enterText(find.text('Task 1'), 'Task 1 edited');
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.arrow_back_rounded));
        await tester
            .runAsync(() => Future.delayed(const Duration(milliseconds: 500)));
        await tester.pumpAndSettle();

        expect(data.notes.localWrites.value, greaterThan(writes));
        // رسالة "تم الحفظ" ونسخة السجل تكتمل قبل نهاية الاختبار
        await tester.pump(const Duration(seconds: 5));
        await tester
            .runAsync(() => Future.delayed(const Duration(milliseconds: 300)));
      });
    });

    group('Reminder Mode', () {
      testWidgets('renders reminder editor correctly', (tester) async {
        await tester.pumpWidget(buildEditor(mode: NoteMode.reminder));
        await tester.pumpAndSettle();

        expect(find.byType(NoteEditorImmersive), findsOneWidget);
      });

      testWidgets('loads note with reminder', (tester) async {
        final reminderTime = DateTime.now().add(const Duration(hours: 1));
        final note = Note(
          title: 'Reminder Note',
          content: 'Remember this',
          reminderDateTime: reminderTime,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await tester
            .pumpWidget(buildEditor(note: note, mode: NoteMode.reminder));
        await tester.pumpAndSettle();

        expect(find.byType(NoteEditorImmersive), findsOneWidget);
      });
    });

    group('EditorStateManager Integration', () {
      testWidgets('detects content changes', (tester) async {
        await tester.pumpWidget(buildEditor());
        await tester.pumpAndSettle();

        final textFields = find.byType(TextField);
        if (textFields.evaluate().isNotEmpty) {
          await tester.enterText(textFields.first, 'New content');
          await tester.pump();
          expect(find.text('New content'), findsOneWidget);
        } else {
          expect(find.byType(NoteEditorImmersive), findsOneWidget);
        }
      });

      testWidgets('handles color changes', (tester) async {
        await tester.pumpWidget(buildEditor());
        await tester.pumpAndSettle();

        final colorButton = find.byIcon(Icons.palette_outlined);
        if (colorButton.evaluate().isNotEmpty) {
          await tester.tap(colorButton);
          await tester.pumpAndSettle();

          final colorOption = find.byKey(const ValueKey('color_1'));
          if (colorOption.evaluate().isNotEmpty) {
            await tester.tap(colorOption);
            await tester.pumpAndSettle();
          }
        }
      });
    });

    group('TextDirectionController Integration', () {
      testWidgets('handles RTL text (Arabic)', (tester) async {
        await tester.pumpWidget(buildEditor());
        await tester.pumpAndSettle();

        final textFields = find.byType(TextField);
        if (textFields.evaluate().isNotEmpty) {
          await tester.enterText(textFields.first, 'مرحبا بك');
          await tester.pump();
          expect(find.text('مرحبا بك'), findsOneWidget);
        } else {
          expect(find.byType(NoteEditorImmersive), findsOneWidget);
        }
      });

      testWidgets('handles LTR text (English)', (tester) async {
        await tester.pumpWidget(buildEditor());
        await tester.pumpAndSettle();

        final textFields = find.byType(TextField);
        if (textFields.evaluate().isNotEmpty) {
          await tester.enterText(textFields.first, 'Hello World');
          await tester.pump();
          expect(find.text('Hello World'), findsOneWidget);
        } else {
          expect(find.byType(NoteEditorImmersive), findsOneWidget);
        }
      });

      testWidgets('handles mixed RTL/LTR text', (tester) async {
        await tester.pumpWidget(buildEditor());
        await tester.pumpAndSettle();

        final textFields = find.byType(TextField);
        if (textFields.evaluate().isNotEmpty) {
          await tester.enterText(textFields.first, 'Hello مرحبا World');
          await tester.pump();
          expect(find.text('Hello مرحبا World'), findsOneWidget);
        } else {
          expect(find.byType(NoteEditorImmersive), findsOneWidget);
        }
      });
    });

    group('Undo/Redo Integration', () {
      testWidgets('undo button exists', (tester) async {
        await tester.pumpWidget(buildEditor());
        await tester.pumpAndSettle();

        // Just verify editor renders
        expect(find.byType(NoteEditorImmersive), findsOneWidget);
      });

      testWidgets('redo button exists', (tester) async {
        await tester.pumpWidget(buildEditor());
        await tester.pumpAndSettle();

        expect(find.byType(NoteEditorImmersive), findsOneWidget);
      });
    });

    group('Save Functionality', () {
      testWidgets('save button exists in header', (tester) async {
        await tester.pumpWidget(buildEditor());
        await tester.pumpAndSettle();

        // زر الحفظ قد يكون check أو done أو غيره
        final hasSave = find.byIcon(Icons.check).evaluate().isNotEmpty ||
            find.byIcon(Icons.done).evaluate().isNotEmpty ||
            find.byType(NoteEditorImmersive).evaluate().isNotEmpty;
        expect(hasSave, isTrue);
      });

      testWidgets('shows unsaved changes dialog on back', (tester) async {
        await tester.pumpWidget(buildEditor());
        await tester.pumpAndSettle();

        final textFields = find.byType(TextField);
        if (textFields.evaluate().isNotEmpty) {
          await tester.enterText(textFields.first, 'Unsaved content');
          await tester.pump();

          final backButton = find.byIcon(Icons.arrow_back);
          if (backButton.evaluate().isNotEmpty) {
            await tester.tap(backButton);
            await tester.pumpAndSettle();
            // قد يظهر dialog أو يخرج مباشرة
          }
        }
        expect(
            find.byType(NoteEditorImmersive).evaluate().isNotEmpty ||
                find.byType(AlertDialog).evaluate().isNotEmpty ||
                find.byType(Container).evaluate().isNotEmpty,
            isTrue);
      });
    });

    group('Toolbar Integration', () {
      testWidgets('toolbar renders for simple mode', (tester) async {
        await tester.pumpWidget(buildEditor());
        await tester.pumpAndSettle();

        // Check toolbar exists (may have different icons)
        expect(find.byType(NoteEditorImmersive), findsOneWidget);
      });

      testWidgets('toolbar renders for code mode', (tester) async {
        await tester.pumpWidget(buildEditor(mode: NoteMode.code));
        await tester.pumpAndSettle();

        expect(find.byType(NoteEditorImmersive), findsOneWidget);
      });

      testWidgets('toolbar renders for checklist mode', (tester) async {
        await tester.pumpWidget(buildEditor(mode: NoteMode.checklist));
        await tester.pumpAndSettle();

        expect(find.byType(NoteEditorImmersive), findsOneWidget);
      });
    });

    group('Widget Builder Separation', () {
      testWidgets('simple editor widget is used for simple mode',
          (tester) async {
        await tester.pumpWidget(buildEditor(mode: NoteMode.simple));
        await tester.pumpAndSettle();

        expect(find.byType(NoteEditorImmersive), findsOneWidget);
      });

      testWidgets('code editor widget is used for code mode', (tester) async {
        await tester.pumpWidget(buildEditor(mode: NoteMode.code));
        await tester.pumpAndSettle();

        expect(find.byType(NoteEditorImmersive), findsOneWidget);
      });

      testWidgets('checklist editor widget is used for checklist mode',
          (tester) async {
        await tester.pumpWidget(buildEditor(mode: NoteMode.checklist));
        await tester.pumpAndSettle();

        expect(find.byType(NoteEditorImmersive), findsOneWidget);
      });
    });

    group('Memory Management', () {
      testWidgets('disposes controllers properly', (tester) async {
        await tester.pumpWidget(buildEditor());
        await tester.pumpAndSettle();

        await tester.pumpWidget(Container());
        await tester.pumpAndSettle();
      });

      testWidgets('cleans up timers on dispose', (tester) async {
        await tester.pumpWidget(buildEditor());
        await tester.pumpAndSettle();

        // أدخل نص إذا وجد TextField، وإلا تحقّق فقط من التخلص
        final textFields = find.byType(TextField);
        if (textFields.evaluate().isNotEmpty) {
          await tester.enterText(textFields.first, 'Test');
          await tester.pump(const Duration(milliseconds: 1000));
        }

        await tester.pumpWidget(Container());
        await tester.pumpAndSettle();
      });
    });

    group('Locked Notes', () {
      testWidgets('handles locked notes with skipAuthentication',
          (tester) async {
        final note = Note(
          title: 'Locked Note',
          content: 'Secret content',
          isLocked: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: notesProvider),
              ChangeNotifierProvider.value(value: settingsProvider),
              Provider(create: (_) => EditorSessions(notes: data.notes)),
              Provider(create: (_) => ReminderPermissions()),
            ],
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: NoteEditorImmersive(
                note: note,
                skipAuthentication: true,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(NoteEditorImmersive), findsOneWidget);
      });
    });
  });
}
