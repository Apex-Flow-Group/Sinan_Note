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
  bool _isLoading = true;
  bool _isDirectionFormatting = false;
  bool _isHandlingEnter = false;
  String? _cachedFontFamily;

  // ── Overlay للشريط العائم ─────────────────────────────────────────────────
  OverlayEntry? _selectionBarOverlay;
  bool _suppressBar = false; // يمنع إعادة الظهور بعد الإغلاق المتعمد

  void _showSelectionBar() {
    if (_suppressBar) return; // مُغلق بشكل متعمد — لا تُعد الفتح
    if (_selectionBarOverlay != null) {
      _selectionBarOverlay!.markNeedsBuild();
      return;
    }
    final topOffset = MediaQuery.of(context).padding.top + kToolbarHeight;
    _selectionBarOverlay = OverlayEntry(
      builder: (_) => _FloatingSelectionBar(
        topOffset: topOffset,
        ctrl: widget.quillController,
        noteColor: widget.textColor,
        onPaste: _pastePlainText,
        onDismiss: _hideSelectionBar,
      ),
    );
    Overlay.of(context).insert(_selectionBarOverlay!);
  }

  void _hideSelectionBar() {
    _suppressBar = true;
    _selectionBarOverlay?.remove();
    _selectionBarOverlay = null;
    // بعد frame واحد نُعيد تفعيل الشريط للضغطات المستقبلية
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _suppressBar = false;
    });
  }

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
    _hideSelectionBar();
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
        ctrl.formatText(
            pos, lineTextLen, Attribute.clone(Attribute.bold, null));
        ctrl.formatText(
            pos, lineTextLen, Attribute.clone(Attribute.italic, null));
        ctrl.formatText(
            pos, lineTextLen, Attribute.clone(Attribute.underline, null));
        ctrl.formatText(pos, lineTextLen, const SizeAttribute(null));
      }

      pos += lineTextLen;

      // طبّق direction على ال\n فقط (1 حرف)
      if (!isLast) {
        final isRtl =
            TextDirectionUtils.getDirection(line.isNotEmpty ? line : '') ==
                TextDirection.rtl;
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
                      enableInteractiveSelection: !widget.readOnly,
                      paintCursorAboveText: true,
                      contextMenuBuilder: (context, rawEditorState) {
                        // جميع المنصات → شريط عائم تحت الهيدر
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) _showSelectionBar();
                        });
                        return const SizedBox.shrink();
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

/// بيانات زر واحد في الشريط العائم
class _BarEntry {
  final String label;
  final IconData icon;
  final VoidCallback action;
  final bool enabled;
  const _BarEntry({
    required this.label,
    required this.icon,
    required this.action,
    this.enabled = true,
  });
}

// ── حالات الشريط ──────────────────────────────────────────────────────────────
enum _BarState {
  /// لا يوجد تحديد
  noSelection,

  /// يوجد تحديد جزئي
  hasSelection,

  /// كل النص محدد
  allSelected,
}

/// شريط تحديد النص العائم — يظهر بـ slide من الأعلى تحت الهيدر مباشرة
/// يتكيف ذكياً مع حالة التحديد والـ clipboard
class _FloatingSelectionBar extends StatefulWidget {
  final double topOffset;
  final QuillController ctrl;
  final Color noteColor;
  final Future<void> Function() onPaste;
  final VoidCallback onDismiss;

  const _FloatingSelectionBar({
    required this.topOffset,
    required this.ctrl,
    required this.noteColor,
    required this.onPaste,
    required this.onDismiss,
  });
  @override
  State<_FloatingSelectionBar> createState() => _FloatingSelectionBarState();
}

