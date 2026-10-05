import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sinan_note/core/physics/glide_scroll_physics.dart';

ScrollMetrics _metrics(double pixels, {double max = 5000}) {
  return FixedScrollMetrics(
    minScrollExtent: 0,
    maxScrollExtent: max,
    pixels: pixels,
    viewportDimension: 800,
    axisDirection: AxisDirection.down,
    devicePixelRatio: 3,
  );
}

void main() {
  const physics = GlideScrollPhysics(parent: AlwaysScrollableScrollPhysics());

  group('GlideScrollPhysics', () {
    test('fling glides with the Android spline curve', () {
      final sim = physics.createBallisticSimulation(_metrics(1000), 3000)!;
      final reference =
          ClampingScrollSimulation(position: 1000, velocity: 3000);
      for (final t in [0.1, 0.3, 0.6]) {
        expect(sim.x(t), closeTo(reference.x(t), 0.001));
      }
      // ينزلق مسافة ملموسة ويتباطأ تدريجياً
      expect(sim.x(0.6) - 1000, greaterThan(600));
      expect(sim.dx(0.6), lessThan(sim.dx(0.1)));
    });

    test('fling toward the top stops at the top, never into the pull area',
        () {
      final sim = physics.createBallisticSimulation(_metrics(200), -6000)!;
      for (var t = 0.0; t < 3; t += 0.05) {
        expect(sim.x(t), greaterThanOrEqualTo(0));
      }
      expect(sim.isDone(3), isTrue);
    });

    test('fling toward the bottom stops at the last item', () {
      final sim = physics.createBallisticSimulation(_metrics(4800), 6000)!;
      for (var t = 0.0; t < 3; t += 0.05) {
        expect(sim.x(t), lessThanOrEqualTo(5000));
      }
    });

    test('dragging above the top is allowed (pull to refresh)', () {
      expect(physics.applyBoundaryConditions(_metrics(0), -50), 0);
    });

    test('dragging past the bottom is clamped', () {
      expect(physics.applyBoundaryConditions(_metrics(4990), 5020), 20);
    });

    test('releasing a pull springs back to the top', () {
      final sim = physics.createBallisticSimulation(_metrics(-90), 0)!;
      expect(sim.x(5), closeTo(0, 1));
    });
  });
}
