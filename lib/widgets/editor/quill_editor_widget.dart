// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/core/constants/app_text_styles.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:apex_note/widgets/editor/apex_magnifier.dart';
import 'package:apex_note/widgets/editor/quill_editor_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

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
    this.onScroll,
  });

  @override
  State<QuillEditorWidget> createState() => _QuillEditorWidgetState();
}

class _QuillEditorWidgetState extends State<QuillEditorWidget> {
  late final QuillEditorController _ctrl;
  String? _cachedFontFamily;

  @override
  void initState() {
    super.initState();
    _ctrl = QuillEditorController(
      quillController: widget.quillController,
      focusNode: widget.focusNode,
      selectionBarActive: widget.selectionBarActive,
      getNoteColor: () => widget.noteColor,
      onScroll: widget.onScroll,
      rebuild: () {
        if (mounted) setState(() {});
      },
    );
    _ctrl.init(widget.readOnly);
  }

  @override
  void didUpdateWidget(QuillEditorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.readOnly != widget.readOnly) {
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
            _ctrl.pastePlainText();
            return null;
          },
        ),
      },
      child: Focus(
        onKeyEvent: (_, event) => _ctrl.handleKeyEvent(event),
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
                    scrollController: _ctrl.scrollController,
                    config: QuillEditorConfig(
                      editorKey: _ctrl.editorKey,
                      autoFocus: widget.autoFocus,
                      expands: true,
                      scrollable: true,
                      padding: EdgeInsets.zero,
                      placeholder: '',
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
