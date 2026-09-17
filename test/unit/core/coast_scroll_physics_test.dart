// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sinan_note/core/physics/coast_scroll_physics.dart';

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

    test('grants exactly the requested pull room above the top', () {
      const pulling = CoastScrollPhysics(
        pullExtent: CoastScrollPhysics.refreshPullExtent,
      );

      // داخل مسافة السحب: لا شيء يُمتص
      expect(pulling.applyBoundaryConditions(metrics(pixels: 0), -90), 0);
      // خارجها: يُمتص الفائض فقط
      expect(
        pulling.applyBoundaryConditions(metrics(pixels: -100), -160),
        closeTo(-40, 0.001),
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
  });
}
