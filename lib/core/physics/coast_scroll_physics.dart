// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// انزلاق ما بعد رفع الإصبع.
///
/// المنحنى `1 - (1 - t)^k` يبدأ بسرعة الإصبع بالضبط وتصل سرعته صفراً عند نهاية
/// المدة، فلا قفزة قبل السكون ولا انقطاع لحظة الإفلات.
///
/// المدة ثابتة والمسافة تتبع سرعة الإفلات: سحبة قوية تقطع أكثر من سحبة خفيفة
/// خلال نفس زمن التباطؤ.
///
/// المحاكاة لا تعرف آخر عنصر؛ التوقف عنده مسؤولية
/// [CoastScrollPhysics.applyBoundaryConditions].
/// انزلاق نحو القمة يقف عند [CoastFlingSimulation.ceiling] ولا يدخل مساحة السحب.
class CoastFlingSimulation extends Simulation {
  CoastFlingSimulation({
    required double position,
    required double velocity,
    super.tolerance,
    this.ceiling,
  })  : assert(velocity != 0),
        _start = position,
        _velocity = velocity;

  /// حد القمة. الانزلاق يتمطّط قليلاً بعده ثم يتوقف ليرجع النابض.
  final double? ceiling;

  final double _start;
  final double _velocity;

  static const double _duration = CoastScrollPhysics.coastDuration;
  static const double _curve = CoastScrollPhysics.coastCurve;

  /// زمن التباطؤ الكامل بالثواني.
  double get duration => _duration;

  /// المسافة التي يقطعها الانزلاق لو لم يعترضه حدّ.
  double get reach => _velocity * _duration / _curve;

  double _t(double time) => (time / _duration).clamp(0.0, 1.0);

  double _raw(double time) {
    return _start + reach * (1.0 - math.pow(1.0 - _t(time), _curve));
  }

  bool _hitCeiling(double time) {
    final ceiling = this.ceiling;
    return ceiling != null && _velocity < 0 && _raw(time) <= ceiling;
  }

  /// تمطيط قصير فوق القمة، لا فجوة سحب.
  double _stretch(double time) {
    final past = ceiling! - _raw(time);
    const limit = CoastScrollPhysics.edgeStretch;
    return limit * (1.0 - math.exp(-past / limit));
  }

  @override
  double x(double time) {
    final raw = _raw(time);
    if (!_hitCeiling(time)) return raw;
    return ceiling! - _stretch(time);
  }

  @override
  double dx(double time) {
    if (isDone(time)) return 0.0;
    return _velocity * math.pow(1.0 - _t(time), _curve - 1.0);
  }

  @override
  bool isDone(double time) {
    if (time >= _duration) return true;
    if (!_hitCeiling(time)) return false;
    if (_stretch(time) >= CoastScrollPhysics.edgeStretch * 0.92) return true;
    final speed = _velocity * math.pow(1.0 - _t(time), _curve - 1.0);
    return speed.abs() < 350;
  }
}

/// فيزياء تمرير القوائم والشبكات.
///
/// انزلاق يتباطأ حتى الصفر خلال [coastDuration]، وتوقف صلب عند طرفي القائمة
/// بلا ارتداد. الشاشات التي فيها تحديث بالسحب تفتح مسافة سحب فوق القمة عبر
/// [pullExtent]؛ ما عداها لا يتحرك المحتوى فوق أول عنصر إطلاقاً.
class CoastScrollPhysics extends ScrollPhysics {
  const CoastScrollPhysics({super.parent, this.pullExtent = 0});

  /// أقصى مسافة (px) يُسمح بسحب المحتوى فوق أول عنصر. صفر = توقف صلب.
  final double pullExtent;

  /// زمن تباطؤ الانزلاق بالثواني.
  static const double coastDuration = 2.0;

  /// أُس المنحنى — أعلى يعني مسافة أقصر وذيلاً أطول قبل السكون.
  static const double coastCurve = 3.4;

  /// px/s — أقصى سرعة إفلات تُقرأ من الإصبع.
  static const double flingSpeedCap = 5000;

  /// مسافة سحب تكفي لظهور مؤشر التحديث فوق القائمة.
  static const double refreshPullExtent = 120;

