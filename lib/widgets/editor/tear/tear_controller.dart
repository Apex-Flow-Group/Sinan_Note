// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:sinan_note/widgets/editor/tear/tear_magnifier.dart';
import 'package:sinan_note/widgets/editor/tear/tear_painters.dart';

class TearController {
  TearController({
    required this.quillController,
    required this.getBgColor,
  });

  final QuillController quillController;
  final Color Function() getBgColor;

  VoidCallback? onDragStarted;
  VoidCallback? onDragEnded;

  GlobalKey<EditorState>? _editorKey;
  OverlayEntry? _entry;
  Timer? _timer;
  bool _dragging = false;

  bool get isDragging => _dragging;

  void updateEditorKey(GlobalKey<EditorState> key) => _editorKey = key;

  void showOnTap({required GlobalKey<EditorState> editorKey}) {
    updateEditorKey(editorKey);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_dragging) return;
      if (!quillController.selection.isCollapsed) return;
      _show();
    });
  }

  void onSelectionChanged() {
    if (_dragging) return;
    if (!quillController.selection.isCollapsed) _hide();
  }

  void onTextChanged() {
    if (_dragging) return;
    _hide();
  }

  void onTypingDone() {
    WidgetsBinding.instance.addPostFrameCallback((_) => onSelectionChanged());
  }

  void forceHide() => _hide();

  void dispose() {
    _timer?.cancel();
    _entry?.remove();
    _entry = null;
  }

  void _show() {
    final key = _editorKey;
    final state = key?.currentState;
    final ctx = key?.currentContext;
    if (state == null || ctx == null) return;

    final sel = quillController.selection;
    if (!sel.isCollapsed) return;

    Rect caretRect;
    try {
      caretRect = state.renderEditor
          .getLocalRectForCaret(TextPosition(offset: sel.baseOffset));
    } catch (_) {
      return;
    }

    final caretBottom = state.renderEditor
        .localToGlobal(Offset(caretRect.center.dx, caretRect.bottom));

    _timer?.cancel();
    _entry?.remove();
    _entry = OverlayEntry(
      builder: (_) => _TearWidget(
        initialPos: caretBottom,
        lineHeight: caretRect.height,
        quillController: quillController,
        getEditorKey: () => _editorKey,
        bgColor: getBgColor(),
        onDragStart: _onDragStart,
        onDragEnd: _onDragEnd,
        onDismiss: _hide,
      ),
    );

    Overlay.of(ctx, rootOverlay: true).insert(_entry!);
    _restartTimer();
  }

  void _hide() {
    _dragging = false;
    _timer?.cancel();
    _entry?.remove();
    _entry = null;
  }

  void _restartTimer() {
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 4), _hide);
  }

  void _onDragStart() {
    _dragging = true;
    _timer?.cancel();
    onDragStarted?.call();
  }

  void _onDragEnd() {
    _dragging = false;
    onDragEnded?.call();
    WidgetsBinding.instance.addPostFrameCallback((_) => _show());
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _TearWidget extends StatefulWidget {
  const _TearWidget({
    required this.initialPos,
    required this.lineHeight,
    required this.quillController,
    required this.getEditorKey,
    required this.bgColor,
    required this.onDragStart,
    required this.onDragEnd,
    required this.onDismiss,
  });

  final Offset initialPos;
  final double lineHeight;
  final QuillController quillController;
  final GlobalKey<EditorState>? Function() getEditorKey;
  final Color bgColor;
  final VoidCallback onDragStart;
  final VoidCallback onDragEnd;
  final VoidCallback onDismiss;

  @override
  State<_TearWidget> createState() => _TearWidgetState();
}

class _TearWidgetState extends State<_TearWidget>
    with SingleTickerProviderStateMixin {
  static const double _kW = 22.0;
  static const double _kH = 34.0;
  static const double _kHit = 48.0;

  late AnimationController _anim;
  late Animation<double> _scale;
  late Offset _pos;
  double _lineTop = 0;
  double _lineBottom = 0;
  bool _dragging = false;
  int _lastOffset = -1;
  int _lastDragMs = 0;

  late final ValueNotifier<({Offset pos, double lineTop, double lineBottom})>
      _magNotifier;

  @override
  void initState() {
    super.initState();
    _pos = widget.initialPos;
    _lineTop = _pos.dy - widget.lineHeight;
    _lineBottom = _pos.dy;
    _magNotifier = ValueNotifier((
      pos: _pos,
      lineTop: _lineTop,
      lineBottom: _lineBottom,
    ));
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _scale = CurvedAnimation(parent: _anim, curve: Curves.easeOutBack);
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    _magNotifier.dispose();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent e) {
    final tearCenterY = _pos.dy + _kH / 2;
    final dx = (e.position.dx - _pos.dx).abs();
    final dy = (e.position.dy - tearCenterY).abs();
    if (dx < _kHit / 2 && dy < _kHit / 2) {
      HapticFeedback.mediumImpact();
      widget.onDragStart();
      setState(() => _dragging = true);
      _magNotifier.value =
          (pos: _pos, lineTop: _lineTop, lineBottom: _lineBottom);
    }
  }

  void _updateDrag(Offset globalPos) {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastDragMs < 16) return;
    _lastDragMs = now;

    final state = widget.getEditorKey()?.currentState;
    if (state == null) return;

    RenderEditor re;
    try {
      re = state.renderEditor;
    } catch (_) {
      return;
    }

    final pos = re.getPositionForOffset(
        Offset(globalPos.dx, globalPos.dy - widget.lineHeight));

    if (pos.offset != _lastOffset) {
      _lastOffset = pos.offset;
      HapticFeedback.selectionClick();
      widget.quillController.updateSelection(
        TextSelection.collapsed(offset: pos.offset),
        ChangeSource.local,
      );
    }

    try {
      final r = re.getLocalRectForCaret(TextPosition(offset: pos.offset));
      _lineTop = re.localToGlobal(Offset(0, r.top)).dy;
      _lineBottom = re.localToGlobal(Offset(0, r.bottom)).dy;
      final caretX = re.localToGlobal(Offset(r.center.dx, 0)).dx;
      _pos = Offset(caretX, _lineBottom);

      final screenH = MediaQuery.of(context).size.height;
      final keyboardTop = screenH - MediaQuery.of(context).viewInsets.bottom;
      if (_pos.dy > keyboardTop) {
        widget.onDismiss();
        return;
      }

      if (!mounted) return;
      _magNotifier.value =
          (pos: _pos, lineTop: _lineTop, lineBottom: _lineBottom);
    } catch (_) {}
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
      onPointerDown: _onPointerDown,
      onPointerMove: (e) {
        if (_dragging) _updateDrag(e.position);
      },
      onPointerUp: (e) {
        if (_dragging) _endDrag();
      },
      onPointerCancel: (e) {
        if (_dragging) _endDrag();
      },
      child: ValueListenableBuilder(
        valueListenable: _magNotifier,
        builder: (_, v, child) => Stack(
          fit: StackFit.expand,
          children: [
            const SizedBox.expand(),
            if (_dragging)
              TearMagnifier(
                pos: v.pos,
                lineTop: v.lineTop,
                lineBottom: v.lineBottom,
                bgColor: widget.bgColor,
              ),
            Positioned(
              left: v.pos.dx - _kHit / 2,
              top: v.pos.dy - 2,
              child: child!,
            ),
          ],
        ),
        child: SizedBox(
          width: _kHit,
          height: _kHit,
          child: Center(
            child: ScaleTransition(
              scale: _scale,
              child: CustomPaint(
                painter: TearPainter(color: color),
                size: const Size(_kW, _kH),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
