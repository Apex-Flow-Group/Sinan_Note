// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/widgets.dart';

/// فيزياء تمرير بانزلاق أندرويد الأصلي.
///
/// - الانزلاق بعد رفع الإصبع يتبع منحنى أندرويد الأصلي (`OverScroller` spline)
///   عبر [ClampingScrollSimulation]: يبدأ بسرعة الإصبع ويتباطأ تدريجياً.
/// - القمة: يُسمح بسحب المحتوى فوق أول عنصر بمقاومة (للتحديث بالسحب)
///   ثم يرجع بنابض — موروث من [BouncingScrollPhysics].
/// - القاع: توقف صلب، ويظهر تمطيط أندرويد عبر [StretchingOverscrollIndicator].
/// - الانزلاق لا يعبر القمة أبداً، فلا يفتح مسافة السحب ولا يطلق التحديث.
class GlideScrollPhysics extends BouncingScrollPhysics {
  const GlideScrollPhysics({super.parent});

  @override
  GlideScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return GlideScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    // القاع فقط — القمة مفتوحة لسحب التحديث
    if (position.pixels < position.maxScrollExtent &&
        position.maxScrollExtent < value) {
      return value - position.maxScrollExtent;
    }
    if (position.maxScrollExtent <= position.pixels &&
        position.pixels < value) {
      return value - position.pixels;
    }
    return 0.0;
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    // خارج الحدود (بعد سحب التحديث) — نابض الرجوع من BouncingScrollPhysics
    if (position.outOfRange) {
      return super.createBallisticSimulation(position, velocity);
    }

    final tolerance = toleranceFor(position);
    if (velocity.abs() < tolerance.velocity) return null;
    if (velocity < 0 && position.pixels <= position.minScrollExtent) {
      return null;
    }
    if (velocity > 0 && position.pixels >= position.maxScrollExtent) {
      return null;
    }

    return EdgeClampedSimulation(
      ClampingScrollSimulation(
        position: position.pixels,
        velocity: velocity,
        tolerance: tolerance,
      ),
      min: position.minScrollExtent,
      max: position.maxScrollExtent,
    );
  }
}

/// يحصر محاكاة انزلاق بين حدّين ويوقفها لحظة ملامسة أي منهما.
class EdgeClampedSimulation extends Simulation {
  EdgeClampedSimulation(this.inner, {required this.min, required this.max})
      : super(tolerance: inner.tolerance);

  final Simulation inner;
  final double min;
  final double max;

  bool _atEdge(double time) {
    final x = inner.x(time);
    return x <= min || x >= max;
  }

  @override
  double x(double time) => inner.x(time).clamp(min, max);

  @override
  double dx(double time) => _atEdge(time) ? 0.0 : inner.dx(time);

  @override
  bool isDone(double time) => inner.isDone(time) || _atEdge(time);
}