  /// تمطيط الانزلاق عند القمة. أصغر من عتبة التحديث حتى لا يفتح فجوة.
  static const double edgeStretch = 28;

  /// مقاومة السحب عند أول بكسل فوق القمة — أصغر يعني شداً أثقل.
  static const double _pullResistance = 0.52;

  @override
  CoastScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return CoastScrollPhysics(
      parent: buildParent(ancestor),
      pullExtent: pullExtent,
    );
  }

  @override
  double get maxFlingVelocity => flingSpeedCap;

  /// السحب فوق القمة يثقل كلما اقترب من [pullExtent] ويتوقف عنده.
  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    final beyondTop = position.minScrollExtent - position.pixels;
    if (offset == 0.0 || beyondTop <= 0.0 || pullExtent <= 0.0) return offset;

    final magnitude = offset.abs();
    // offset سالب يعني رجوعاً نحو القائمة — نقيس المقاومة عند وجهة الحركة
    final target = offset < 0.0 ? beyondTop - magnitude : beyondTop;
    final gamma = _pullFriction(target);
    return offset.sign * _applyFriction(beyondTop, magnitude, gamma);
  }

  double _pullFriction(double beyondTop) {
    final ratio = (beyondTop / pullExtent).clamp(0.0, 1.0);
    return _pullResistance * math.pow(1.0 - ratio, 2.0);
  }

  static double _applyFriction(
    double extentOutside,
    double absDelta,
    double gamma,
  ) {
    if (gamma <= 0.0) return 0.0;

    var remaining = absDelta;
    var total = 0.0;
    if (extentOutside > 0) {
      final cap = extentOutside / gamma;
      if (remaining < cap) return remaining * gamma;
      total += extentOutside;
      remaining -= cap;
    }
    return total + remaining;
  }

  /// الطرفان سواء: التجاوز يُمتص فيُطلق تمطيط الحافة، ولا تُزاح القائمة فتفتح فجوة.
  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    final pixels = position.pixels;
    final max = position.maxScrollExtent;
    final min = position.minScrollExtent;

    if (pixels >= max && value > pixels) return value - pixels;
    if (pixels < max && value > max) return value - max;
    if (pixels <= min && value < pixels) return value - pixels;
    if (pixels > min && value < min) return value - min;
    return 0.0;
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    final tolerance = toleranceFor(position);
    final speed = velocity.clamp(-flingSpeedCap, flingSpeedCap).toDouble();

    final settle = _settleTarget(position);
    if (settle != null) {
      // سرعة متجهة خارج القائمة تصطدم بالحد وتُبقي الفجوة. نُسقطها
      // فيرجع النابض بسلاسة نحو الحد دون غوص إضافي.
      final outward = (settle - position.pixels).sign;
      final settleSpeed = speed.sign == outward || speed == 0 ? speed : 0.0;
      return ScrollSpringSimulation(
        spring,
        position.pixels,
        settle,
        settleSpeed,
        tolerance: tolerance,
      );
    }

    if (speed.abs() < tolerance.velocity) return null;
    if (speed > 0 && position.pixels >= position.maxScrollExtent) return null;
    if (speed < 0 && position.pixels <= position.minScrollExtent) return null;

    return CoastFlingSimulation(
      position: position.pixels,
      velocity: speed,
      tolerance: tolerance,
    );
  }

  /// الحد الذي يجب الرجوع إليه بنابض إذا كنا خارج النطاق، وإلا `null`.
  double? _settleTarget(ScrollMetrics position) {
    if (position.pixels < position.minScrollExtent) {
      return position.minScrollExtent;
    }
    if (position.pixels > position.maxScrollExtent) {
      return position.maxScrollExtent;
    }
    return null;
  }
}

/// يجعل [CoastScrollPhysics] فيزياء التمرير الافتراضية للتطبيق.
///
/// أي `Scrollable` لا يمرّر `physics` صريحاً يأخذها تلقائياً؛ ومَن يمرّرها
/// (مثل `NeverScrollableScrollPhysics` أو فيزياء الصفحات) يبقى على حاله.
mixin CoastScrollBehaviorMixin on ScrollBehavior {
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const CoastScrollPhysics();
}
