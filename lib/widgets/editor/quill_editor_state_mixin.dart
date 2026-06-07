// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:sinan_note/core/utils/text_direction_utils.dart';

/// Mixin يحتوي على كل منطق الـ state الخاص بمحرر Quill:
/// - اتجاه النص (RTL/LTR)
/// - التشكيل
/// - اللصق
/// - أحداث لوحة المفاتيح
mixin QuillEditorStateMixin<T extends StatefulWidget> on State<T> {
  // ── يجب أن يوفرها الـ widget ──────────────────────────────
  QuillController get quillController;
  FocusNode get editorFocusNode;
  bool get isReadOnly;
  ValueChanged<double>? get onScroll;

  // ── الـ scroll controller يُعرَّف هنا ─────────────────────
  final stableScrollController = StableScrollController();
  final editorKey = GlobalKey<EditorState>();

  // ── flags ──────────────────────────────────────────────────
  bool isFormatting = false;
  bool isPasting = false;
  bool isKeyboardOpening = false;
  bool isLoading = true;
  bool isDirectionFormatting = false;
  bool isHandlingEnter = false;

  TextDirection textDirection = TextDirection.rtl;
  String lastPlainText = '';
  StreamSubscription? docChangeSub;

  // ── تشكيل ──────────────────────────────────────────────────
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

  // ── init / dispose ─────────────────────────────────────────
  void initEditorState() {
    quillController.readOnly = isReadOnly;
    final initialText = quillController.document.toPlainText();
    lastPlainText = initialText;
    textDirection = TextDirectionUtils.getDirection(initialText);
    quillController.addListener(onChanged);
    docChangeSub = quillController.document.changes.listen(onDocumentChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) isLoading = false;
      stableScrollController.addListener(onScrollChanged);
    });
  }

  void disposeEditorState() {
    quillController.removeListener(onChanged);
    stableScrollController.removeListener(onScrollChanged);
    docChangeSub?.cancel();
    stableScrollController.dispose();
  }

  // ── scroll ─────────────────────────────────────────────────
  void onScrollChanged() {
    if (!stableScrollController.hasClients) return;
    final offset = stableScrollController.offset.clamp(0.0, 120.0);
    onScroll?.call(offset / 120.0);
  }

  // ── document change ────────────────────────────────────────
  void onDocumentChange(DocChange change) {
    if (isFormatting || isPasting || isLoading || isDirectionFormatting) return;
    if (change.source != ChangeSource.local) return;

    final ops = change.change.toList();

    if (ops.any((op) => op.isDelete)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        fixDanglingTashkeel();
      });
      return;
    }

    final isOnlyNewline =
        ops.length <= 2 && ops.any((op) => op.isInsert && op.data == '\n');
    if (!isOnlyNewline) return;

    final plainText = quillController.document.toPlainText();
    final cursorOffset =
        quillController.selection.baseOffset.clamp(0, plainText.length);
    final prevLineOffset = cursorOffset > 0 ? cursorOffset - 1 : 0;
    final dir = getLineDirection(plainText, prevLineOffset);

    isHandlingEnter = true;
    // Apply direction immediately to prevent cursor disappearing on empty RTL lines
    if (!isFormatting && !isDirectionFormatting) {
      applyEnterDirection(dir);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      isHandlingEnter = false;
      if (!mounted) return;
      scrollToCursor();
    });
  }

  // ── tashkeel ───────────────────────────────────────────────
  void fixDanglingTashkeel() {
    final sel = quillController.selection;
    if (!sel.isCollapsed) return;
    final text = quillController.document.toPlainText();
    final pos = sel.baseOffset;
    if (pos == 0 || pos > text.length) return;
    if (!isTashkeel(text[pos - 1])) return;
    if (pos >= 2 && !isTashkeel(text[pos - 2])) return;
    quillController.replaceText(
      pos - 1,
      1,
      '',
      TextSelection.collapsed(offset: pos - 1),
    );
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
        tashkeelPos,
        1,
        '',
        TextSelection.collapsed(offset: tashkeelPos),
      );
      return true;
    }
    return false;
  }

  // ── direction ──────────────────────────────────────────────
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
    final lineStart = text.lastIndexOf('\n', offset > 0 ? offset - 1 : 0);
    return _getPrevNonEmptyLineDirFast(text, lineStart);
  }

  TextDirection _getPrevNonEmptyLineDirFast(String text, int lineStartIndex) {
    int end = lineStartIndex;
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

  void applyDirectionFormat(VoidCallback applyFn) {
    if (isFormatting || isDirectionFormatting) return;
    isFormatting = true;
    isDirectionFormatting = true;
    stableScrollController.freezed = true;
    applyFn();
    isFormatting = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      stableScrollController.freezed = false;
      isDirectionFormatting = false;
    });
  }

  void onChanged() {
    if (isFormatting ||
        isPasting ||
        isKeyboardOpening ||
        isDirectionFormatting ||
        isHandlingEnter) {
      return;
    }

    final plainText = quillController.document.toPlainText();
    if (plainText == lastPlainText) return;
    lastPlainText = plainText;

    final selection = quillController.selection;
    if (!selection.isValid || plainText.trim().isEmpty) return;

    final docLength = plainText.length;
    if (!selection.isCollapsed &&
        selection.start == 0 &&
        selection.end >= docLength - 1) {
      return;
    }

    final offset = selection.baseOffset.clamp(0, plainText.length);
    final lineStart = plainText.lastIndexOf('\n', offset > 0 ? offset - 1 : 0);
    final lineEnd = plainText.indexOf('\n', offset);
    final currentLine = plainText.substring(
      lineStart < 0 ? 0 : lineStart + 1,
      lineEnd < 0 ? plainText.length : lineEnd,
    );

    if (currentLine.isEmpty) {
      final prevDir = getPrevNonEmptyLineDirection(plainText, offset);
      if (textDirection != prevDir) setState(() => textDirection = prevDir);
      return;
    }

    final newDir = TextDirectionUtils.getDirection(currentLine);
    final effectiveDir = (currentLine.length == 1 &&
            newDir == TextDirection.rtl &&
            !RegExp(r'[\u0600-\u06FF]').hasMatch(currentLine))
        ? getPrevNonEmptyLineDirection(plainText, offset)
        : newDir;

    final isRtl = effectiveDir == TextDirection.rtl;
    // في Quill: direction:'rtl' يعني LTR (الاتجاه المعاكس للـ widget)، null يعني RTL
    // لذا currentIsRtl = true يعني الفقرة الحالية LTR، وليس RTL
    final currentAttr =
        quillController.getSelectionStyle().attributes['direction'];
    final currentIsRtl = currentAttr?.value == 'rtl';

    // currentIsRtl != !isRtl ↔ currentIsRtl == isRtl
    // أي: إذا كان الـ attribute الحالي لا يتطابق مع الاتجاه المطلوب → نُعيد التنسيق
    if (currentIsRtl != !isRtl) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || isFormatting || isDirectionFormatting) return;
        applyDirectionFormat(() {
          if (isRtl) {
            quillController.formatSelection(const DirectionAttribute(null));
            quillController.formatSelection(const AlignAttribute(null));
          } else {
            quillController.formatSelection(Attribute.rtl);
            quillController.formatSelection(const AlignAttribute(null));
          }
        });
      });
    }

    if (effectiveDir != textDirection) {
      setState(() => textDirection = effectiveDir);
    }
  }

  // ── paste ──────────────────────────────────────────────────
  Future<void> pastePlainText() async {
    isPasting = true;
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.isEmpty) {
      isPasting = false;
      return;
    }

    final sel = quillController.selection;
    final offset = sel.isCollapsed ? sel.extentOffset : sel.start;
    final deleteLen = sel.isCollapsed ? 0 : sel.end - sel.start;
    quillController.replaceText(offset, deleteLen, text, null);

    final lines = text.split('\n');
    int pos = offset;
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final isLast = i == lines.length - 1;
      final len = line.length;
      final isRtl =
          TextDirectionUtils.getDirection(line.isNotEmpty ? line : '') ==
              TextDirection.rtl;
      if (len > 0) {
        quillController.formatText(pos, len, const ColorAttribute(null));
        quillController.formatText(pos, len, const BackgroundAttribute(null));
        quillController.formatText(
            pos, len, Attribute.clone(Attribute.bold, null));
        quillController.formatText(
            pos, len, Attribute.clone(Attribute.italic, null));
        quillController.formatText(
            pos, len, Attribute.clone(Attribute.underline, null));
        quillController.formatText(pos, len, const SizeAttribute(null));
      }
      pos += len;
      if (!isLast) {
        quillController.formatText(pos, 1, const AlignAttribute(null));
        quillController.formatText(
          pos,
          1,
          isRtl ? const DirectionAttribute(null) : Attribute.rtl,
        );
        pos += 1;
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      isPasting = false;
      if (!stableScrollController.hasClients) return;
      final scrollPos = stableScrollController.position;
      if (scrollPos.pixels < scrollPos.maxScrollExtent - 100) return;
      stableScrollController.animateTo(
        scrollPos.maxScrollExtent,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
      );
    });
  }

  // ── scroll to cursor ───────────────────────────────────────
  void scrollToCursor() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !stableScrollController.hasClients) return;
      editorKey.currentState?.requestKeyboard();
    });
  }

  // ── keyboard ───────────────────────────────────────────────
  KeyEventResult handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.keyV &&
        HardwareKeyboard.instance.isControlPressed) {
      pastePlainText();
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
    final dir = getLineDirection(plainText, offset);
    isHandlingEnter = true;
    // Apply direction immediately to prevent cursor disappearing on empty RTL lines
    if (!isFormatting && !isDirectionFormatting) {
      applyEnterDirection(dir);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      isHandlingEnter = false;
      if (!mounted) return;
      scrollToCursor();
    });
  }
}

/// ScrollController يتجاهل animateTo أثناء تغيير الاتجاه
class StableScrollController extends ScrollController {
  bool freezed = false;

  @override
  Future<void> animateTo(double offset,
      {required Duration duration, required Curve curve}) {
    if (freezed) return Future.value();
    return super.animateTo(offset, duration: duration, curve: curve);
  }
}
