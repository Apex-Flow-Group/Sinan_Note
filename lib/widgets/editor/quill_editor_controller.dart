// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:sinan_note/core/utils/text_direction_utils.dart';
import 'package:sinan_note/widgets/editor/paste_handler.dart';
import 'package:sinan_note/widgets/editor/quill_editor_state_mixin.dart';
import 'package:sinan_note/widgets/editor/tear/tear.dart';

class QuillEditorController {
  final QuillController quillController;
  final FocusNode focusNode;
  final ValueNotifier<bool> selectionBarActive;
  final Color Function() getNoteColor;
  final ValueChanged<double>? onScroll;
  final VoidCallback rebuild; // setState del widget

  final scrollController = StableScrollController();
  final editorKey = GlobalKey<EditorState>();
  late final CursorTearHandle tearHandle;

  // ── flags ──────────────────────────────────────────────────────────────────
  bool isFormatting = false;
  bool isPasting = false;
  bool isKeyboardOpening = false;
  bool isLoading = true;
  bool isDirectionFormatting = false;
  bool isHandlingEnter = false;
  bool isDraggingSelection = false;
  bool isDraggingTear = false;
  bool _suppressBar = false;

  TextDirection textDirection = TextDirection.rtl;
  StreamSubscription? _docChangeSub;
  Timer? _onChangedDebounce;

  // ── tashkeel ───────────────────────────────────────────────────────────────
  static const _harakat = {
    '\u064B',
    '\u064C',
    '\u064D',
    '\u064E',
    '\u064F',
    '\u0650',
    '\u0652',
    '\u0653',
    '\u0654',
    '\u0655',
    '\u0656',
    '\u0657',
    '\u0670',
  };
  static const _shadda = '\u0651';
  static bool isTashkeel(String ch) => _harakat.contains(ch) || ch == _shadda;

  QuillEditorController({
    required this.quillController,
    required this.focusNode,
    required this.selectionBarActive,
    required this.getNoteColor,
    required this.rebuild,
    this.onScroll,
  }) {
    tearHandle = CursorTearHandle(
      controller: quillController,
      editorKey: editorKey,
      getMagnifierBgColor: getNoteColor,
    );
  }

  // ── init / dispose ─────────────────────────────────────────────────────────
  void init(bool readOnly) {
    quillController.readOnly = readOnly;
    final initialText = quillController.document.toPlainText();
    textDirection = TextDirectionUtils.getDirection(initialText);

    quillController.addListener(onChanged);
    quillController.addListener(onSelectionChangedForBar);
    quillController.addListener(tearHandle.onSelectionChanged);
    focusNode.addListener(onFocusChanged);
    _docChangeSub = quillController.document.changes.listen(onDocumentChange);

    tearHandle.onDragStarted = () => isDraggingTear = true;
    tearHandle.onDragEnded = () {
      isDraggingTear = false;
      // نعالج الاتجاه مرة واحدة بعد انتهاء السحب
      _processOnChanged();
    };

    WidgetsBinding.instance.addPostFrameCallback((_) {
      isLoading = false;
      scrollController.addListener(onScrollChanged);
    });
  }

  void dispose() {
    _suppressBar = true;
    _onChangedDebounce?.cancel();
    selectionBarActive.value = false;
    tearHandle.dispose();
    focusNode.removeListener(onFocusChanged);
    quillController.removeListener(onChanged);
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
    if (!tearHandle.isDragging) tearHandle.hide();
    final offset = scrollController.offset.clamp(0.0, 120.0);
    onScroll?.call(offset / 120.0);
  }

  void onFocusChanged() {
    if (!focusNode.hasFocus) tearHandle.forceHide();
  }

