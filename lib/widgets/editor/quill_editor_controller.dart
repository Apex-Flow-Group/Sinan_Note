// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:async';import 'package:flutter/material.dart'; import 'package:flutter/services.dart'; import 'package:flutter_quill/flutter_quill.dart'; import 'package:flutter_quill/quill_delta.dart';import 'package:markdown/markdown.dart' as md; import 'package:sinan_note/core/utils/text_direction_utils.dart'; import 'package:sinan_note/widgets/editor/quill_editor_state_mixin.dart'; import 'package:sinan_note/widgets/editor/tear/tear.dart';
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
  bool _suppressBar = false;

  TextDirection textDirection = TextDirection.rtl;
  String _lastPlainText = '';
  StreamSubscription? _docChangeSub;

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
    _lastPlainText = initialText;
    textDirection = TextDirectionUtils.getDirection(initialText);

    quillController.addListener(onChanged);
    quillController.addListener(onSelectionChangedForBar);
    quillController.addListener(tearHandle.onSelectionChanged);
    focusNode.addListener(onFocusChanged);
    _docChangeSub = quillController.document.changes.listen(onDocumentChange);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      isLoading = false;
      scrollController.addListener(onScrollChanged);
    });
  }

  void dispose() {
    _suppressBar = true;
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
    if (isFormatting ||
        isPasting ||
        isLoading ||
        isDirectionFormatting ||
        isDraggingSelection) {
      return;
    }
    if (change.source != ChangeSource.local) return;

    if (!tearHandle.isDragging) tearHandle.onTextChanged();

    final ops = change.change.toList();
    if (ops.any((op) => op.isDelete)) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => fixDanglingTashkeel());
      return;
    }

    final isOnlyNewline =
        ops.length <= 2 && ops.any((op) => op.isInsert && op.data == '\n');
    if (!isOnlyNewline) return;

    final plainText = quillController.document.toPlainText();
    final cursorOffset =
        quillController.selection.baseOffset.clamp(0, plainText.length);

    // الـ cursor الآن في السطر الجديد الفارغ — نقرأ اتجاه السطر السابق
    // نجد بداية السطر السابق (قبل الـ \n الذي أُدرج للتو)
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      isHandlingEnter = false;
      if (isFormatting || isDirectionFormatting || isDraggingSelection) return;
      applyEnterDirection(dir);
      scrollToCursor();
    });
  }

  // ── onChanged ──────────────────────────────────────────────────────────────
  void onChanged() {
    if (isFormatting ||
        isPasting ||
        isKeyboardOpening ||
        isDirectionFormatting ||
        isHandlingEnter) {
      return;
    }

    final sel = quillController.selection;

    if (!sel.isCollapsed) {
      isDraggingSelection = true;
      return;
    }
    if (isDraggingSelection) {
      isDraggingSelection = false;
      return;
    }

    final plainText = quillController.document.toPlainText();
    if (plainText == _lastPlainText) return;
    _lastPlainText = plainText;

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
      if (textDirection != prevDir) {
        textDirection = prevDir;
        rebuild();
      }
      return;
    }

    final newDir = TextDirectionUtils.getDirection(currentLine);
    final hasExplicitDir = RegExp(r'[\u0600-\u06FF]').hasMatch(currentLine) ||
        RegExp(r'[a-zA-Z]').hasMatch(currentLine);
    final effectiveDir = !hasExplicitDir
        ? getPrevNonEmptyLineDirection(plainText, offset)
        : newDir;
    final isRtl = effectiveDir == TextDirection.rtl;
    final currentAttr =
        quillController.getSelectionStyle().attributes['direction'];
    final currentIsRtl = currentAttr?.value == 'rtl';

    if (hasExplicitDir && currentIsRtl != !isRtl) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (isFormatting || isDirectionFormatting || isDraggingSelection) {
          return;
        }
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
    final currentLineStart =
        text.lastIndexOf('\n', offset > 0 ? offset - 1 : 0);
    if (currentLineStart <= 0) return TextDirection.rtl;
    final prevLines = text.substring(0, currentLineStart).split('\n');
    for (int i = prevLines.length - 1; i >= 0; i--) {
      if (prevLines[i].trim().isNotEmpty) {
        return TextDirectionUtils.getDirection(prevLines[i]);
      }
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
  bool _looksLikeMarkdown(String text) {
    return RegExp(
      r'(^#{1,6} |\*\*|__| *[-*+] | *\d+\. |^> |```|`[^`])',
      multiLine: true,
    ).hasMatch(text);
  }

  Future<void> pastePlainText({bool markdownEnabled = false}) async {
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

    if (markdownEnabled && _looksLikeMarkdown(text)) {
      final mdDelta = MarkdownToDelta(
        markdownDocument: md.Document(encodeHtml: false),
      ).convert(text);

      // بناء delta للإدراج عند الـ offset
      final insertDelta = Delta();
      if (deleteLen > 0) {
        insertDelta
          ..retain(offset)
          ..delete(deleteLen);
      } else {
        insertDelta.retain(offset);
      }
      for (final op in mdDelta.toList()) {
        insertDelta.push(op);
      }

      quillController.compose(
        insertDelta,
        TextSelection.collapsed(offset: offset + mdDelta.length - 1),
        ChangeSource.local,
      );

      isPasting = false;
    } else {
      quillController.replaceText(offset, deleteLen, text, null);

      final lines = text.split('\n');
      int pos = offset;
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        final isLast = i == lines.length - 1;
        final len = line.length;
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
          final isRtl =
              TextDirectionUtils.getDirection(line.isNotEmpty ? line : '') ==
                  TextDirection.rtl;
          quillController.formatText(pos, 1, const AlignAttribute(null));
          quillController.formatText(
              pos, 1, isRtl ? const DirectionAttribute(null) : Attribute.rtl);
          pos += 1;
        }
      }
      isPasting = false;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;
      final p = scrollController.position;
      if (p.pixels < p.maxScrollExtent - 100) return;
      scrollController.animateTo(p.maxScrollExtent,
          duration: const Duration(milliseconds: 100), curve: Curves.easeOut);
    });
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      isHandlingEnter = false;
      if (isFormatting || isDirectionFormatting || isDraggingSelection) return;
      applyEnterDirection(dir);
      scrollToCursor();
    });
  }
}

