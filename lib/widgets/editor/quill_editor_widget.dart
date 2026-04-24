// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:async';

import 'package:apex_note/core/constants/app_text_styles.dart';
import 'package:apex_note/core/utils/text_direction_utils.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';

/// ScrollController يتجاهل animateTo أثناء تغيير الاتجاه
class _StableScrollController extends ScrollController {
  bool freezed = false;

  @override
  Future<void> animateTo(double offset,
      {required Duration duration, required Curve curve}) {
    if (freezed) return Future.value();
    return super.animateTo(offset, duration: duration, curve: curve);
  }
}

/// Rich text editor widget powered by flutter_quill
class QuillEditorWidget extends StatefulWidget {
  final QuillController quillController;
  final FocusNode focusNode;
  final Color textColor;
  final Color hintColor;
  final double fontSize;
  final double sidePadding;
  final double totalBottomSpace;
  final bool autoFocus;
  final bool readOnly;
  final ValueChanged<double>? onScroll;

  const QuillEditorWidget({
    super.key,
    required this.quillController,
    required this.focusNode,
    required this.textColor,
    required this.hintColor,
    required this.fontSize,
    required this.sidePadding,
    required this.totalBottomSpace,
    this.autoFocus = false,
    this.readOnly = false,
    this.onScroll,
  });

  @override
  State<QuillEditorWidget> createState() => _QuillEditorWidgetState();
}

class _QuillEditorWidgetState extends State<QuillEditorWidget> {
  TextDirection _textDirection = TextDirection.rtl;
  final _StableScrollController _scrollController = _StableScrollController();
  final GlobalKey<EditorState> _editorKey = GlobalKey<EditorState>();
  bool _isFormatting = false;
  bool _isPasting = false;
  bool _isKeyboardOpening = false;
  bool _isLoading = true; // يمنع _onDocumentChange أثناء تحميل النوتة
  bool _isDirectionFormatting = false;
  bool _isHandlingEnter = false;
  String? _cachedFontFamily;

  /// يستخرج اتجاه السطر الذي يقع فيه offset
  TextDirection _getLineDirection(String text, int offset) {
    final lineStart = text.lastIndexOf('\n', offset > 0 ? offset - 1 : 0);
    final lineEnd = text.indexOf('\n', offset);
    final line = text.substring(
      lineStart < 0 ? 0 : lineStart + 1,
      lineEnd < 0 ? text.length : lineEnd,
    );
    if (line.trim().isEmpty) {
      return _getPrevNonEmptyLineDirection(text, offset);
    }
    return TextDirectionUtils.getDirection(line);
  }

  void _applyEnterDirection(TextDirection dir) {
    _applyDirectionFormat(() {
      if (dir == TextDirection.ltr) {
        widget.quillController.formatSelection(Attribute.rtl);
      } else {
        widget.quillController.formatSelection(const DirectionAttribute(null));
      }
      widget.quillController.formatSelection(const AlignAttribute(null));
    });
  }

