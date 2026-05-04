// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/widgets/editor/tear/tear_magnifier.dart';
import 'package:apex_note/widgets/editor/tear/tear_painters.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';

class TearHandleWidget extends StatefulWidget {
  const TearHandleWidget({
    super.key,
    required this.initialPos,
    required this.lineHeight,
    required this.controller,
    required this.editorKey,
    required this.bgColor,
    required this.onTouchDown,
    required this.onDragStart,
    required this.onDragEnd,
    required this.onDismiss,
  });

  final Offset initialPos;
  final double lineHeight;
  final QuillController controller;
  final GlobalKey<EditorState> editorKey;
  final Color bgColor;
  final VoidCallback onTouchDown;
  final VoidCallback onDragStart;
  final VoidCallback onDragEnd;
  final VoidCallback onDismiss;

  @override
  State<TearHandleWidget> createState() => _TearHandleWidgetState();
}

class _TearHandleWidgetState extends State<TearHandleWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _scale;

  late Offset _pos;
  double _lineTop = 0;
  double _lineBottom = 0;
  bool _dragging = false;
  int _lastOffset = -1;
  static const double _kHandleW = 22.0;
  static const double _kHandleH = 34.0;
  static const double _kHit = 48.0;

  @override
  void initState() {
    super.initState();
    _pos = widget.initialPos;
    _lineTop = _pos.dy - widget.lineHeight;
    _lineBottom = _pos.dy;

    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _scale = CurvedAnimation(parent: _anim, curve: Curves.easeOutBack);
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _startDrag(Offset globalPos) {
    HapticFeedback.mediumImpact();
    widget.onDragStart();
    _anim.value = 1.0;
    setState(() => _dragging = true);
  }

  void _updateDrag(Offset globalPos) {
    final state = widget.editorKey.currentState;
    if (state == null) return;

    RenderEditor re;
    try {
      re = state.renderEditor;
    } catch (_) {
      return;
    }
    final local = re.globalToLocal(globalPos);
    final lineH = widget.lineHeight;
    final scrollOffset = re.offset?.pixels ?? 0.0;
    final viewportDy = local.dy - scrollOffset;
    final lineIndex = (viewportDy / lineH).floor();
    final targetLocal = Offset(local.dx, lineIndex * lineH + lineH / 2);
    final pos = re.getPositionForOffset(targetLocal);

    if (pos.offset != _lastOffset) {
      _lastOffset = pos.offset;
      HapticFeedback.selectionClick();
    }

    try {
      final r = re.getLocalRectForCaret(TextPosition(offset: pos.offset));
      _lineTop = re.localToGlobal(Offset(0, r.top)).dy;
      _lineBottom = re.localToGlobal(Offset(0, r.bottom)).dy;
      final caretGlobalX = re.localToGlobal(Offset(r.center.dx, 0)).dx;
      final newPos = Offset(caretGlobalX, _lineBottom);

      // أخفِ الدمعة إذا خرج الكرسر عن المنطقة المرئية (تحت الكيبورد)
      final screenH = MediaQuery.of(context).size.height;
      final keyboardTop = screenH - MediaQuery.of(context).viewInsets.bottom;
      if (newPos.dy > keyboardTop) {
        widget.onDismiss();
        return;
      }

      if (!mounted) return;
      setState(() => _pos = newPos);
    } catch (_) {}

    widget.controller.updateSelection(
      TextSelection.collapsed(offset: pos.offset),
      ChangeSource.local,
    );
  }

  void _endDrag() {
    if (!mounted) return;
    setState(() => _dragging = false);
    widget.onDragEnd();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return Listener(
      behavior:
          _dragging ? HitTestBehavior.opaque : HitTestBehavior.translucent,
      onPointerDown: (e) {
        final tearCenterY = _pos.dy + _kHandleH / 2;
        final dx = e.position.dx - _pos.dx;
        final dy = e.position.dy - tearCenterY;
        if (dx.abs() < _kHit / 2 && dy.abs() < _kHit / 2) {
          widget.onTouchDown();
          _startDrag(e.position);
        }
      },
      onPointerMove: (e) {
        if (_dragging) _updateDrag(e.position);
      },
      onPointerUp: (e) {
        if (_dragging) _endDrag();
      },
      onPointerCancel: (e) {
        if (_dragging) _endDrag();
      },
      child: Stack(
        children: [
          if (_dragging)
            TearMagnifier(
              pos: _pos,
              lineTop: _lineTop,
              lineBottom: _lineBottom,
              bgColor: widget.bgColor,
            ),
          Positioned(
            left: _pos.dx - _kHit / 2,
            top: _pos.dy - 2,
            child: SizedBox(
              width: _kHit,
              height: _kHit,
              child: Center(
                child: ScaleTransition(
                  scale: _scale,
                  alignment: Alignment.center,
                  child: CustomPaint(
                    painter: TearPainter(color: color),
                    size: const Size(_kHandleW, _kHandleH),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
