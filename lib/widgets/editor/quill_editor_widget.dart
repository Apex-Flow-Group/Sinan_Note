// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:async';

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
  bool _isKeyboardOpening = false;
  bool _isLoading = true; // يمنع _onDocumentChange أثناء تحميل النوتة
  String _lastPlainText = '';
  StreamSubscription? _docChangeSub;

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
    });
  }

  /// يكتشف إدراج \n عبر IME (أندرويد) ويحقن سمة الاتجاه
  /// ويُصلح التشكيل المعلق بعد حذف IME
  void _onDocumentChange(DocChange change) {
    if (_isFormatting || _isPasting || _isLoading) return;
    if (change.source != ChangeSource.local) return;

    final delta = change.change;
    final ops = delta.toList();

    // ── اكتشاف حذف IME وإصلاح التشكيل المعلق ──────────────────────────
    final isDelete = ops.any((op) => op.isDelete);
    if (isDelete) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _fixDanglingTashkeel();
      });
      return;
    }

    // ── اكتشاف Enter عبر IME ─────────────────────────────────────────────
    final isOnlyNewline =
        ops.length <= 2 && ops.any((op) => op.isInsert && op.data == '\n');
    if (!isOnlyNewline) return;

    final plainText = widget.quillController.document.toPlainText();
    final offset =
        widget.quillController.selection.baseOffset.clamp(0, plainText.length);
    final prevDir = _getPrevNonEmptyLineDirection(plainText, offset);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isFormatting) return;
      _isFormatting = true;
      if (prevDir == TextDirection.ltr) {
        widget.quillController.formatSelection(Attribute.rtl);
      } else {
        widget.quillController.formatSelection(const DirectionAttribute(null));
      }
      widget.quillController.formatSelection(const AlignAttribute(null));
      _isFormatting = false;
    });
  }

  /// يفحص النص بعد أي حذف — إذا وُجد تشكيل في بداية المجموعة (بدون حرف أساسي) يحذفه
  void _fixDanglingTashkeel() {
    final ctrl = widget.quillController;
    final sel = ctrl.selection;
    if (!sel.isCollapsed) return;

    final text = ctrl.document.toPlainText();
    final pos = sel.baseOffset;
    if (pos == 0 || pos > text.length) return;

    // إذا كان الحرف قبل المؤشر تشكيلاً والحرف قبله أيضاً تشكيل أو بداية النص
    // → يعني تشكيل معلق بدون حرف أساسي
    final charBefore = text[pos - 1];
    if (!_isTashkeel(charBefore)) return;

    // تحقق: هل قبله حرف أساسي؟
    if (pos >= 2 && !_isTashkeel(text[pos - 2])) return; // طبيعي — حرف + تشكيل

    // تشكيل معلق — احذفه
    ctrl.replaceText(
      pos - 1, 1, '',
      TextSelection.collapsed(offset: pos - 1),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // عند ظهور الكيبورد (viewInsets تتغير) — نوقف formatSelection مؤقتاً
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    if (keyboardVisible && !_isKeyboardOpening) {
      _isKeyboardOpening = true;
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _isKeyboardOpening = false;
      });
    }
  }

  @override
  void dispose() {
    widget.quillController.removeListener(_onChanged);
    _docChangeSub?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (_isFormatting || _isPasting || _isKeyboardOpening) return;

    final doc = widget.quillController.document;
    final plainText = doc.toPlainText();

    // ← الجديد: تجاهل إذا لم يتغير النص (مجرد تحريك cursor أو تحديد)
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
      // السطر الفارغ تُعالجه _handleEnterKey — فقط نحدّث الاتجاه المرئي
      final prevDir = _getPrevNonEmptyLineDirection(plainText, offset);
      if (_textDirection != prevDir) {
        setState(() => _textDirection = prevDir);
      }
      return;
    }

    final newDir = TextDirectionUtils.getDirection(currentLine);
    // إذا كان السطر حرفاً واحداً فقط والحرف محايد (رقم أو رمز) — ارث اتجاه السطر السابق
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
        if (!mounted || _isFormatting) return;
        _isFormatting = true;
        if (isRtl) {
          widget.quillController
              .formatSelection(const DirectionAttribute(null));
          widget.quillController.formatSelection(const AlignAttribute(null));
        } else {
          widget.quillController.formatSelection(Attribute.rtl);
          widget.quillController.formatSelection(const AlignAttribute(null));
        }
        _isFormatting = false;
      });
    }

    if (effectiveDir != _textDirection) {
      setState(() => _textDirection = effectiveDir);
    }
  }

  /// يجد اتجاه آخر سطر غير فارغ قبل موضع المؤشر
  TextDirection _getPrevNonEmptyLineDirection(String text, int offset) {
    // ابحث عن بداية السطر الحالي
    final currentLineStart =
        text.lastIndexOf('\n', offset > 0 ? offset - 1 : 0);
    if (currentLineStart <= 0) return TextDirection.rtl;

    // ابحث للخلف عن أول سطر غير فارغ
    final before = text.substring(0, currentLineStart);
    final prevLines = before.split('\n');
    for (int i = prevLines.length - 1; i >= 0; i--) {
      if (prevLines[i].trim().isNotEmpty) {
        return TextDirectionUtils.getDirection(prevLines[i]);
      }
    }
    return TextDirection.rtl;
  }

  /// يحذف التشكيل أولاً قبل الحرف — يعمل على الموبايل والديسكتوب
  bool _deleteWithTashkeelAwareness() {
    final ctrl = widget.quillController;
    final sel = ctrl.selection;
    if (!sel.isCollapsed || sel.baseOffset == 0) return false;

    final text = ctrl.document.toPlainText();
    final pos = sel.baseOffset;
    if (pos > text.length) return false;

    // ابحث للخلف عن بداية المجموعة (حرف + تشكيله متراكم)
    // مثال: "لً" في الذاكرة = [ل][ً] — نجد بداية المجموعة من pos للخلف
    int start = pos - 1;
    // تخطّ كل تشكيل متراكم للخلف
    while (start > 0 && _isTashkeel(text[start])) {
      start--;
    }
    // start الآن يشير إلى الحرف الأساسي أو تشكيل إذا كان كل شيء تشكيل

    final hasTashkeel = (pos - start) > 1 ||
        (pos - start == 1 && _isTashkeel(text[start]));

    if (!hasTashkeel) return false; // لا يوجد تشكيل — اتركه للسلوك الافتراضي

    // احذف آخر تشكيل فقط (واحد في كل ضغطة)
    // ابحث عن آخر تشكيل قبل المؤشر
    int tashkeelPos = pos - 1;
    while (tashkeelPos > start && !_isTashkeel(text[tashkeelPos])) {
      tashkeelPos--;
    }
    if (_isTashkeel(text[tashkeelPos])) {
      ctrl.replaceText(
        tashkeelPos, 1, '',
        TextSelection.collapsed(offset: tashkeelPos),
      );
      return true;
    }

    return false;
  }

  // محارف التحكم BiDi (محفوظة للاستخدام المستقبلي)
  // static const _lrm = '\u200E'; // Left-to-Right Mark
  // static const _rlm = '\u200F'; // Right-to-Left Mark

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
    // Enter — حقن سمة الاتجاه للسطر الجديد قبل إنشائه
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      _handleEnterKey();
      return KeyEventResult.ignored; // نترك Quill ينشئ السطر بعد تحديث الحالة
    }
    // Backspace
    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      return _deleteWithTashkeelAwareness()
          ? KeyEventResult.handled
          : KeyEventResult.ignored;
    }
    return KeyEventResult.ignored;
  }

  /// يحدد اتجاه السطر الحالي ويحفظه ليُطبَّق على السطر الجديد
  void _handleEnterKey() {
    final ctrl = widget.quillController;
    final plainText = ctrl.document.toPlainText();
    final offset = ctrl.selection.baseOffset.clamp(0, plainText.length);
    final prevDir = _getPrevNonEmptyLineDirection(plainText, offset);

    // بعد Enter بمليسثانية واحدة — طبّق السمة على السطر الجديد
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isFormatting) return;
      _isFormatting = true;
      if (prevDir == TextDirection.ltr) {
        // إنجليزي: نحتاج direction:rtl ليعكس الاتجاه في سياق الأب RTL
        ctrl.formatSelection(Attribute.rtl);
      } else {
        // عربي: نحذف أي direction صريح — يرث RTL من الأب تلقائياً
        ctrl.formatSelection(const DirectionAttribute(null));
      }
      ctrl.formatSelection(const AlignAttribute(null));
      _isFormatting = false;
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
