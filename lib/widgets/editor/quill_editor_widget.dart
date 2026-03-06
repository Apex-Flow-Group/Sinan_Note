// Copyright © 2025 Apex Flow Group. All rights reserved.

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
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenHeight = MediaQuery.of(context).size.height;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    final topPadding = MediaQuery.of(context).padding.top + 56.0;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        if (!widget.focusNode.hasFocus) {
          widget.focusNode.requestFocus();
        }
      },
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          top: topPadding,
          bottom: widget.totalBottomSpace,
          left: widget.sidePadding,
          right: widget.sidePadding,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: screenHeight - topPadding - widget.totalBottomSpace - keyboardHeight,
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: QuillEditor(
              controller: widget.quillController,
              focusNode: widget.focusNode,
              scrollController: ScrollController(),
              config: QuillEditorConfig(
                autoFocus: widget.autoFocus,
                expands: false,
                scrollable: false,
                padding: EdgeInsets.zero,
                placeholder: l10n.startWriting,
                textSelectionThemeData: TextSelectionThemeData(
                  cursorColor: widget.textColor.withValues(alpha: 0.8),
                  selectionColor: widget.textColor.withValues(alpha: 0.2),
                  selectionHandleColor: widget.textColor.withValues(alpha: 0.8),
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
                  placeHolder: DefaultTextBlockStyle(
                    TextStyle(
                      fontSize: widget.fontSize,
                      height: 1.6,
                      color: widget.hintColor,
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
