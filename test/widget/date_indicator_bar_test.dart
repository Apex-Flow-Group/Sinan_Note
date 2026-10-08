// Copyright © 2025 Apex Flow Group. All rights reserved.

// شريط التاريخ يُظهر تاريخ أول ملاحظة حتى حين تصل الملاحظات بعد ظهوره
// (الرئيسية تظهر قبل اكتمال تحميلها)، ويُفرغ حين لا تبقى ملاحظات.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sinan_note/data/repositories/sync_repository.dart';
import 'package:sinan_note/data/services/sync/drive_sync_remote.dart';
import 'package:sinan_note/domain/models/note.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';
import 'package:sinan_note/ui/features/categories/view_models/categories_provider.dart';
import 'package:sinan_note/ui/features/home/widgets/date_indicator_bar.dart';
import 'package:sinan_note/ui/features/sync/view_models/sync_view_model.dart';

import '../helpers/test_data_layer.dart';
import '../test_setup.dart';

void main() {
  setUpAll(initializeTestEnvironment);

  late TestDataLayer data;
  late ValueNotifier<List<Note>> notes;

  Note note(int id, DateTime at) =>
      Note(id: id, title: 'n$id', content: '', createdAt: at, updatedAt: at);

  late ScrollController scroll;

  /// الشريط فوق قائمة طويلة يمررها [scroll] (كل بطاقة 80 بكسل افتراضياً).
  Future<void> pumpBar(WidgetTester tester) async {
    scroll = ScrollController();
    await tester.runAsync(() async => data = await TestDataLayer.create());
    addTearDown(() => tester.runAsync(data.dispose));
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider(
              create: (_) => CategoriesProvider(categories: data.categories)),
          ChangeNotifierProvider(
            create: (_) => SyncViewModel(
              notes: data.notes,
              sync: SyncRepository(
                notes: data.notes,
                categories: data.categories,
                tombstones: data.tombstones,
                remote: _SignedOut(),
                store: data.store,
              ),
            ),
          ),
        ],
        child: Scaffold(
          body: Column(children: [
            DateIndicatorBar(
              scrollController: scroll,
              filteredNotesNotifier: notes,
              noteHeights: const {},
              activeFilterNotifier: ValueNotifier<String?>(null),
            ),
            Expanded(
              child: ListView(
                controller: scroll,
                children: const [SizedBox(height: 3000)],
              ),
            ),
          ]),
        ),
      ),
    ));
    await tester.pump();
  }

  testWidgets('notes that arrive after the bar is shown give it a date',
      (tester) async {
    notes = ValueNotifier([]);
    await pumpBar(tester);
    expect(find.text('Today'), findsNothing);

    // التحميل يكتمل بعد ظهور الرئيسية
    notes.value = [note(1, DateTime.now())];
    await tester.pump();
    expect(find.text('Today'), findsOneWidget);
  });

  testWidgets('notes already loaded show their date at once', (tester) async {
    notes = ValueNotifier([note(1, DateTime.now())]);
    await pumpBar(tester);
    expect(find.text('Today'), findsOneWidget);
  });

  testWidgets('a new first note changes the date; no notes clears it',
      (tester) async {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    notes = ValueNotifier([note(1, yesterday)]);
    await pumpBar(tester);
    expect(find.text('Yesterday'), findsOneWidget);

    notes.value = [note(2, DateTime.now()), note(1, yesterday)];
    await tester.pump();
    expect(find.text('Today'), findsOneWidget);

    notes.value = [];
    await tester.pump();
    expect(find.text('Today'), findsNothing);
    expect(find.text('Yesterday'), findsNothing);
  });

  testWidgets('scrolling shows the date of the note at the top',
      (tester) async {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    // ثلاث ملاحظات اليوم (240 بكسل) ثم ملاحظات الأمس
    notes = ValueNotifier([
      for (var i = 1; i <= 3; i++) note(i, DateTime.now()),
      for (var i = 4; i <= 9; i++) note(i, yesterday),
    ]);
    await pumpBar(tester);
    expect(find.text('Today'), findsOneWidget);

    scroll.jumpTo(300);
    await tester.pump();
    expect(find.text('Yesterday'), findsOneWidget);

    scroll.jumpTo(0);
    await tester.pump();
    expect(find.text('Today'), findsOneWidget);
  });
}

/// حساب غير مسجّل؛ الشريط لا يطلب منه شيئاً.
class _SignedOut implements SyncRemote {
  @override
  bool get isSignedIn => false;

  @override
  String? get accountEmail => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
