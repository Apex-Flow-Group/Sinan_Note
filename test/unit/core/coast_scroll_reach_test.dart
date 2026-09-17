// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sinan_note/core/physics/coast_scroll_physics.dart';

void main() {
  Widget grid({
    required int childCount,
    required int firstIndex,
    required double bottomPadding,
  }) {
    return SliverPadding(
      padding: EdgeInsets.only(top: 4, bottom: bottomPadding),
      sliver: SliverMasonryGrid(
        key: ValueKey<int>(firstIndex),
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        gridDelegate: const SliverSimpleGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final id = firstIndex + index;
            return SizedBox(
              height: 90 + (id % 5) * 40,
              child: Text('note $id'),
            );
          },
          childCount: childCount,
        ),
      ),
    );
  }

  Widget harness(
    ScrollPhysics physics,
    ScrollController controller, {
    bool twoLazyGrids = false,
  }) {
    final sections = twoLazyGrids
        ? [
            grid(childCount: 6, firstIndex: 0, bottomPadding: 0),
            grid(childCount: 94, firstIndex: 6, bottomPadding: 180),
          ]
        : [grid(childCount: 100, firstIndex: 0, bottomPadding: 180)];

    return MaterialApp(
      home: Scaffold(
        body: CustomScrollView(
          controller: controller,
          cacheExtent: 1500,
          physics: physics,
          slivers: [SliverMainAxisGroup(slivers: sections)],
        ),
      ),
    );
  }

  Future<double> dragToBottom(
    WidgetTester tester,
    ScrollController controller,
  ) async {
    var previous = -1.0;
    for (var i = 0; i < 60; i++) {
      if (controller.offset == previous) break;
      previous = controller.offset;
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
      await tester.pumpAndSettle();
    }
    return controller.offset;
  }

  testWidgets('coast physics reaches the very bottom of a masonry grid',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2000);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    final controller = ScrollController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      harness(const CoastScrollPhysics(), controller),
    );
    await tester.pumpAndSettle();

    final reached = await dragToBottom(tester, controller);
    expect(reached, controller.position.maxScrollExtent);
    expect(find.text('note 99'), findsOneWidget);
  });

  testWidgets('a shrink-wrapped pinned section keeps the list reachable',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2000);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    final controller = ScrollController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomScrollView(
            controller: controller,
            cacheExtent: 1500,
            physics: const CoastScrollPhysics(),
            slivers: [
              SliverMainAxisGroup(
                slivers: [
                  const SliverToBoxAdapter(child: Text('Pinned')),
                  SliverToBoxAdapter(
                    child: MasonryGridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 6,
                      crossAxisSpacing: 6,
                      shrinkWrap: true,
                      primary: false,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      itemCount: 6,
                      itemBuilder: (context, index) => SizedBox(
                        height: 90 + (index % 5) * 40,
                        child: Text('pinned $index'),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: Text('Others')),
                  grid(childCount: 94, firstIndex: 6, bottomPadding: 180),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('pinned 0'), findsOneWidget);
    final reached = await dragToBottom(tester, controller);
    expect(reached, controller.position.maxScrollExtent);
    expect(find.text('note 99'), findsOneWidget);
  });

  testWidgets('two lazy masonry grids stall before the end', (tester) async {
    tester.view.physicalSize = const Size(1080, 2000);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    final controller = ScrollController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      harness(const CoastScrollPhysics(), controller, twoLazyGrids: true),
    );
    await tester.pumpAndSettle();

    final reached = await dragToBottom(tester, controller);
    expect(reached, lessThan(controller.position.maxScrollExtent / 2));
  });

  testWidgets('clamping physics reaches the same bottom', (tester) async {
    tester.view.physicalSize = const Size(1080, 2000);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    final controller = ScrollController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      harness(const ClampingScrollPhysics(), controller),
    );
    await tester.pumpAndSettle();

    final reached = await dragToBottom(tester, controller);
    expect(reached, controller.position.maxScrollExtent);
    expect(find.text('note 99'), findsOneWidget);
  });
}
