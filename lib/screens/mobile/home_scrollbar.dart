// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:async';

import 'package:apex_note/models/note.dart';
import 'package:flutter/material.dart';

class HomeScrollbar extends StatelessWidget {
  final ScrollController scrollController;
  final ValueNotifier<List<Note>> notesNotifier;
  final bool interactive;
  final ValueNotifier<int>? totalCountNotifier;

  const HomeScrollbar({
    super.key,
    required this.scrollController,
    required this.notesNotifier,
    this.interactive = true,
    this.totalCountNotifier,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary.withValues(alpha: 0.5);
    return Positioned(
      top: 0,
      bottom: 0,
      right: 2,
      width: 10,
      child: IgnorePointer(
        ignoring: !interactive,
        child: _ScrollThumb(
          scrollController: scrollController,
          color: color,
          totalCountNotifier: totalCountNotifier,
        ),
      ),
    );
  }
}

class _ScrollThumb extends StatefulWidget {
  final ScrollController scrollController;
  final Color color;
  final ValueNotifier<int>? totalCountNotifier;

  const _ScrollThumb({
    required this.scrollController,
    required this.color,
    this.totalCountNotifier,
  });

  @override
  State<_ScrollThumb> createState() => _ScrollThumbState();
}

class _ScrollThumbState extends State<_ScrollThumb>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const double _trackPadTop = 80.0;
  static const double _trackPadBottom = 60.0;
  static const double _thumbMinHeight = 32.0;
  static const double _thumbWidth = 6.0;

  double _thumbTop = 0;
  double _thumbHeight = 40;
  double _targetTop = 0;
  double _targetHeight = 40;
  bool _visible = false;
  Timer? _hideTimer;

  late final AnimationController _fadeController;
  late final AnimationController _posController;
  late Animation<double> _topAnimation;
  late Animation<double> _heightAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _posController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    _topAnimation = AlwaysStoppedAnimation(_thumbTop);
    _heightAnimation = AlwaysStoppedAnimation(_thumbHeight);

    _posController.addListener(() {
      if (mounted) setState(() {});
    });

    widget.scrollController.addListener(_update);
    widget.totalCountNotifier?.addListener(_update);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _update());
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _fadeController.dispose();
    _posController.dispose();
    widget.scrollController.removeListener(_update);
    widget.totalCountNotifier?.removeListener(_update);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _update() {
    if (!widget.scrollController.hasClients) return;
    final pos = widget.scrollController.position;
    if (pos.maxScrollExtent <= 0) {
      _hide();
      return;
    }

    final trackH = pos.viewportDimension - _trackPadTop - _trackPadBottom;
    if (trackH <= 0) return;

    final totalCount = widget.totalCountNotifier?.value ?? 0;
    double ratio;
    double scrollFraction;

    if (totalCount > 0 && pos.maxScrollExtent > 0) {
      // حساب متوسط ارتفاع العنصر من الـ viewport الحالي
      final visibleItems = pos.viewportDimension /
          (pos.maxScrollExtent / (totalCount * 0.85)).clamp(40.0, 300.0);
      ratio = (visibleItems / totalCount).clamp(0.04, 1.0);
      // موضع السحب بناءً على النسبة الحقيقية من الكل
      final loadedFraction =
          (pos.maxScrollExtent + pos.viewportDimension) / (totalCount / visibleItems * pos.viewportDimension);
      scrollFraction =
          (pos.pixels / pos.maxScrollExtent * loadedFraction).clamp(0.0, 1.0);
    } else {
      ratio = pos.viewportDimension /
          (pos.maxScrollExtent + pos.viewportDimension);
      scrollFraction = pos.pixels / pos.maxScrollExtent;
    }

    final newThumbH = (trackH * ratio).clamp(_thumbMinHeight, trackH);
    final newThumbTop =
        _trackPadTop + scrollFraction * (trackH - newThumbH);

    if (_visible &&
        (_targetTop - newThumbTop).abs() < 0.5 &&
        (_targetHeight - newThumbH).abs() < 0.5) {
      _resetHideTimer();
      return;
    }

    final prevTop = _topAnimation.value;
    final prevHeight = _heightAnimation.value;

    _targetTop = newThumbTop;
    _targetHeight = newThumbH;

    // قفزة كبيرة = pagination جديد → تمهيد ناعم
    final bigJump = (_targetTop - prevTop).abs() > 30 ||
        (_targetHeight - prevHeight).abs() > 10;

    if (bigJump) {
      _topAnimation = Tween<double>(begin: prevTop, end: _targetTop).animate(
          CurvedAnimation(parent: _posController, curve: Curves.easeOut));
      _heightAnimation = Tween<double>(begin: prevHeight, end: _targetHeight)
          .animate(
              CurvedAnimation(parent: _posController, curve: Curves.easeOut));
      _posController
        ..reset()
        ..forward();
    } else {
      _thumbTop = _targetTop;
      _thumbHeight = _targetHeight;
      _topAnimation = AlwaysStoppedAnimation(_thumbTop);
      _heightAnimation = AlwaysStoppedAnimation(_thumbHeight);
      if (mounted) setState(() {});
    }

    if (!_visible) {
      _visible = true;
      _fadeController.forward();
    }

    _resetHideTimer();
  }

  void _hide() {
    if (!_visible) return;
    _fadeController.reverse().then((_) {
      if (mounted) setState(() => _visible = false);
    });
  }

  void _resetHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(milliseconds: 1500), _hide);
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();

    return FadeTransition(
      opacity: _fadeController,
      child: CustomPaint(
        painter: _ThumbPainter(
          color: widget.color,
          thumbTop: _topAnimation.value,
          thumbHeight: _heightAnimation.value,
          thumbWidth: _thumbWidth,
        ),
      ),
    );
  }
}

class _ThumbPainter extends CustomPainter {
  final Color color;
  final double thumbTop;
  final double thumbHeight;
  final double thumbWidth;

  const _ThumbPainter({
    required this.color,
    required this.thumbTop,
    required this.thumbHeight,
    required this.thumbWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, thumbTop, thumbWidth, thumbHeight),
      const Radius.circular(3),
    );
    canvas.drawRRect(rect, paint);
  }

  @override
  bool shouldRepaint(_ThumbPainter old) =>
      old.thumbTop != thumbTop ||
      old.thumbHeight != thumbHeight ||
      old.color != color;
}
