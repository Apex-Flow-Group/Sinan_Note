// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:sinan_note/core/constants/app_text_styles.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';
import 'package:sinan_note/widgets/editor/apex_magnifier.dart';
import 'package:sinan_note/widgets/editor/quill_editor_controller.dart';

class QuillEditorWidget extends StatefulWidget {
  final QuillController quillController;
  final FocusNode focusNode;
  final Color textColor;
  final Color hintColor;
  final Color noteColor;
  final double fontSize;
  final double sidePadding;
  final double totalBottomSpace;
  final bool autoFocus;
  final bool readOnly;
  final bool markdownPaste;
  final ValueChanged<double>? onScroll;
  final ValueNotifier<bool> selectionBarActive;

  const QuillEditorWidget({
    super.key,
    required this.quillController,
    required this.focusNode,
    required this.textColor,
    required this.hintColor,
    required this.noteColor,
    required this.fontSize,
    required this.sidePadding,
    required this.totalBottomSpace,
    required this.selectionBarActive,
    this.autoFocus = false,
    this.readOnly = false,
    this.markdownPaste = false,
    this.onScroll,
  });

  @override
  State<QuillEditorWidget> createState() => _QuillEditorWidgetState();
}

class _QuillEditorWidgetState extends State<QuillEditorWidget> {
  late QuillEditorController _ctrl;
  String? _cachedFontFamily;
  // editorKey يُنشأ مرة واحدة ويبقى ثابتاً طوال عمر الـ widget
  final _editorKey = GlobalKey<EditorState>();

  QuillEditorController _makeCtrl() => QuillEditorController(
        quillController: widget.quillController,
        focusNode: widget.focusNode,
        selectionBarActive: widget.selectionBarActive,
        getNoteColor: () => widget.noteColor,
        onScroll: widget.onScroll,
        externalEditorKey: _editorKey,
        rebuild: () {
          if (mounted) setState(() {});
        },
      );