class _FloatingSelectionBarState extends State<_FloatingSelectionBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<Offset> _slide;
  late Animation<double> _fade;
  bool _hasClipboard = false;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
    _checkClipboard();
    widget.ctrl.addListener(_onSelectionChanged);
  }

  @override
  void dispose() {
    widget.ctrl.removeListener(_onSelectionChanged);
    _animCtrl.dispose();
    super.dispose();
  }

  void _onSelectionChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _checkClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (mounted) {
      setState(() => _hasClipboard = (data?.text?.isNotEmpty ?? false));
    }
  }

  _BarState _getBarState() {
    final sel = widget.ctrl.selection;
    if (sel.isCollapsed) return _BarState.noSelection;
    final docLen = widget.ctrl.document.length;
    // كل النص محدد إذا كان التحديد يغطي كل المحتوى (مع مراعاة \n الأخير)
    if (sel.start == 0 && sel.end >= docLen - 1) return _BarState.allSelected;
    return _BarState.hasSelection;
  }

  List<_BarEntry> _buildEntries(_BarState state, bool isAr) {
    final ctrl = widget.ctrl;

    void doCut() {
      widget.onDismiss();
      ContextMenuController.removeAny();
      final sel = ctrl.selection;
      if (sel.isCollapsed) return;
      final text = ctrl.document.toPlainText();
      Clipboard.setData(
          ClipboardData(text: text.substring(sel.start, sel.end)));
      ctrl.replaceText(sel.start, sel.end - sel.start, '',
          TextSelection.collapsed(offset: sel.start));
    }

    void doCopy() {
      widget.onDismiss();
      ContextMenuController.removeAny();
      final sel = ctrl.selection;
      if (sel.isCollapsed) return;
      final text = ctrl.document.toPlainText();
      Clipboard.setData(
          ClipboardData(text: text.substring(sel.start, sel.end)));
    }

    void doPaste() {
      // اللصق أولاً قبل الإغلاق — حتى لا يُفقد التحديد
      widget.onPaste();
      widget.onDismiss();
      ContextMenuController.removeAny();
    }

    void doSelectAll() {
      // لا نُغلق الشريط — يتحول لحالة allSelected عبر _onSelectionChanged
      final len = ctrl.document.length;
      ctrl.updateSelection(
        TextSelection(baseOffset: 0, extentOffset: len - 1),
        ChangeSource.local,
      );
      _checkClipboard();
    }

    void doDeselect() {
      widget.onDismiss();
      ContextMenuController.removeAny();
      final offset = ctrl.selection.start;
      ctrl.updateSelection(
        TextSelection.collapsed(offset: offset),
        ChangeSource.local,
      );
    }

    // ── بناء الأزرار حسب الحالة ────────────────────────────────────────────
    switch (state) {
      case _BarState.noSelection:
        // لا تحديد: لصق (إذا clipboard فيه شيء) + تحديد الكل
        return [
          _BarEntry(
            label: isAr ? 'لصق' : 'Paste',
            icon: Icons.content_paste_rounded,
            action: doPaste,
            enabled: _hasClipboard,
          ),
          _BarEntry(
            label: isAr ? 'تحديد الكل' : 'Select all',
            icon: Icons.select_all_rounded,
            action: doSelectAll,
          ),
        ];

      case _BarState.hasSelection:
        // تحديد جزئي: قص + نسخ + لصق (إذا clipboard) + تحديد الكل + إلغاء
        return [
          _BarEntry(
            label: isAr ? 'قص' : 'Cut',
            icon: Icons.content_cut_rounded,
            action: doCut,
          ),
          _BarEntry(
            label: isAr ? 'نسخ' : 'Copy',
            icon: Icons.content_copy_rounded,
            action: doCopy,
          ),
          if (_hasClipboard)
            _BarEntry(
              label: isAr ? 'لصق' : 'Paste',
              icon: Icons.content_paste_rounded,
              action: doPaste,
            ),
          _BarEntry(
            label: isAr ? 'تحديد الكل' : 'All',
            icon: Icons.select_all_rounded,
            action: doSelectAll,
          ),
          _BarEntry(
            label: isAr ? 'إلغاء' : 'Deselect',
            icon: Icons.deselect_rounded,
            action: doDeselect,
          ),
        ];

      case _BarState.allSelected:
        // كل النص محدد: قص + نسخ + لصق (إذا clipboard) + إلغاء التحديد
        return [
          _BarEntry(
            label: isAr ? 'قص' : 'Cut',
            icon: Icons.content_cut_rounded,
            action: doCut,
          ),
          _BarEntry(
            label: isAr ? 'نسخ' : 'Copy',
            icon: Icons.content_copy_rounded,
            action: doCopy,
          ),
          if (_hasClipboard)
            _BarEntry(
              label: isAr ? 'لصق' : 'Paste',
              icon: Icons.content_paste_rounded,
              action: doPaste,
            ),
          _BarEntry(
            label: isAr ? 'إلغاء التحديد' : 'Deselect',
            icon: Icons.deselect_rounded,
            action: doDeselect,
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final isNoteLight = widget.noteColor.computeLuminance() > 0.5;

    final barBg = isNoteLight
        ? (isDark ? const Color(0xFF2A2A2A) : const Color(0xFF1C1C1E))
        : (isDark ? const Color(0xFFF2F2F7) : Colors.white);
    final barText = isNoteLight ? Colors.white : Colors.black87;
    final disabledText = barText.withValues(alpha: 0.3);
    final dividerColor = barText.withValues(alpha: 0.12);

    final state = _getBarState();
    final entries = _buildEntries(state, isAr);

    return Positioned(
      top: widget.topOffset + 6,
      left: 12,
      right: 12,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: FadeTransition(
            opacity: _fade,
            child: SlideTransition(
              position: _slide,
              child: Material(
                color: Colors.transparent,
                child: TapRegion(
                  onTapOutside: (_) {
                    widget.onDismiss();
                    ContextMenuController.removeAny();
                  },
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: barBg,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withValues(alpha: isDark ? 0.4 : 0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    // AnimatedSwitcher على الـ Row فقط — الـ slide/fade لا تُعاد
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 160),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: child,
                      ),
                      child: Row(
                        // key يُخبر AnimatedSwitcher أن المحتوى تغيّر
                        key: ValueKey(state),
                        children: entries.asMap().entries.map((entry) {
                          final i = entry.key;
                          final e = entry.value;
                          final isLast = i == entries.length - 1;
                          return Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  child: _BarButton(
                                    label: e.label,
                                    icon: e.icon,
                                    textColor:
                                        e.enabled ? barText : disabledText,
                                    enabled: e.enabled,
                                    onAction: e.action,
                                  ),
                                ),
                                if (!isLast)
                                  Container(
                                    width: 1,
                                    height: 24,
                                    color: dividerColor,
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ), // ConstrainedBox
      ), // Align
    );
  }
}

/// زر داخل الشريط العائم
class _BarButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color textColor;
  final bool enabled;
  final VoidCallback onAction;

  const _BarButton({
    required this.label,
    required this.icon,
    required this.textColor,
    required this.onAction,
    this.enabled = true,
  });

  @override
  State<_BarButton> createState() => _BarButtonState();
}

class _BarButtonState extends State<_BarButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.enabled
          ? (_) {
              setState(() => _pressed = true);
              widget.onAction();
            }
          : null,
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        decoration: BoxDecoration(
          color: _pressed && widget.enabled
              ? widget.textColor.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(widget.icon, size: 17, color: widget.textColor),
            const SizedBox(height: 2),
            Text(
              widget.label,
              style: TextStyle(
                fontSize: 10,
                color: widget.textColor,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
