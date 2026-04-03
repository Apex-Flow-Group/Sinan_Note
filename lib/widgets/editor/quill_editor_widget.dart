// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/core/utils/text_direction_utils.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';

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
  });

  @override
  State<QuillEditorWidget> createState() => _QuillEditorWidgetState();
}

class _QuillEditorWidgetState extends State<QuillEditorWidget> {
  TextDirection _textDirection = TextDirection.rtl;
  final ScrollController _scrollController = ScrollController();
  bool _isFormatting = false;
  bool _isPasting = false;

  // حروف التشكيل العربية (بدون الشدة)
  static const _harakat = {
    '\u064B', '\u064C', '\u064D', // تنوين فتح/ضم/كسر
    '\u064E', '\u064F', '\u0650', // فتحة/ضمة/كسرة
    '\u0652', // سكون
    '\u0653', '\u0654', '\u0655', // مدة/همزة فوق/همزة تحت
    '\u0656', '\u0657', '\u0670', // صفحة سفلية/إشارة رفع/ألف خنجرية
  };
  static const _shadda = '\u0651'; // الشدة تُحذف بعد باقي التشكيل

  static bool _isTashkeel(String ch) => _harakat.contains(ch) || ch == _shadda;

  @override
  void initState() {
    super.initState();
    final initialText = widget.quillController.document.toPlainText();
    _textDirection = TextDirectionUtils.getDirection(initialText);
    widget.quillController.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.quillController.removeListener(_onChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (_isFormatting || _isPasting) return;

    final doc = widget.quillController.document;
    final selection = widget.quillController.selection;
    if (!selection.isValid) return;

    final plainText = doc.toPlainText();
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
      _isFormatting = true;
      widget.quillController.formatSelection(const DirectionAttribute(null));
      widget.quillController.formatSelection(const AlignAttribute(null));
      _isFormatting = false;
      if (_textDirection != TextDirection.rtl) {
        setState(() => _textDirection = TextDirection.rtl);
      }
      return;
    }

    final newDir = TextDirectionUtils.getDirection(currentLine);
    final isRtl = newDir == TextDirection.rtl;
    final currentAttr =
        widget.quillController.getSelectionStyle().attributes['direction'];
    final currentIsRtl = currentAttr?.value == 'rtl';
    final wantAttr = !isRtl;

    if (currentIsRtl != wantAttr) {
      _isFormatting = true;
      if (isRtl) {
        widget.quillController.formatSelection(const DirectionAttribute(null));
        widget.quillController.formatSelection(const AlignAttribute(null));
      } else {
        widget.quillController.formatSelection(Attribute.rtl);
        widget.quillController.formatSelection(const AlignAttribute(null));
      }
      _isFormatting = false;
    }

    if (newDir != _textDirection) {
      setState(() => _textDirection = newDir);
    }
  }

  /// يحذف التشكيل أولاً قبل الحرف — يعمل على الموبايل والديسكتوب
  bool _deleteWithTashkeelAwareness() {
    final ctrl = widget.quillController;
    final sel = ctrl.selection;
    if (!sel.isCollapsed || sel.baseOffset == 0) return false;

    final text = ctrl.document.toPlainText();
    final pos = sel.baseOffset;
    if (pos > text.length) return false;

    final charBefore = text[pos - 1];

    // إذا كان الحرف قبل الكرسر تشكيلاً — احذفه فقط
    if (_isTashkeel(charBefore)) {
      ctrl.replaceText(
        pos - 1,
        1,
        '',
        TextSelection.collapsed(offset: pos - 1),
      );
      return true;
    }

    // إذا كان الحرف عادياً — تحقق هل قبله تشكيل متراكم
    // مثال: "كَـ" → الكرسر بعد الفتحة، نحذف الفتحة أولاً
    // هذا يُعالج حالة: حرف + تشكيل + كرسر → احذف التشكيل لا الحرف
    // (هذه الحالة تُعالجها الفقرة أعلاه بالفعل)

    return false; // اتركه للسلوك الافتراضي
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

    ctrl.formatText(offset, text.length, const ColorAttribute(null));
    ctrl.formatText(offset, text.length, const BackgroundAttribute(null));
    ctrl.formatText(offset, text.length, Attribute.clone(Attribute.bold, null));
    ctrl.formatText(
        offset, text.length, Attribute.clone(Attribute.italic, null));
    ctrl.formatText(
        offset, text.length, Attribute.clone(Attribute.underline, null));
    ctrl.formatText(offset, text.length, const SizeAttribute(null));

    final lines = text.split('\n');
    int pos = offset;
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lineLen = line.length + (i < lines.length - 1 ? 1 : 0);
      ctrl.formatText(pos, lineLen, const AlignAttribute(null));
      if (line.isNotEmpty) {
        final isRtl =
            TextDirectionUtils.getDirection(line) == TextDirection.rtl;
        ctrl.formatText(
          pos,
          lineLen,
          isRtl ? const DirectionAttribute(null) : Attribute.rtl,
        );
      }
      pos += lineLen;
    }
    _isPasting = false;
    // تمرير لموضع المؤشر بعد اللصق
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });
  }

  KeyEventResult _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    // Ctrl+V
    if (event.logicalKey == LogicalKeyboardKey.keyV &&
        HardwareKeyboard.instance.isControlPressed) {
      _pastePlainText();
      return KeyEventResult.handled;
    }
    // Backspace
    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      return _deleteWithTashkeelAwareness()
          ? KeyEventResult.handled
          : KeyEventResult.ignored;
    }
    return KeyEventResult.ignored;
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
            // تشكيل → احذفه فقط
            if (_deleteWithTashkeelAwareness()) return null;
            // حرف عادي → احذفه يدوياً
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
                              fontSize: widget.fontSize,
                              height: 1.6,
                              color: widget.hintColor,
                            ),
                          ),
                        ),
                    ],
                  );
                },
                child: QuillEditor(
                  controller: widget.quillController,
                  focusNode: widget.focusNode,
                  scrollController: _scrollController,
                  config: QuillEditorConfig(
                    autoFocus: widget.autoFocus,
                    expands: true,
                    scrollable: true,
                    padding: EdgeInsets.zero,
                    placeholder: '',
                    paintCursorAboveText: true,
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
                          fontSize: widget.fontSize,
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
    );
  }
}