  @override
  void initState() {
    super.initState();
    _ctrl = _makeCtrl();
    _ctrl.init(widget.readOnly);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _ctrl.didFirstBuild());
  }

  @override
  void didUpdateWidget(QuillEditorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.quillController != widget.quillController) {
      _ctrl.dispose();
      _ctrl = _makeCtrl();
      _ctrl.init(widget.readOnly);
      // لا نُعيد استدعاء didFirstBuild — editorKey لم يتغير
      _ctrl.didFirstBuild();
    } else if (oldWidget.readOnly != widget.readOnly) {
      _ctrl.updateReadOnly(widget.readOnly);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    if (keyboardVisible && !_ctrl.isKeyboardOpening) {
      _ctrl.isKeyboardOpening = true;
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _ctrl.isKeyboardOpening = false;
      });
    }
    final newFont = Theme.of(context).textTheme.bodyMedium?.fontFamily;
    if (newFont != _cachedFontFamily) {
      _cachedFontFamily = newFont;
      setState(() {});
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool _onTapDown(
      TapDownDetails details, TextPosition Function(Offset) getPosition) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fixRtlCursorPosition();
      if (!widget.readOnly) {
        _ctrl.tearHandle.showOnTap(editorKey: _editorKey);
      }
    });
    return false;
  }

  bool _onTapUp(
      TapUpDetails details, TextPosition Function(Offset) getPosition) {
    if (widget.readOnly) return false;

    final pos = getPosition(details.globalPosition);
    final doc = widget.quillController.document;
    final result = doc.querySegmentLeafNode(pos.offset);
    final line = result.line;
    if (line == null) return false;

    final listAttr = line.style.attributes[Attribute.list.key];
    if (listAttr == null) return false;
    final isCheck =
        listAttr.value == 'checked' || listAttr.value == 'unchecked';
    if (!isCheck) return false;

    final lineStart = line.documentOffset;
    if (pos.offset > lineStart) return false;

    final isChecked = listAttr.value == 'checked';
    HapticFeedback.lightImpact();

    widget.quillController
      ..ignoreFocusOnTextChange = true
      ..skipRequestKeyboard = true
      ..formatText(
        line.documentOffset,
        0,
        isChecked ? Attribute.unchecked : Attribute.checked,
      )
      ..toolbarButtonToggler = {
        Attribute.list.key: isChecked ? Attribute.unchecked : Attribute.checked,
        Attribute.header.key: Attribute.header,
      };

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.quillController
        ..ignoreFocusOnTextChange = false
        ..skipRequestKeyboard = false;
    });

    return true;
  }

  void _fixRtlCursorPosition() {
    final sel = widget.quillController.selection;
    if (!sel.isCollapsed) return;
    final plainText = widget.quillController.document.toPlainText();
    final offset = sel.baseOffset;
    if (offset <= 0 || offset >= plainText.length) return;
    final lineEnd = plainText.indexOf('\n', offset);
    if (lineEnd == -1) return;
    if (offset == lineEnd - 1) {
      final lastChar = plainText[offset];
      final isRtlChar =
          RegExp(r'[\u0600-\u06FF\u0750-\u077F\uFB50-\uFDFF\uFE70-\uFEFF]')
              .hasMatch(lastChar);
      if (isRtlChar) {
        widget.quillController.updateSelection(
          TextSelection.collapsed(offset: lineEnd),
          ChangeSource.local,
        );
      }
    }
  }

  Widget? _buildCheckboxLeading(Node node, LeadingConfig config) {
    final isCheck = config.attribute == Attribute.checked ||
        config.attribute == Attribute.unchecked;
    if (!isCheck) return null;

    final isChecked = config.value;
    final textColor = widget.textColor;
    final size = config.lineSize ?? 16.0;

    return Container(
      alignment: AlignmentDirectional.centerEnd,
      padding: EdgeInsetsDirectional.only(end: size / 2),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isChecked ? Colors.green : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isChecked ? Colors.green : textColor.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        child: isChecked
            ? Icon(Icons.check, size: size * 0.75, color: Colors.white)
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final topPadding = MediaQuery.of(context).padding.top + 52.0;

    return Actions(
      actions: {
        DeleteCharacterIntent: CallbackAction<DeleteCharacterIntent>(
          onInvoke: (intent) {
            if (intent.forward) return Actions.maybeInvoke(context, intent);
            if (_ctrl.deleteWithTashkeelAwareness()) return null;
            final ctrl = widget.quillController;
            final sel = ctrl.selection;
            if (sel.isCollapsed && sel.baseOffset > 0) {
              ctrl.replaceText(sel.baseOffset - 1, 1, '',
                  TextSelection.collapsed(offset: sel.baseOffset - 1));
            } else if (!sel.isCollapsed) {
              ctrl.replaceText(sel.start, sel.end - sel.start, '',
                  TextSelection.collapsed(offset: sel.start));
            }
            return null;
          },
        ),
        PasteTextIntent: CallbackAction<PasteTextIntent>(
          onInvoke: (_) {
            _ctrl.pastePlainText(markdownEnabled: widget.markdownPaste);
            return null;
          },
        ),
      },
      child: Focus(
        onKeyEvent: (_, event) =>
            _ctrl.handleKeyEvent(event, markdownEnabled: widget.markdownPaste),
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            if (!widget.focusNode.hasFocus) widget.focusNode.requestFocus();
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
                  final ops =
                      widget.quillController.document.toDelta().toList();
                  final isEmpty = ops.length <= 1 &&
                      (ops.isEmpty ||
                          (ops.first.isInsert &&
                              ops.first.data == '\n' &&
                              ops.first.attributes == null));
                  if (_ctrl.isDraggingSelection || _ctrl.tearHandle.isDragging) return child!;
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
                              height: AppLineHeight.body(
                                widget.fontSize / AppFontSize.noteBody,
                                _cachedFontFamily,
                              ),
                              color: widget.hintColor,
                            ),
                          ),
                        ),
                      if (_ctrl.isPasting)
                        const Positioned.fill(child: AbsorbPointer()),
                    ],
                  );
                },
                child: DefaultTextStyle.merge(
                  style: TextStyle(fontFamily: _cachedFontFamily),
                  child: QuillEditor(
                    controller: widget.quillController,
                    focusNode: widget.focusNode,
                    scrollController: _ctrl.scrollController,
                    config: QuillEditorConfig(
                      unknownEmbedBuilder: _unknownEmbedBuilder,
                      editorKey: _editorKey,
                      autoFocus: widget.autoFocus,
                      expands: true,
                      scrollable: true,
                      padding: EdgeInsets.zero,
                      placeholder: '',
                      checkBoxReadOnly: widget.readOnly,
                      requestKeyboardFocusOnCheckListChanged: false,
                      // ignore: experimental_member_use, invalid_use_of_visible_for_testing_member
                      customLeadingBlockBuilder: _buildCheckboxLeading,
                      onTapUp: _onTapUp,
                      onTapDown: _onTapDown,
                      showCursor: !widget.readOnly,
                      enableInteractiveSelection: !widget.readOnly,
                      paintCursorAboveText: true,
                      contextMenuBuilder: (context, rawEditorState) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) _ctrl.showSelectionBar();
                        });
                        return const SizedBox.shrink();
                      },
                      quillMagnifierBuilder: apexMagnifierBuilder,
                      textSelectionThemeData: TextSelectionThemeData(
                        cursorColor: widget.textColor,
                        selectionColor:
                            widget.textColor.withValues(alpha: 0.2),
                        selectionHandleColor: widget.textColor,
                      ),
                      customStyles: DefaultStyles(
                        leading: DefaultTextBlockStyle(
                          TextStyle(
                            fontSize: AppFontSize.noteBody,
                            fontFamily: _cachedFontFamily,
                            height: AppLineHeight.body(
                              widget.fontSize / AppFontSize.noteBody,
                              _cachedFontFamily,
                            ),
                            color: widget.textColor,
                          ),
                          HorizontalSpacing.zero,
                          VerticalSpacing.zero,
                          VerticalSpacing.zero,
                          null,
                        ),
                        lists: DefaultListBlockStyle(
                          TextStyle(
                            fontSize: AppFontSize.noteBody,
                            fontFamily: _cachedFontFamily,
                            height: AppLineHeight.body(
                              widget.fontSize / AppFontSize.noteBody,
                              _cachedFontFamily,
                            ),
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
                          null,
                        ),
                        paragraph: DefaultTextBlockStyle(
                          TextStyle(
                            fontSize: AppFontSize.noteBody,
                            fontFamily: _cachedFontFamily,
                            height: AppLineHeight.body(
                              widget.fontSize / AppFontSize.noteBody,
                              _cachedFontFamily,
                            ),
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

class _UnknownEmbedBuilder extends EmbedBuilder {
  const _UnknownEmbedBuilder();
  @override
  String get key => '__unknown__';
  @override
  Widget build(BuildContext context, EmbedContext embedContext) =>
      const SizedBox.shrink();
}

const _unknownEmbedBuilder = _UnknownEmbedBuilder();
