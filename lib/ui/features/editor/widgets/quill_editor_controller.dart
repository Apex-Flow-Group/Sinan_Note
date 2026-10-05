// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:sinan_note/ui/core/input/paste_handler.dart';
import 'package:sinan_note/ui/features/editor/widgets/tear/tear.dart';

class QuillEditorController {
  final QuillController quillController;
  final FocusNode focusNode;
  final ValueNotifier<bool> selectionBarActive;
  final Color Function() getNoteColor;
  final ValueChanged<double>? onScroll;
  final VoidCallback rebuild;
  final GlobalKey<EditorState>? externalEditorKey;

  late final GlobalKey<EditorState> editorKey;
  late final TearController tearHandle;
  final scrollController = ScrollController();

  // ── flags ──────────────────────────────────────────────────────────────────
  bool isPasting = false;
  bool isKeyboardOpening = false;
  bool isLoading = true;
  bool isDraggingSelection = false;
  bool isDraggingTear = false;
  bool _suppressBar = false;

  StreamSubscription? _docChangeSub;

  QuillEditorController({
    required this.quillController,
    required this.focusNode,
    required this.selectionBarActive,
    required this.getNoteColor,
    required this.rebuild,
    this.onScroll,
    this.externalEditorKey,
  }) {
    editorKey = externalEditorKey ?? GlobalKey<EditorState>();
    tearHandle = TearController(
      quillController: quillController,
      getBgColor: getNoteColor,
    );
  }

