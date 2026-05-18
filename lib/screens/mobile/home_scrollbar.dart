// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:async';import 'package:flutter/material.dart';import 'package:sinan_note/models/note.dart';
// ارتفاع ثابت للعرض المطوي (padding 6*2 + card 60)
const double _kCompactItemH = 72.0;

class HomeScrollbar extends StatelessWidget {
  final ScrollController scrollController;
  final ValueNotifier<List<Note>> notesNotifier;
  final bool interactive;
  final ValueNotifier<int>? totalCountNotifier;
  final ValueNotifier<String>? viewTypeNotifier;
  final ValueNotifier<int>? visibleCountNotifier;

  const HomeScrollbar({
    super.key,
    required this.scrollController,
    required this.notesNotifier,
    this.interactive = true,
    this.totalCountNotifier,
    this.viewTypeNotifier,
    this.visibleCountNotifier,
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
          viewTypeNotifier: viewTypeNotifier,
          visibleCountNotifier: visibleCountNotifier,
        ),
      ),
    );
  }
}

class _ScrollThumb extends StatefulWidget {
  final ScrollController scrollController;
  final Color color;
  final ValueNotifier<int>? totalCountNotifier;
  final ValueNotifier<String>? viewTypeNotifier;
  final ValueNotifier<int>? visibleCountNotifier;

  const _ScrollThumb({
    required this.scrollController,
    required this.color,
    this.totalCountNotifier,
    this.viewTypeNotifier,
    this.visibleCountNotifier,
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

  // avgH محسوب مرة واحدة فقط لكل viewType
  double _cachedAvgH = 0;
  String _cachedViewType = '';

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
    widget.totalCountNotifier?.addListener(_onTotalCountChanged);
    widget.viewTypeNotifier?.addListener(_onViewTypeChanged);
    widget.visibleCountNotifier?.addListener(_onVisibleCountChanged);
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _update());
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
    widget.totalCountNotifier?.removeListener(_onTotalCountChanged);
    widget.viewTypeNotifier?.removeListener(_onViewTypeChanged);
    widget.visibleCountNotifier?.removeListener(_onVisibleCountChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onViewTypeChanged() {
    _cachedAvgH = 0;
    _cachedViewType = '';
    _update();
  }

  void _onVisibleCountChanged() {
    // تحميل صفحة جديدة → أعد حساب avgH من المحمّل الجديد
    _cachedAvgH = 0;
    _update(isTotalCountChange: true);
  }

  void _onTotalCountChanged() {
    _update(isTotalCountChange: true);
  }

  double _getAvgH(ScrollPosition pos, String viewType) {
    if (viewType == 'listCompact') return _kCompactItemH;
    if (_cachedAvgH > 0 && _cachedViewType == viewType) return _cachedAvgH;

    // visibleCount = عدد النوتات المحمّلة فعلاً في الـ list
    final visibleCount = widget.visibleCountNotifier?.value ?? 0;
    if (visibleCount > 0 && pos.maxScrollExtent > 0) {
      _cachedAvgH =
          (pos.maxScrollExtent + pos.viewportDimension) / visibleCount;
      _cachedViewType = viewType;
      return _cachedAvgH;
    }
    return _kCompactItemH;
  }

  void _update({bool isTotalCountChange = false}) {
    if (!mounted) return;
    if (WidgetsBinding.instance.buildOwner?.debugBuilding ?? false) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _update());
      return;
    }
    if (!widget.scrollController.hasClients) return;
    final pos = widget.scrollController.position;
    if (pos.maxScrollExtent <= 0) {
      _hide();
      return;
    }

    final trackH = pos.viewportDimension - _trackPadTop - _trackPadBottom;
    if (trackH <= 0) return;

    final totalCount = widget.totalCountNotifier?.value ?? 0;
    if (totalCount == 0) return;

    final viewType = widget.viewTypeNotifier?.value ?? 'listCompact';
    final avgH = _getAvgH(pos, viewType);
    final estimatedTotalH = avgH * totalCount;

    // حجم الـ thumb — بناءً على التقدير
    final ratio = (pos.viewportDimension / estimatedTotalH).clamp(0.04, 1.0);
    final newThumbH = (trackH * ratio).clamp(_thumbMinHeight, trackH);

    // موضع الـ thumb — بناءً على maxScrollExtent الحقيقي دائماً
    final scrollFraction = pos.maxScrollExtent > 0
        ? (pos.pixels / pos.maxScrollExtent).clamp(0.0, 1.0)
        : 0.0;
    final newThumbTop = _trackPadTop + scrollFraction * (trackH - newThumbH);

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

    // عند تحميل صفحة جديدة: لا animation — الـ thumb يبقى في مكانه
    // عند سكرول عادي وقفزة كبيرة: animation ناعم
    final bigJump = !isTotalCountChange &&
        ((_targetTop - prevTop).abs() > 30 ||
            (_targetHeight - prevHeight).abs() > 10);

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

