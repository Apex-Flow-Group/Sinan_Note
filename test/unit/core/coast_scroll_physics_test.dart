// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sinan_note/core/physics/coast_scroll_physics.dart';
import 'package:sinan_note/widgets/home/smooth_search_header_delegate.dart';

void main() {
  group('CoastFlingSimulation', () {
    test('starts at the finger velocity', () {
      final sim = CoastFlingSimulation(position: 0, velocity: -1200);
      expect(sim.dx(0), closeTo(-1200, 0.001));
    });

    test('decelerates to zero over the full coast duration', () {
      final sim = CoastFlingSimulation(position: 0, velocity: 3000);
      expect(sim.duration, CoastScrollPhysics.coastDuration);
      expect(sim.dx(sim.duration), 0);
      expect(sim.isDone(sim.duration), isTrue);
      expect(sim.isDone(sim.duration - 0.01), isFalse);
    });

    test('velocity only decreases along the way', () {
      final sim = CoastFlingSimulation(position: 0, velocity: 3000);
      var previous = sim.dx(0);
      for (var t = 0.05; t <= sim.duration; t += 0.05) {
        final current = sim.dx(t);
        expect(current, lessThanOrEqualTo(previous));
        previous = current;
      }
    });

    test('a strong fling travels much further than a light one', () {
      final light = CoastFlingSimulation(position: 0, velocity: 800);
      final medium = CoastFlingSimulation(position: 0, velocity: 2500);
      final strong = CoastFlingSimulation(position: 0, velocity: 5000);

      expect(light.reach, lessThan(medium.reach));
      expect(medium.reach, lessThan(strong.reach));
      expect(strong.reach / light.reach, closeTo(5000 / 800, 0.001));
    });

    test('distance is never clamped to a stale scroll extent', () {
      final sim = CoastFlingSimulation(position: 0, velocity: 5000);
      expect(sim.x(sim.duration), closeTo(sim.reach, 0.001));
    });
  });

  group('CoastScrollPhysics', () {
    FixedScrollMetrics metrics({
      required double pixels,
      double min = 0,
      double max = 4000,
    }) {
      return FixedScrollMetrics(
        minScrollExtent: min,
        maxScrollExtent: max,
        pixels: pixels,
        viewportDimension: 800,
        axisDirection: AxisDirection.down,
        devicePixelRatio: 1,
      );
    }

    const physics = CoastScrollPhysics();

    test('caps the fling speed', () {
      final sim = physics.createBallisticSimulation(
        metrics(pixels: 500),
        9000,
      );
      expect(sim, isNotNull);
      expect(sim!.dx(0), closeTo(CoastScrollPhysics.flingSpeedCap, 0.001));
    });

    test('keeps flings below the cap distinct', () {
      final light = physics.createBallisticSimulation(
        metrics(pixels: 0),
        900,
      )!;
      final strong = physics.createBallisticSimulation(
        metrics(pixels: 0),
        3600,
      )!;
      expect(strong.x(0.5), greaterThan(light.x(0.5) * 3));
    });

    test('absorbs any overscroll past the last item', () {
      expect(
        physics.applyBoundaryConditions(metrics(pixels: 3950), 4120),
        closeTo(120, 0.001),
      );
      expect(
        physics.applyBoundaryConditions(metrics(pixels: 4000), 4060),
        closeTo(60, 0.001),
      );
    });

    test('leaves normal scrolling untouched', () {
      expect(physics.applyBoundaryConditions(metrics(pixels: 500), 620), 0);
    });

    test('holds the top edge when no pull room is granted', () {
      expect(
        physics.applyBoundaryConditions(metrics(pixels: 0), -90),
        closeTo(-90, 0.001),
      );
      expect(physics.applyPhysicsToUserOffset(metrics(pixels: 0), 30), 30);
    });

    test('the top absorbs overscroll the same way as the bottom', () {
      const pulling = CoastScrollPhysics(
        pullExtent: CoastScrollPhysics.refreshPullExtent,
      );

      expect(
        pulling.applyBoundaryConditions(metrics(pixels: 0), -90),
        closeTo(-90, 0.001),
      );
      expect(
        pulling.applyBoundaryConditions(metrics(pixels: 4000), 4090),
        closeTo(90, 0.001),
      );
      // والمقاومة تزيد كلما اقترب من الحد
      final near =
          pulling.applyPhysicsToUserOffset(metrics(pixels: -10), 20).abs();
      final far =
          pulling.applyPhysicsToUserOffset(metrics(pixels: -100), 20).abs();
      expect(far, lessThan(near));
    });

    test('applyTo keeps the pull room', () {
      const pulling = CoastScrollPhysics(pullExtent: 120);
      final applied = pulling.applyTo(const AlwaysScrollableScrollPhysics());
      expect(applied.pullExtent, 120);
    });

    test('does not start a fling that sits on the last item', () {
      expect(
        physics.createBallisticSimulation(metrics(pixels: 4000), 1200),
        isNull,
      );
    });

    test('still flings when the extent is only an estimate', () {
      final sim = physics.createBallisticSimulation(
        metrics(pixels: 3900, max: 4000),
        4000,
      );
      expect(sim, isA<CoastFlingSimulation>());
      final coast = sim! as CoastFlingSimulation;
      expect(coast.x(coast.duration), greaterThan(4000));
    });

    test('springs back when content shrinks below the current offset', () {
      final sim = physics.createBallisticSimulation(metrics(pixels: 4200), 0);
      expect(sim, isA<ScrollSpringSimulation>());
    });

    test('an upward fling runs past the top the same way a downward fling runs past the bottom', () {
      const pulling = CoastScrollPhysics(pullExtent: 120);
      final sim = pulling.createBallisticSimulation(
        metrics(pixels: 900),
        -4000,
      );
      expect(sim, isA<CoastFlingSimulation>());
      final coast = sim! as CoastFlingSimulation;
      expect(coast.x(coast.duration), lessThan(0));
    });

    test('release in the pull zone springs back without diving further', () {
      const pulling = CoastScrollPhysics(pullExtent: 120);
      final sim = pulling.createBallisticSimulation(
        metrics(pixels: -90),
        -2500,
      )!;
      expect(sim, isA<ScrollSpringSimulation>());
      expect(sim.dx(0), 0);
      expect(sim.x(0.2), greaterThan(-90));
    });

    test('a flick back from the pull zone keeps its upward speed', () {
      const pulling = CoastScrollPhysics(pullExtent: 120);
      final sim = pulling.createBallisticSimulation(
        metrics(pixels: -40),
        800,
      )!;
      expect(sim.dx(0), closeTo(800, 0.01));
    });

    test('an explicit pull at the top is absorbed like the bottom edge', () {
      const pulling = CoastScrollPhysics(pullExtent: 120);
      expect(
        pulling.applyBoundaryConditions(metrics(pixels: 0), -90),
        closeTo(-90, 0.001),
      );
    });
  });

  testWidgets('flinging up from the bottom settles on the first item',
      (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    var lowest = 0.0;
    controller.addListener(() {
      if (!controller.hasClients) return;
      if (controller.offset < lowest) lowest = controller.offset;
    });

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 400,
          height: 600,
          child: CustomScrollView(
            controller: controller,
            physics: const CoastScrollPhysics(
              pullExtent: CoastScrollPhysics.refreshPullExtent,
            ),
            slivers: [
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, index) => SizedBox(height: 80, child: Text('n$index')),
                  childCount: 40,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    controller.jumpTo(700);
    await tester.pump();

    // إصبع قصير ثم إفلات: الانزلاق وحده هو الذي يصل للقمة.
    await tester.fling(
      find.byType(CustomScrollView),
      const Offset(0, 80),
      5000,
    );
    await tester.pumpAndSettle();

    expect(lowest, greaterThanOrEqualTo(0));
    expect(controller.offset, 0);
    expect(find.text('n0'), findsOneWidget);
  });

  testWidgets('a finger pull at the top still opens the pull zone',
      (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 400,
          height: 600,
          child: CustomScrollView(
            controller: controller,
            physics: const CoastScrollPhysics(
              pullExtent: CoastScrollPhysics.refreshPullExtent,
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, index) => SizedBox(height: 80, child: Text('n$index')),
                  childCount: 4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    final gesture = await tester.startGesture(const Offset(200, 300));
    await gesture.moveBy(const Offset(0, 160));
    await tester.pump();

    expect(controller.offset, greaterThanOrEqualTo(0));

    await gesture.up();
    await tester.pumpAndSettle();
    expect(controller.offset, 0);
  });

  testWidgets('a scroll end at the top does not animate or open a gap',
      (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(home: _TopList(controller: controller)),
    );
    await tester.pumpAndSettle();
    expect(controller.offset, 0);

    final gesture = await tester.startGesture(const Offset(200, 400));
    await tester.pump();
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(controller.offset, 0);
    expect(controller.position.isScrollingNotifier.value, isFalse);

    final dateBottom = tester.getBottomLeft(find.text('date')).dy;
    final noteTop = tester.getTopLeft(find.text('n0')).dy;
    expect(noteTop - dateBottom, lessThan(8));
  });
}

class _TopList extends StatefulWidget {
  const _TopList({required this.controller});
  final ScrollController controller;

  @override
  State<_TopList> createState() => _TopListState();
}

class _TopListState extends State<_TopList> with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: widget.controller,
      physics: const CoastScrollPhysics(
        pullExtent: CoastScrollPhysics.refreshPullExtent,
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        SliverPersistentHeader(
          pinned: true,
          floating: true,
          delegate: SmoothSearchHeaderDelegate(
            expandedHeight: 68,
            statusBarHeight: 0,
            tickerProvider: this,
            hideOnScroll: true,
            child: const SizedBox(height: 68, child: Text('search')),
          ),
        ),
        const SliverPersistentHeader(
          pinned: true,
          delegate: _DateDelegate(),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, index) => SizedBox(height: 80, child: Text('n$index')),
            childCount: 30,
          ),
        ),
      ],
    );
  }
}

class _DateDelegate extends SliverPersistentHeaderDelegate {
  const _DateDelegate();

  @override
  Widget build(
          BuildContext context, double shrinkOffset, bool overlapsContent) =>
      const SizedBox(height: 28, child: Text('date'));

  @override
  double get maxExtent => 28;

  @override
  double get minExtent => 28;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      false;
}