  void _applyDirectionFormat(VoidCallback applyFn) {
    if (_isFormatting || _isDirectionFormatting) return;
    _isFormatting = true;
    _isDirectionFormatting = true;
    _scrollController.freezed = true;
    applyFn();
    _isFormatting = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.freezed = false;
      _isDirectionFormatting = false;
    });
  }

  String _lastPlainText = '';
  StreamSubscription? _docChangeSub;

  static const _harakat = {
    '\u064B', '\u064C', '\u064D',
    '\u064E', '\u064F', '\u0650',
    '\u0652',
    '\u0653', '\u0654', '\u0655',
    '\u0656', '\u0657', '\u0670',
  };
  static const _shadda = '\u0651';

  static bool _isTashkeel(String ch) => _harakat.contains(ch) || ch == _shadda;

  @override
  void initState() {
    super.initState();
    widget.quillController.readOnly = widget.readOnly;
    final initialText = widget.quillController.document.toPlainText();
    _lastPlainText = initialText;
    _textDirection = TextDirectionUtils.getDirection(initialText);
    final lines = initialText.split('\n');
    lines.lastWhere(
      (l) => l.trim().isNotEmpty,
      orElse: () => '',
    );
    widget.quillController.addListener(_onChanged);
    _docChangeSub =
        widget.quillController.document.changes.listen(_onDocumentChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _isLoading = false;
      _scrollController.addListener(_onScrollChanged);
    });
  }

  void _onScrollChanged() {
    if (!_scrollController.hasClients) return;
    final offset = _scrollController.offset.clamp(0.0, 120.0);
    widget.onScroll?.call(offset / 120.0);
  }

  void _onDocumentChange(DocChange change) {
    if (_isFormatting || _isPasting || _isLoading || _isDirectionFormatting) {
      return;
    }
    if (change.source != ChangeSource.local) return;

    final ops = change.change.toList();

    if (ops.any((op) => op.isDelete)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _fixDanglingTashkeel();
      });
      return;
    }

    final isOnlyNewline =
        ops.length <= 2 && ops.any((op) => op.isInsert && op.data == '\n');
    if (!isOnlyNewline) return;

    final plainText = widget.quillController.document.toPlainText();
    final cursorOffset =
        widget.quillController.selection.baseOffset.clamp(0, plainText.length);
    final prevLineOffset = cursorOffset > 0 ? cursorOffset - 1 : 0;
    final dir = _getLineDirection(plainText, prevLineOffset);

    _isHandlingEnter = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isHandlingEnter = false;
      if (!mounted || _isFormatting || _isDirectionFormatting) return;
      _applyEnterDirection(dir);
      _scrollToCursor();
    });
  }

  void _fixDanglingTashkeel() {
    final ctrl = widget.quillController;
    final sel = ctrl.selection;
    if (!sel.isCollapsed) return;

    final text = ctrl.document.toPlainText();
    final pos = sel.baseOffset;
    if (pos == 0 || pos > text.length) return;

    final charBefore = text[pos - 1];
    if (!_isTashkeel(charBefore)) return;

    if (pos >= 2 && !_isTashkeel(text[pos - 2])) return;

    ctrl.replaceText(
      pos - 1,
      1,
      '',
      TextSelection.collapsed(offset: pos - 1),
    );
  }

  @override
  void didUpdateWidget(QuillEditorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.readOnly != widget.readOnly) {
      widget.quillController.readOnly = widget.readOnly;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    if (keyboardVisible && !_isKeyboardOpening) {
      _isKeyboardOpening = true;
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _isKeyboardOpening = false;
      });
    }
    // تحديث الخط فقط عند تغييره — لا نمس customStyles
    final newFont = Theme.of(context).textTheme.bodyMedium?.fontFamily;
    if (newFont != _cachedFontFamily) {
      _cachedFontFamily = newFont;
      setState(() {});
    }
  }

  @override
  void dispose() {
    widget.quillController.removeListener(_onChanged);
    _scrollController.removeListener(_onScrollChanged);
    _docChangeSub?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (_isFormatting ||
        _isPasting ||
        _isKeyboardOpening ||
        _isDirectionFormatting ||
        _isHandlingEnter) {
      return;
    }

    final doc = widget.quillController.document;
    final plainText = doc.toPlainText();

    if (plainText == _lastPlainText) return;
    _lastPlainText = plainText;

    final selection = widget.quillController.selection;
    if (!selection.isValid) return;
    if (plainText.trim().isEmpty) return;

    final pt = plainText;
    final off2 = selection.baseOffset.clamp(0, pt.length);
    final ls2 = pt.lastIndexOf('\n', off2 > 0 ? off2 - 1 : 0);
    final le2 = pt.indexOf('\n', off2);
    pt.substring(ls2 < 0 ? 0 : ls2 + 1, le2 < 0 ? pt.length : le2);

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
      final prevDir = _getPrevNonEmptyLineDirection(plainText, offset);
      if (_textDirection != prevDir) {
        setState(() => _textDirection = prevDir);
      }
      return;
    }

    final newDir = TextDirectionUtils.getDirection(currentLine);
    final effectiveDir = (currentLine.length == 1 &&
            newDir == TextDirection.rtl &&
            !RegExp(r'[\u0600-\u06FF]').hasMatch(currentLine))
        ? _getPrevNonEmptyLineDirection(plainText, offset)
        : newDir;
    final isRtl = effectiveDir == TextDirection.rtl;
    final currentAttr =
        widget.quillController.getSelectionStyle().attributes['direction'];
    final currentIsRtl = currentAttr?.value == 'rtl';
    final wantAttr = !isRtl;

    if (currentIsRtl != wantAttr) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _isFormatting || _isDirectionFormatting) return;
        _applyDirectionFormat(() {
          if (isRtl) {
            widget.quillController
                .formatSelection(const DirectionAttribute(null));
            widget.quillController.formatSelection(const AlignAttribute(null));
          } else {
            widget.quillController.formatSelection(Attribute.rtl);
            widget.quillController.formatSelection(const AlignAttribute(null));
          }
        });
      });
    }

    if (effectiveDir != _textDirection) {
      setState(() => _textDirection = effectiveDir);
    }
  }

  TextDirection _getPrevNonEmptyLineDirection(String text, int offset) {
    final currentLineStart =
        text.lastIndexOf('\n', offset > 0 ? offset - 1 : 0);
    if (currentLineStart <= 0) return TextDirection.rtl;

    final before = text.substring(0, currentLineStart);
    final prevLines = before.split('\n');
    for (int i = prevLines.length - 1; i >= 0; i--) {
      if (prevLines[i].trim().isNotEmpty) {
        return TextDirectionUtils.getDirection(prevLines[i]);
      }
    }
    return TextDirection.rtl;
  }

  bool _deleteWithTashkeelAwareness() {
    final ctrl = widget.quillController;
    final sel = ctrl.selection;
    if (!sel.isCollapsed || sel.baseOffset == 0) return false;

    final text = ctrl.document.toPlainText();
    final pos = sel.baseOffset;
    if (pos > text.length) return false;

    int start = pos - 1;
    while (start > 0 && _isTashkeel(text[start])) {
      start--;
    }

    final hasTashkeel =
        (pos - start) > 1 || (pos - start == 1 && _isTashkeel(text[start]));

    if (!hasTashkeel) return false;

    int tashkeelPos = pos - 1;
    while (tashkeelPos > start && !_isTashkeel(text[tashkeelPos])) {
      tashkeelPos--;
    }
    if (_isTashkeel(text[tashkeelPos])) {
      ctrl.replaceText(
        tashkeelPos,
        1,
        '',
        TextSelection.collapsed(offset: tashkeelPos),
      );
      return true;
    }

    return false;
  }

  Future<void> _pastePlainText() async {
    _isPasting = true;
    final ctrl = widget.quillController;
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.isEmpty) {
      return;
    }

    final sel = ctrl.selection;
    final offset = sel.isCollapsed ? sel.extentOffset : sel.start;
    final deleteLen = sel.isCollapsed ? 0 : sel.end - sel.start;

    ctrl.replaceText(offset, deleteLen, text, null);

    final lines = text.split('\n');
    int pos = offset;
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final isLast = i == lines.length - 1;
      final lineTextLen = line.length;

      // تنظيف تنسيق النص فقط (بدون direction)
      if (lineTextLen > 0) {
        ctrl.formatText(pos, lineTextLen, const ColorAttribute(null));
        ctrl.formatText(pos, lineTextLen, const BackgroundAttribute(null));
        ctrl.formatText(pos, lineTextLen, Attribute.clone(Attribute.bold, null));
        ctrl.formatText(pos, lineTextLen, Attribute.clone(Attribute.italic, null));
        ctrl.formatText(pos, lineTextLen, Attribute.clone(Attribute.underline, null));
        ctrl.formatText(pos, lineTextLen, const SizeAttribute(null));
      }

      pos += lineTextLen;

      // طبّق direction على ال\n فقط (1 حرف)
      if (!isLast) {
        final isRtl = TextDirectionUtils.getDirection(line.isNotEmpty ? line : '') == TextDirection.rtl;
        ctrl.formatText(pos, 1, const AlignAttribute(null));
        ctrl.formatText(
          pos,
          1,
          isRtl ? const DirectionAttribute(null) : Attribute.rtl,
        );
        pos += 1;
      }
    }
    _isPasting = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final pos = _scrollController.position;
      final offset = widget.quillController.selection.extentOffset;
      if (pos.pixels < pos.maxScrollExtent - 100) return;
      _scrollController.animateTo(
        pos.maxScrollExtent,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
      );
      offset;
    });
  }

  void _scrollToCursor() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final editorState = _editorKey.currentState;
      editorState?.requestKeyboard();
    });
  }

  KeyEventResult _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.keyV &&
        HardwareKeyboard.instance.isControlPressed) {
      _pastePlainText();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      _handleEnterKey();
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      return _deleteWithTashkeelAwareness()
          ? KeyEventResult.handled
          : KeyEventResult.ignored;
    }
    return KeyEventResult.ignored;
  }

  void _handleEnterKey() {
    final ctrl = widget.quillController;
    final plainText = ctrl.document.toPlainText();
    final offset = ctrl.selection.baseOffset.clamp(0, plainText.length);
    final dir = _getLineDirection(plainText, offset);

    _isHandlingEnter = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isHandlingEnter = false;
      if (!mounted || _isFormatting || _isDirectionFormatting) return;
      _applyEnterDirection(dir);
      _scrollToCursor();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final topPadding = MediaQuery.of(context).padding.top + 56.0;

    return Actions(
      actions: {
        DeleteCharacterIntent: CallbackAction<DeleteCharacterIntent>(
          onInvoke: (intent) {
            if (intent.forward) return Actions.maybeInvoke(context, intent);
            if (_deleteWithTashkeelAwareness()) return null;
            final ctrl = widget.quillController;
            final sel = ctrl.selection;
            if (sel.isCollapsed && sel.baseOffset > 0) {
              ctrl.replaceText(
                sel.baseOffset - 1,
                1,
                '',
                TextSelection.collapsed(offset: sel.baseOffset - 1),
              );
            } else if (!sel.isCollapsed) {
              ctrl.replaceText(
                sel.start,
                sel.end - sel.start,
                '',
                TextSelection.collapsed(offset: sel.start),
              );
            }
            return null;
          },
        ),
        PasteTextIntent: CallbackAction<PasteTextIntent>(
          onInvoke: (_) {
            _pastePlainText();
            return null;
          },
        ),
      },
      child: Focus(
        onKeyEvent: (_, event) => _handleKeyEvent(event),
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            if (!widget.focusNode.hasFocus) {
              widget.focusNode.requestFocus();
            }
          },
          child: Padding(
            padding: EdgeInsets.only(
              top: topPadding,
              bottom: widget.totalBottomSpace,
              left: widget.sidePadding,
              right: widget.sidePadding,
            ),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: ListenableBuilder(
                listenable: widget.quillController,
                builder: (context, child) {
                  final isEmpty = widget.quillController.document.isEmpty();
                  return Stack(
                    fit: StackFit.expand,
                    alignment: AlignmentDirectional.topStart,
                    children: [
                      child!,
                      if (isEmpty)
                        IgnorePointer(
                          child: Text(
                            l10n.startWriting,
                            style: TextStyle(
                              fontFamily: _cachedFontFamily,
                              fontSize: AppFontSize.noteBody,
                              height: 1.6,
                              color: widget.hintColor,
                            ),
                          ),
                        ),
                    ],
                  );
                },
                child: DefaultTextStyle.merge(
                  style: TextStyle(fontFamily: _cachedFontFamily),
                  child: QuillEditor(
                    controller: widget.quillController,
                    focusNode: widget.focusNode,
                    scrollController: _scrollController,
                    config: QuillEditorConfig(
                      editorKey: _editorKey,
                      autoFocus: widget.autoFocus,
                      expands: true,
                      scrollable: true,
                      padding: EdgeInsets.zero,
                      placeholder: '',
                      showCursor: !widget.readOnly,
                      enableInteractiveSelection: !widget.readOnly,                      paintCursorAboveText: true,
                      contextMenuBuilder: (context, rawEditorState) {
                        final anchor = rawEditorState.contextMenuAnchors;
                        final items =
                            rawEditorState.contextMenuButtonItems.map((item) {
                          if (item.type == ContextMenuButtonType.paste) {
                            return item.copyWith(
                              onPressed: () {
                                ContextMenuController.removeAny();
                                _pastePlainText();
                              },
                            );
                          }
                          return item;
                        }).toList();
                        return AdaptiveTextSelectionToolbar.buttonItems(
                          anchors: TextSelectionToolbarAnchors(
                            primaryAnchor: anchor.primaryAnchor,
                            secondaryAnchor: anchor.secondaryAnchor,
                          ),
                          buttonItems: items,
                        );
                      },
                      quillMagnifierBuilder: (dragPosition) =>
                          QuillMagnifier(dragPosition: dragPosition),
                      textSelectionThemeData: TextSelectionThemeData(
                        cursorColor: widget.textColor,
                        selectionColor: widget.textColor.withValues(alpha: 0.2),
                        selectionHandleColor: widget.textColor,
                      ),
                      customStyles: DefaultStyles(
                        paragraph: DefaultTextBlockStyle(
                          TextStyle(
                            fontSize: AppFontSize.noteBody,
                            fontFamily: _cachedFontFamily,
                            height: 1.6,
                            color: widget.textColor,
                            fontFeatures: const [
                              FontFeature.disable('liga'),
                              FontFeature.disable('clig'),
                            ],
                          ),
                          HorizontalSpacing.zero,
                          VerticalSpacing.zero,
                          VerticalSpacing.zero,
                          null,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
