// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:async';

import 'package:apex_note/models/note.dart';
import 'package:flutter/material.dart';

class HomeScrollbar extends StatelessWidget {
  final ScrollController scrollController;
  final ValueNotifier<List<Note>> notesNotifier;
  final bool interactive;

  const HomeScrollbar({
    super.key,
    required this.scrollController,
    required this.notesNotifier,
    this.interactive = true,
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
        ),
      ),
    );
  }
}

class _ScrollThumb extends StatefulWidget {
  final ScrollController scrollController;
  final Color color;

  const _ScrollThumb({
    required this.scrollController,
    required this.color,
  });

  @override
  State<_ScrollThumb> createState() => _ScrollThumbState();
}

class _ScrollThumbState extends State<_ScrollThumb>
    with SingleTickerProviderStateMixin {
  static const double _trackPadTop = 80.0;
  static const double _trackPadBottom = 60.0;
  static const double _thumbMinHeight = 32.0;
  static const double _thumbWidth = 6.0;

  double _thumbTop = 0;
  double _thumbHeight = 40;
  bool _visible = false;
  Timer? _hideTimer;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fadeAnimation = _fadeController;
    widget.scrollController.addListener(_update);
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _fadeController.dispose();
    widget.scrollController.removeListener(_update);
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

    final ratio = pos.viewportDimension / (pos.maxScrollExtent + pos.viewportDimension);
    final newThumbH = (trackH * ratio).clamp(_thumbMinHeight, trackH);
    final newThumbTop = _trackPadTop +
        (pos.pixels / pos.maxScrollExtent) * (trackH - newThumbH);

    // تجاهل تغييرات أقل من 0.5px
    if (_visible &&
        (_thumbTop - newThumbTop).abs() < 0.5 &&
        (_thumbHeight - newThumbH).abs() < 0.5) {
      _resetHideTimer();
      return;
    }

    _thumbTop = newThumbTop;
    _thumbHeight = newThumbH;

    if (!_visible) {
      _visible = true;
      _fadeController.forward();
    }

    // setState صغير يؤثر فقط على هذا الـ widget
    if (mounted) setState(() {});
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
      opacity: _fadeAnimation,
      child: CustomPaint(
        painter: _ThumbPainter(
          color: widget.color,
          thumbTop: _thumbTop,
          thumbHeight: _thumbHeight,
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