  void scrollToCursor() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        editorKey.currentState?.requestKeyboard();
      }
    });
  }

  // ── document change ────────────────────────────────────────────────────────
  void onDocumentChange(DocChange change) {
    if (isLoading || isDraggingTear) return;
    if (change.source != ChangeSource.local) return;

    if (!tearHandle.isDragging) tearHandle.onTextChanged();

    final ops = change.change.toList();
    if (ops.any((op) => op.isDelete)) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => fixDanglingTashkeel());
      return;
    }

    // تطبيق اتجاه السطر الجديد عند Enter فقط
    final isOnlyNewline =
        ops.length <= 2 && ops.any((op) => op.isInsert && op.data == '\n');
    if (!isOnlyNewline) return;

    // إذا كنا في قائمة — ورّث الاتجاه من الـ block الحالي بدون إعادة حساب
    final currentAttrs = quillController.getSelectionStyle().attributes;
    final isList = currentAttrs['list'] != null;
    if (isList) {
      isHandlingEnter = true;
      // فقط نُعيد تطبيق الاتجاه الحالي للقائمة (ورث تلقائياً)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        isHandlingEnter = false;
        scrollToCursor();
      });
      return;
    }

    final plainText = quillController.document.toPlainText();
    final cursorOffset =
        quillController.selection.baseOffset.clamp(0, plainText.length);

    final newlinePos = cursorOffset > 0 ? cursorOffset - 1 : 0;
    final prevLineStart =
        newlinePos > 0 ? plainText.lastIndexOf('\n', newlinePos - 1) : -1;
    final prevLine = plainText.substring(
      prevLineStart < 0 ? 0 : prevLineStart + 1,
      newlinePos,
    );
    final dir = prevLine.trim().isEmpty
        ? getPrevNonEmptyLineDirection(plainText, newlinePos)
        : TextDirectionUtils.getDirection(prevLine);

    isHandlingEnter = true;
    if (!isFormatting && !isDirectionFormatting && !isDraggingSelection) {
      applyEnterDirection(dir);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      isHandlingEnter = false;
      scrollToCursor();
    });
  }

  // ── onChanged ──────────────────────────────────────────────────────────────
  void onChanged() {
    if (isFormatting ||
        isPasting ||
        isKeyboardOpening ||
        isDirectionFormatting ||
        isHandlingEnter ||
        isDraggingSelection) {
      return;
    }
    _onChangedDebounce?.cancel();
    _onChangedDebounce =
        Timer(const Duration(milliseconds: 50), _processOnChanged);
  }

  void _processOnChanged() {
    if (isFormatting || isPasting || isDirectionFormatting || isHandlingEnter) {
      return;
    }

    final plainText = quillController.document.toPlainText();

    final selection = quillController.selection;
    if (!selection.isValid || plainText.trim().isEmpty) return;

    final offset = selection.baseOffset.clamp(0, plainText.length);
    final lineStart = plainText.lastIndexOf('\n', offset > 0 ? offset - 1 : 0);
    final lineEnd = plainText.indexOf('\n', offset);
    final currentLine = plainText.substring(
      lineStart < 0 ? 0 : lineStart + 1,
      lineEnd < 0 ? plainText.length : lineEnd,
    );

    // إذا كان الـ block قائمة (list) — لا نتدخل في اتجاهه
    // الاتجاه يُحدد عند التحميل بـ fixDeltaDirections ويثبت لكل القائمة
    final blockAttrs = quillController.getSelectionStyle().attributes;
    final isList = blockAttrs['list'] != null;
    if (isList) {
      // فقط نحدّث textDirection للـ widget بناءً على الـ attribute الموجود
      final currentAttr = blockAttrs['direction'];
      final blockIsLtr = currentAttr?.value == 'rtl';
      final blockDir = blockIsLtr ? TextDirection.ltr : TextDirection.rtl;
      if (blockDir != textDirection) {
        textDirection = blockDir;
        rebuild();
      }
      return;
    }

    // اتجاه السطر الحالي
    final effectiveDir = currentLine.trim().isEmpty
        ? _getPrevNonEmptyLineDirFast(plainText, lineStart)
        : TextDirectionUtils.getDirection(currentLine);

    final isRtl = effectiveDir == TextDirection.rtl;
    final currentAttr = blockAttrs['direction'];
    final currentIsLtr = currentAttr?.value == 'rtl';

    // طبّق فقط إذا يوجد حرف صريح (عربي أو إنجليزي) في السطر
    final hasExplicitDir =
        RegExp(r'[a-zA-Z\u0600-\u06FF]').hasMatch(currentLine);
    if (hasExplicitDir && currentIsLtr == isRtl) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (isFormatting || isDirectionFormatting || isDraggingSelection) {
          return;
        }
        applyDirectionFormat(() {
          if (isRtl) {
            quillController.formatSelection(const DirectionAttribute(null));
          } else {
            quillController.formatSelection(Attribute.rtl);
          }
          quillController.formatSelection(const AlignAttribute(null));
        });
      });
    }

    if (effectiveDir != textDirection) {
      textDirection = effectiveDir;
      rebuild();
    }
  }

  // ── direction ──────────────────────────────────────────────────────────────
  TextDirection getLineDirection(String text, int offset) {
    final lineStart = text.lastIndexOf('\n', offset > 0 ? offset - 1 : 0);
    final lineEnd = text.indexOf('\n', offset);
    final line = text.substring(
      lineStart < 0 ? 0 : lineStart + 1,
      lineEnd < 0 ? text.length : lineEnd,
    );
    if (line.trim().isEmpty) return getPrevNonEmptyLineDirection(text, offset);
    return TextDirectionUtils.getDirection(line);
  }

  TextDirection getPrevNonEmptyLineDirection(String text, int offset) {
    return _getPrevNonEmptyLineDirFast(
        text, text.lastIndexOf('\n', offset > 0 ? offset - 1 : 0));
  }

  /// نسخة سريعة — تمشي للخلف بدون split
  TextDirection _getPrevNonEmptyLineDirFast(String text, int lineStartIndex) {
    int end = lineStartIndex; // نهاية السطر السابق (الـ \n)
    while (end > 0) {
      final start = text.lastIndexOf('\n', end - 1);
      final line = text.substring(start < 0 ? 0 : start + 1, end);
      if (line.trim().isNotEmpty) {
        return TextDirectionUtils.getDirection(line);
      }
      end = start < 0 ? 0 : start;
      if (start < 0) break;
    }
    return TextDirection.rtl;
  }

  void applyEnterDirection(TextDirection dir) {
    applyDirectionFormat(() {
      if (dir == TextDirection.ltr) {
        quillController.formatSelection(Attribute.rtl);
      } else {
        quillController.formatSelection(const DirectionAttribute(null));
      }
      quillController.formatSelection(const AlignAttribute(null));
    });
  }

  void applyDirectionFormat(VoidCallback fn) {
    if (isFormatting || isDirectionFormatting) return;
    isFormatting = true;
    isDirectionFormatting = true;
    scrollController.freezed = true;
    fn();
    isFormatting = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollController.freezed = false;
      isDirectionFormatting = false;
    });
  }

  // ── tashkeel ───────────────────────────────────────────────────────────────
  void fixDanglingTashkeel() {
    final sel = quillController.selection;
    if (!sel.isCollapsed) return;
    final text = quillController.document.toPlainText();
    final pos = sel.baseOffset;
    if (pos == 0 || pos > text.length) return;
    if (!isTashkeel(text[pos - 1])) return;
    if (pos >= 2 && !isTashkeel(text[pos - 2])) return;
    quillController.replaceText(
        pos - 1, 1, '', TextSelection.collapsed(offset: pos - 1));
  }

  bool deleteWithTashkeelAwareness() {
    final sel = quillController.selection;
    if (!sel.isCollapsed || sel.baseOffset == 0) return false;
    final text = quillController.document.toPlainText();
    final pos = sel.baseOffset;
    if (pos > text.length) return false;

    int start = pos - 1;
    while (start > 0 && isTashkeel(text[start])) {
      start--;
    }

    final hasTashkeel =
        (pos - start) > 1 || (pos - start == 1 && isTashkeel(text[start]));
    if (!hasTashkeel) return false;

    int tashkeelPos = pos - 1;
    while (tashkeelPos > start && !isTashkeel(text[tashkeelPos])) {
      tashkeelPos--;
    }

    if (isTashkeel(text[tashkeelPos])) {
      quillController.replaceText(
          tashkeelPos, 1, '', TextSelection.collapsed(offset: tashkeelPos));
      return true;
    }
    return false;
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
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut);
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
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      handleEnterKey();
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      return deleteWithTashkeelAwareness()
          ? KeyEventResult.handled
          : KeyEventResult.ignored;
    }
    return KeyEventResult.ignored;
  }

  void handleEnterKey() {
    final plainText = quillController.document.toPlainText();
    final offset =
        quillController.selection.baseOffset.clamp(0, plainText.length);
    // نقرأ اتجاه السطر الحالي (قبل Enter) — نفس منطق onDocumentChange
    final lineStart = offset > 0 ? plainText.lastIndexOf('\n', offset - 1) : -1;
    final lineEnd = plainText.indexOf('\n', offset);
    final currentLine = plainText.substring(
      lineStart < 0 ? 0 : lineStart + 1,
      lineEnd < 0 ? plainText.length : lineEnd,
    );
    final dir = currentLine.trim().isEmpty
        ? getPrevNonEmptyLineDirection(plainText, offset)
        : TextDirectionUtils.getDirection(currentLine);
    isHandlingEnter = true;
    // Apply direction immediately to prevent cursor disappearing on empty RTL lines
    if (!isFormatting && !isDirectionFormatting && !isDraggingSelection) {
      applyEnterDirection(dir);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      isHandlingEnter = false;
      scrollToCursor();
    });
  }
}
