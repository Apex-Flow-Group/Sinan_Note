// Copyright © 2025 Apex Flow Group. All rights reserved.


import 'package:flutter/material.dart';


class ResizableDivider extends StatefulWidget {
  final ValueChanged<double> onDrag;
  final VoidCallback onDragEnd;

  const ResizableDivider({
    super.key,
    required this.onDrag,
    required this.onDragEnd,
  });

  @override
  State<ResizableDivider> createState() => _ResizableDividerState();
}

class _ResizableDividerState extends State<ResizableDivider> {
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragStart: (_) => setState(() => _dragging = true),
      onHorizontalDragUpdate: (d) {
        // عكس اتجاه السحب في RTL ليتوافق مع الاتجاه المنطقي
        final isRtl = Directionality.of(context) == TextDirection.rtl;
        final dx = isRtl ? -d.delta.dx : d.delta.dx;
        widget.onDrag(dx);
      },
      onHorizontalDragEnd: (_) {
        setState(() => _dragging = false);
        widget.onDragEnd();
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeColumn,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 20,
          color: _dragging
              ? Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withValues(alpha: 0.3)
              : Colors.transparent,
          child: Center(
            child: Icon(
              Icons.drag_indicator,
              size: 20,
              color: _dragging
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
        ),
      ),
    );
  }
}

