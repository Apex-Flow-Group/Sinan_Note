// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:async';

import 'package:apex_note/models/note.dart';
import 'package:flutter/material.dart';

class HomeScrollbar extends StatefulWidget {
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
  State<HomeScrollbar> createState() => _HomeScrollbarState();
}

class _HomeScrollbarState extends State<HomeScrollbar> {
  double _thumbTop = 0;
  double _thumbHeight = 40;
  bool _visible = false;
  Timer? _hideTimer;

  static const double _trackPadTop = 80.0;
  static const double _trackPadBottom = 60.0;
  static const double _thumbMinHeight = 32.0;
  static const double _width = 6.0;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_update);
    widget.notesNotifier.addListener(_update);
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    widget.scrollController.removeListener(_update);
    widget.notesNotifier.removeListener(_update);
    super.dispose();
  }

  void _update() {
    if (!widget.scrollController.hasClients) return;
    final pos = widget.scrollController.position;
    if (pos.maxScrollExtent <= 0) {
      if (_visible) setState(() => _visible = false);
      return;
    }

    final trackH = pos.viewportDimension - _trackPadTop - _trackPadBottom;
    if (trackH <= 0) return;

    final ratio = pos.viewportDimension / (pos.maxScrollExtent + pos.viewportDimension);
    final newThumbH = (trackH * ratio).clamp(_thumbMinHeight, trackH);
    final newThumbTop = _trackPadTop + (pos.pixels / pos.maxScrollExtent) * (trackH - newThumbH);

    if (!_visible || (_thumbTop - newThumbTop).abs() > 0.5 || (_thumbHeight - newThumbH).abs() > 0.5) {
      setState(() {
        _visible = true;
        _thumbTop = newThumbTop;
        _thumbHeight = newThumbH;
      });
    }

    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _visible = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary.withValues(alpha: 0.5);

    return Positioned(
      top: 0,
      bottom: 0,
      right: 2,
      width: _width + 4,
      child: IgnorePointer(
        ignoring: !widget.interactive,
        child: AnimatedOpacity(
          opacity: _visible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: Stack(
            children: [
              Positioned(
                top: _thumbTop,
                height: _thumbHeight,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
