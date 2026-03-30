// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:convert';
import 'package:apex_note/core/utils/text_direction_utils.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
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

  bool _isFormatting = false;

  void _onChanged() {
    debugPrint('[Quill] _onChanged called, _isFormatting=$_isFormatting');
    if (_isFormatting) {
      debugPrint('[Quill] skipped (formatting in progress)');
      return;
    }

    final doc = widget.quillController.document;
    final selection = widget.quillController.selection;
    debugPrint('[Quill] selection=$selection, isValid=${selection.isValid}');
    if (!selection.isValid) return;

    final plainText = doc.toPlainText();
    debugPrint('[Quill] plainText="${plainText.replaceAll('\n', '\\n')}"');
    if (plainText.trim().isEmpty) {
      debugPrint('[Quill] plainText is empty, skipping');
      return;
    }

    final offset = selection.baseOffset.clamp(0, plainText.length);
    final lineStart = plainText.lastIndexOf('\n', offset > 0 ? offset - 1 : 0);
    final lineEnd = plainText.indexOf('\n', offset);
    final currentLine = plainText.substring(
      lineStart < 0 ? 0 : lineStart + 1,
      lineEnd < 0 ? plainText.length : lineEnd,
    );
    debugPrint('[Quill] offset=$offset, lineStart=$lineStart, lineEnd=$lineEnd');
    debugPrint('[Quill] currentLine="$currentLine"');

    final newDir = TextDirectionUtils.getDirection(
      currentLine.isNotEmpty ? currentLine : plainText,
    );
    debugPrint('[Quill] newDir=$newDir');

    if (currentLine.isEmpty) {
      debugPrint('[Quill] empty line, skipping');
      return;
    }

    final isRtl = newDir == TextDirection.rtl;
    final selectionStyle = widget.quillController.getSelectionStyle();
    final currentAttr = selectionStyle.attributes['direction'];
    final currentIsRtl = currentAttr?.value == 'rtl';
    debugPrint('[Quill] selectionStyle.attributes=${selectionStyle.attributes}');
    debugPrint('[Quill] currentAttr=$currentAttr, currentIsRtl=$currentIsRtl, isRtl=$isRtl');

    // مع Directionality(rtl):
    // عربي = بدون direction (يرث rtl من الأب) ← currentIsRtl يجب أن يكون false
    // إنجليزي = direction:rtl (يعكس) ← currentIsRtl يجب أن يكون true
    // إذن: isRtl=true يعني نريد currentIsRtl=false، وisRtl=false يعني نريد currentIsRtl=true
    final wantAttr = !isRtl; // عربي=false(بدون attr)، إنجليزي=true(direction:rtl)

    if (currentIsRtl != wantAttr) {
      debugPrint('[Quill] APPLYING: ${isRtl ? 'Arabic→remove direction' : 'English→add direction:rtl'}');
      _isFormatting = true;
      if (isRtl) {
        widget.quillController.formatSelection(const DirectionAttribute(null));
        widget.quillController.formatSelection(const AlignAttribute(null));
      } else {
        widget.quillController.formatSelection(Attribute.rtl);
        widget.quillController.formatSelection(const AlignAttribute(null));
      }
      _isFormatting = false;
      debugPrint('[Quill] formatting done');
    } else {
      debugPrint('[Quill] no change needed');
    }

    if (newDir != _textDirection) {
      debugPrint('[Quill] _textDirection: $_textDirection → $newDir (hint only)');
      setState(() => _textDirection = newDir);
    }

    debugPrint('[Quill] delta=${jsonEncode(widget.quillController.document.toDelta().toJson())}');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final topPadding = MediaQuery.of(context).padding.top + 56.0;

    return GestureDetector(
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
    );
  }
}