  // ── init / dispose ─────────────────────────────────────────────────────────
  void init(bool readOnly) {
    quillController.readOnly = readOnly;
    quillController.addListener(onSelectionChangedForBar);
    focusNode.addListener(onFocusChanged);
    _docChangeSub = quillController.document.changes.listen(onDocumentChange);

    // لا نُسجّل tearHandle.onSelectionChanged هنا —
    // editorKey لم يُربط بعد. نُسجّله بعد أول build عبر didFirstBuild()
    tearHandle.onDragStarted = () => isDraggingTear = true;
    tearHandle.onDragEnded = () => isDraggingTear = false;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      isLoading = false;
      scrollController.addListener(onScrollChanged);
    });
  }

  /// يُستدعى من QuillEditorWidget بعد أول build — الـ editorKey جاهز
  void didFirstBuild() {
    tearHandle.updateEditorKey(editorKey);
    quillController.addListener(tearHandle.onSelectionChanged);
  }

  void dispose() {
    _suppressBar = true;
    selectionBarActive.value = false;
    tearHandle.dispose();
    focusNode.removeListener(onFocusChanged);
    quillController.removeListener(onSelectionChangedForBar);
    quillController.removeListener(tearHandle.onSelectionChanged);
    scrollController.removeListener(onScrollChanged);
    _docChangeSub?.cancel();
    scrollController.dispose();
  }

  void updateReadOnly(bool readOnly) {
    quillController.readOnly = readOnly;
  }

  // ── selection bar ──────────────────────────────────────────────────────────
  void showSelectionBar() {
    if (_suppressBar || selectionBarActive.value) return;
    selectionBarActive.value = true;
  }

  void hideSelectionBar() {
    _suppressBar = true;
    selectionBarActive.value = false;
    WidgetsBinding.instance.addPostFrameCallback((_) => _suppressBar = false);
  }

  void onSelectionChangedForBar() {
    if (!selectionBarActive.value || isDraggingSelection) return;
    final sel = quillController.selection;
    if (sel.isCollapsed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (selectionBarActive.value && quillController.selection.isCollapsed) {
          selectionBarActive.value = false;
        }
      });
    }
  }

  // ── scroll ─────────────────────────────────────────────────────────────────
  void onScrollChanged() {
    if (!scrollController.hasClients) return;
    final offset = scrollController.offset.clamp(0.0, 120.0);
    onScroll?.call(offset / 120.0);
    // أخفِ الدمعة عند أي scroll يدوي — أبسط وأصح من تتبع الموضع
    if (!tearHandle.isDragging) {
      tearHandle.forceHide();
    }
  }

  void onFocusChanged() {
    if (!focusNode.hasFocus) {
      if (tearHandle.isDragging) {
        focusNode.requestFocus();
      } else {
        tearHandle.forceHide();
      }
    } else {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => tearHandle.onSelectionChanged());
    }
  }

  void scrollToCursor() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = editorKey.currentState;
      if (state == null || !scrollController.hasClients) return;
      final sel = quillController.selection;
      if (!sel.isCollapsed) return;
      try {
        final caretRect = state.renderEditor
            .getLocalRectForCaret(TextPosition(offset: sel.baseOffset));
        final caretGlobalY =
            state.renderEditor.localToGlobal(caretRect.bottomLeft).dy;
        final viewportH = scrollController.position.viewportDimension;
        final currentScroll = scrollController.offset;
        final targetScroll = currentScroll + caretGlobalY - viewportH * 0.75;
        if (targetScroll > currentScroll + 4) {
          scrollController.animateTo(
            targetScroll.clamp(0.0, scrollController.position.maxScrollExtent),
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
          );
        }
      } catch (_) {}
    });
  }

  // ── document change ────────────────────────────────────────────────────────
  void onDocumentChange(DocChange change) {
    if (isLoading || tearHandle.isDragging) return;
    if (change.source != ChangeSource.local) return;

    final ops = change.change.toList();

    // Enter فقط — نتحقق مبكراً لنتجنب إخفاء الدمعة ثم إعادتها
    final isOnlyNewline =
        ops.length <= 2 && ops.any((op) => op.isInsert && op.data == '\n');

    if (!isPasting) {
      if (!isOnlyNewline) {
        // كتابة عادية أو حذف — أخفِ الدمعة، ستعود عبر onTypingDone
        tearHandle.onTextChanged();
      }
      WidgetsBinding.instance
          .addPostFrameCallback((_) => tearHandle.onTypingDone());
    }

    if (ops.any((op) => op.isDelete)) return;

    if (!isOnlyNewline) return;

    // سطر جديد: الدمعة تتبع المؤشر بعد استقراره
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollToCursor();
      tearHandle.showOnTap(editorKey: editorKey);
    });
  }

  // ── paste ──────────────────────────────────────────────────────────────────
  Future<void> pastePlainText({bool markdownEnabled = false}) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.isEmpty) return;

    isPasting = true;
    quillController.readOnly = true;
    SystemChannels.textInput.invokeMethod('TextInput.hide');
    rebuild();

    final sel = quillController.selection;
    final offset = sel.isCollapsed ? sel.extentOffset : sel.start;
    final deleteLen = sel.isCollapsed ? 0 : sel.end - sel.start;

    try {
      final pasteDelta = await buildDeltaInIsolate(text);

      final insertDelta = Delta();
      if (offset > 0) insertDelta.retain(offset);
      if (deleteLen > 0) insertDelta.delete(deleteLen);
      for (final op in pasteDelta.toList()) {
        // نتجاهل الـ trailing newline الذي يضيفه Document
        if (op.isInsert) insertDelta.push(op);
      }

      quillController.compose(
        insertDelta,
        TextSelection.collapsed(offset: offset + text.length - deleteLen),
        ChangeSource.local,
      );
    } finally {
      isPasting = false;
      quillController.readOnly = false;
      rebuild();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!scrollController.hasClients) return;
        final p = scrollController.position;
        if (p.pixels < p.maxScrollExtent - 100) return;
        scrollController.animateTo(p.maxScrollExtent,
            duration: const Duration(milliseconds: 100), curve: Curves.easeOut);
      });
    }
  }

  // ── keyboard ───────────────────────────────────────────────────────────────
  KeyEventResult handleKeyEvent(KeyEvent event,
      {bool markdownEnabled = false}) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.keyV &&
        HardwareKeyboard.instance.isControlPressed) {
      pastePlainText(markdownEnabled: markdownEnabled);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }
}
