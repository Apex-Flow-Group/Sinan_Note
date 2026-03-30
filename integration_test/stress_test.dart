// Stress Test for Sinan Note
import 'package:apex_note/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

// Stress Test for Sinan Note
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Stress Tests', () {
    testWidgets('Create 50 notes rapidly', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      for (int i = 0; i < 50; i++) {
        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField).first, 'Stress $i');
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.save));
        await tester.pumpAndSettle(const Duration(milliseconds: 100));
      }
    });

    testWidgets('Rapid scroll test', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      for (int i = 0; i < 30; i++) {
        await tester.drag(find.byType(ListView), const Offset(0, -500));
        await tester.pump();
        await tester.drag(find.byType(ListView), const Offset(0, 500));
        await tester.pump();
      }
    });

    testWidgets('Memory leak - Create/Delete cycle', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      for (int i = 0; i < 20; i++) {
        // Create
        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField).first, 'Temp $i');
        await tester.tap(find.byIcon(Icons.save));
        await tester.pumpAndSettle();

        // Delete
        await tester.longPress(find.text('Temp $i'));
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.delete));
        await tester.pumpAndSettle();
      }
    });
  });
}
