// Copyright © 2025 Apex Flow Group. All rights reserved.

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
  bool _isFormatting = false;

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
    if (_isFormatting) return;

    final doc = widget.quillController.document;
    final selection = widget.quillController.selection;
    if (!selection.isValid) return;

    final plainText = doc.toPlainText();
    if (plainText.trim().isEmpty) return;

    final offset = selection.baseOffset.clamp(0, plainText.length);
    final lineStart = plainText.lastIndexOf('\n', offset > 0 ? offset - 1 : 0);
    final lineEnd = plainText.indexOf('\n', offset);
    final currentLine = plainText.substring(
      lineStart < 0 ? 0 : lineStart + 1,
      lineEnd < 0 ? plainText.length : lineEnd,
    );

    if (currentLine.isEmpty) return;

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
                      fontFeatures: [
                        const FontFeature.disable('liga'),
                        const FontFeature.disable('clig'),
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
    );
  }
}
