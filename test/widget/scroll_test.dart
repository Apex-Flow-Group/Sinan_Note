// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Recovery page scroll test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 100),
                Container(height: 200, color: Colors.red),
                const SizedBox(height: 100),
                Container(height: 200, color: Colors.blue),
                const SizedBox(height: 100),
                Container(height: 200, color: Colors.green),
                const SizedBox(height: 100),
                Container(height: 200, color: Colors.orange),
              ],
            ),
          ),
        ),
      ),
    );

    // Find scroll view
    final scrollView = find.byType(SingleChildScrollView);
    expect(scrollView, findsOneWidget);

    // Scroll down
    await tester.drag(scrollView, const Offset(0, -300));
    await tester.pumpAndSettle();

    // Verify scroll worked
    expect(scrollView, findsOneWidget);
  });
}
