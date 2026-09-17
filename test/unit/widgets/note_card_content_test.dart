// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sinan_note/controllers/categories/categories_provider.dart';
import 'package:sinan_note/controllers/notes/notes_provider.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';
import 'package:sinan_note/models/note.dart';
import 'package:sinan_note/screens/mobile/home_screen.dart' show ViewType;
import 'package:sinan_note/widgets/home/note_card/note_card_content.dart';

void main() {
  Note note({
    String title = 'Release Roadmap',
    String content = 'plain preview text',
    bool isLocked = false,
    bool isPinned = false,
    DateTime? reminder,
    String noteType = 'simple',
  }) {
    final now = DateTime(2026, 1, 1);
    return Note(
      id: 1,
      title: title,
      content: content,
      createdAt: now,
      updatedAt: now,
      isLocked: isLocked,
      isPinned: isPinned,
      reminderDateTime: reminder,
      noteType: noteType,
    );
  }

  Future<void> pumpContent(
    WidgetTester tester, {
    required Note subject,
    ViewType viewType = ViewType.grid,
    String source = 'home_grid',
    String preview = 'plain preview text',
    String fileExtension = '',
  }) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CategoriesProvider>(
            create: (_) => CategoriesProvider(),
          ),
          // بطاقة الملاحظة المقفلة تبني قائمتها من هذا المزوّد
          ChangeNotifierProvider<NotesProvider>(
            create: (_) => NotesProvider(),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: NoteCardContent(
              note: subject,
              viewType: viewType,
              source: source,
              title: subject.title,
              preview: preview,
              titleDirection: ui.TextDirection.ltr,
              previewDirection: ui.TextDirection.ltr,
              titleColor: Colors.white,
              contentColor: Colors.white70,
              isChecklist: false,
              checklistItems: const [],
              fileExtension: fileExtension,
              selectionMode: false,
              isFiltering: false,
              onNoteChanged: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('shows the title and preview in grid view', (tester) async {
    await pumpContent(tester, subject: note());
    expect(find.text('Release Roadmap'), findsOneWidget);
    expect(find.text('plain preview text'), findsOneWidget);
  });

  testWidgets('compact view drops the preview', (tester) async {
    await pumpContent(
      tester,
      subject: note(),
      viewType: ViewType.listCompact,
    );
    expect(find.text('Release Roadmap'), findsOneWidget);
    expect(find.text('plain preview text'), findsNothing);
  });

  testWidgets('a locked note never renders its preview outside the vault',
      (tester) async {
    await pumpContent(
      tester,
      subject: note(isLocked: true),
      preview: 'secret body',
    );
    expect(find.text('secret body'), findsNothing);
    expect(find.byIcon(Icons.lock), findsOneWidget);
  });

  testWidgets('shows the pin marker for a pinned note', (tester) async {
    await pumpContent(tester, subject: note(isPinned: true));
    expect(find.byIcon(Icons.push_pin), findsOneWidget);
  });

  testWidgets('reminder badge marks an expired reminder', (tester) async {
    await pumpContent(
      tester,
      subject: note(reminder: DateTime(2020, 5, 4, 9, 30)),
    );
    expect(find.byIcon(Icons.alarm_off), findsOneWidget);
    expect(find.textContaining('Mon, May 4'), findsOneWidget);
    expect(find.textContaining('•'), findsOneWidget);
  });

  testWidgets('reminder badge marks an upcoming reminder', (tester) async {
    await pumpContent(
      tester,
      subject: note(reminder: DateTime.now().add(const Duration(days: 2))),
    );
    expect(find.byIcon(Icons.alarm), findsOneWidget);
  });

  testWidgets('shows a file extension badge for code notes', (tester) async {
    await pumpContent(
      tester,
      subject: note(noteType: 'code'),
      fileExtension: '.dart',
    );
    expect(find.text('.dart'), findsOneWidget);
    expect(find.byIcon(Icons.code), findsOneWidget);
  });

  testWidgets('no extension badge when there is no extension', (tester) async {
    await pumpContent(tester, subject: note());
    expect(find.byIcon(Icons.code), findsNothing);
  });
}
