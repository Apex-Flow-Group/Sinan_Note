// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:sinan_note/widgets/editor/tear/tear_handle_widget.dart';

/// المنطق والتحكم في دمعة المؤشر المفرد
class CursorTearHandle {
  final QuillController controller;
  final GlobalKey<EditorState> editorKey;
  final Color Function() getMagnifierBgColor;

  OverlayEntry? _entry;
  Timer? _hideTimer;
  TextSelection? _lastSel;
  bool _dragging = false;
  bool _suppressRebuild = false;

  VoidCallback? onDragStarted;
  VoidCallback? onDragEnded;

  CursorTearHandle({
    required this.controller,
    required this.editorKey,
    required this.getMagnifierBgColor,
  });

  bool get isDragging => _dragging;

  void onTextChanged() {
    if (_dragging || _suppressRebuild) return;
    _forceHide();
  }

  void onSelectionChanged() {
    if (_dragging || _suppressRebuild) return;
    final sel = controller.selection;

    if (!sel.isCollapsed) {
      _lastSel = sel;
      _forceHide();
      return;
    }

    if (_lastSel != null &&
        _lastSel!.isCollapsed &&
        _lastSel!.baseOffset == sel.baseOffset &&
        _entry != null) {
      _lastSel = sel;
      _restartTimer();
      return;
    }

    _lastSel = sel;
    // تأخير العرض لما بعد اكتمال الـ layout حتى يكون موقع الكرسر محدّث
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // تحقق أن السيلكشن لم يتغير أثناء الانتظار
      if (_dragging || _suppressRebuild) return;
      final currentSel = controller.selection;
      if (currentSel != sel) return;
      _showAtCaret();
    });
  }

  void hide() {
    if (_dragging) return;
    _forceHide();
  }

  void forceHide() => _forceHide();

  void dispose() => _forceHide();

  void _forceHide() {
    _dragging = false;
    _suppressRebuild = false;
    _hideTimer?.cancel();
    _entry?.remove();
    _entry = null;
  }

  void _restartTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), _forceHide);
  }

  void _showAtCaret() {
    final state = editorKey.currentState;
    if (state == null) return;
    final sel = controller.selection;
    if (!sel.isCollapsed) return;

    Rect caretRect;
    try {
      caretRect = state.renderEditor
          .getLocalRectForCaret(TextPosition(offset: sel.baseOffset));
    } catch (_) {
      return;
    }

    final globalBottom = state.renderEditor
        .localToGlobal(Offset(caretRect.center.dx, caretRect.bottom));

    _hideTimer?.cancel();
    _entry?.remove();
    _entry = null;

    final ctx = editorKey.currentContext;
    if (ctx == null) return;

    _entry = OverlayEntry(
      builder: (_) => TearHandleWidget(
        initialPos: globalBottom,
        lineHeight: caretRect.height,
        controller: controller,
        editorKey: editorKey,
        bgColor: getMagnifierBgColor(),
        onTouchDown: () {
          _suppressRebuild = true;
          _hideTimer?.cancel();
        },
        onDragStart: () {
          _dragging = true;
          _suppressRebuild = true;
          _hideTimer?.cancel();
          onDragStarted?.call();
          final state = editorKey.currentState;
          if (state != null) state.cursorCont.suspended = true;
        },
        onDragEnd: () {
          _dragging = false;
          _suppressRebuild = false;
          onDragEnded?.call();
          final state = editorKey.currentState;
          if (state != null) state.cursorCont.suspended = false;
          WidgetsBinding.instance.addPostFrameCallback((_) => _showAtCaret());
        },
        onDismiss: _forceHide,
      ),
    );

    Overlay.of(ctx, rootOverlay: true).insert(_entry!);
    _restartTimer();
  }
}
