// Copyright © 2025 Apex Flow Group. All rights reserved.


import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:provider/provider.dart';
import 'package:sinan_note/controllers/settings/settings_provider.dart';
import 'package:sinan_note/core/constants/app_text_styles.dart';
import 'package:sinan_note/models/note_mode.dart';
import 'package:sinan_note/screens/shared/note_editor/core/editor_coordinator.dart';
import 'package:sinan_note/screens/shared/note_editor/view/readonly_checklist_view.dart';
import 'package:sinan_note/widgets/editor/markdown_viewer.dart';

/// يعرض محتوى الملاحظة في وضع القراءة حسب النوع
class ReadOnlyContent extends StatelessWidget {
  final NoteMode mode;
  final EditorCoordinator coordinator;
  final Color textColor;
  final Color noteColor;
  final ScrollController scrollController;
  final bool showMarkdown;
  final bool isTrashed;
  final int quillKey;
  final Future<void> Function({bool isManualSave}) onSave;

  const ReadOnlyContent({
    super.key,
    required this.mode,
    required this.coordinator,
    required this.textColor,
    required this.noteColor,
    required this.scrollController,
    required this.showMarkdown,
    required this.isTrashed,
    required this.quillKey,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    if (mode == NoteMode.checklist) {
      return ReadOnlyChecklistView(
        coordinator: coordinator,
        textColor: textColor,
        noteColor: noteColor,
        scrollController: scrollController,
        onSave: onSave,
        isTrashed: isTrashed,
      );
    }

    if (showMarkdown) {
      final content = coordinator.codeController?.text ??
          coordinator.contentController.text;
      return Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 80),
        child: MarkdownViewer(content: content, textColor: textColor),
      );
    }

    if (mode == NoteMode.code) {
      final content = coordinator.codeController?.text ??
          coordinator.contentController.text;
      return ScrollbarTheme(
        data: const ScrollbarThemeData(thickness: WidgetStatePropertyAll(0)),
        child: SingleChildScrollView(
          controller: scrollController,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 80),
              child: SelectableText(
                content,
                style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                    height: 1.6,
                    color: textColor),
              ),
            ),
          ),
        ),
      );
    }

    final qc = coordinator.quillController;
    if (qc == null) return const SizedBox.shrink();

    final fontFamily = Theme.of(context).textTheme.bodyMedium?.fontFamily;
    qc.readOnly = true;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: DefaultTextStyle.merge(
        style: TextStyle(fontFamily: fontFamily),
        child: ScrollbarTheme(
          data: const ScrollbarThemeData(thickness: WidgetStatePropertyAll(0)),
          child: QuillEditor(
            key: ValueKey(quillKey),
            controller: qc,
            focusNode: coordinator.textFieldFocusNode,
            scrollController: ScrollController(),
            config: QuillEditorConfig(
              unknownEmbedBuilder: _unknownEmbedBuilder,
              autoFocus: false,
              expands: true,
              scrollable: true,
              padding: const EdgeInsets.only(top: 20, bottom: 40),
              showCursor: false,
              enableInteractiveSelection: false,
              checkBoxReadOnly: true,
              // ignore: experimental_member_use
              customLeadingBlockBuilder: (node, config) =>
                  _buildCheckboxLeading(config, textColor),
              customStyles: DefaultStyles(
                leading: _blockStyle(context, fontFamily, textColor),
                lists: _listStyle(context, fontFamily, textColor),
                paragraph: _blockStyle(context, fontFamily, textColor),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static DefaultTextBlockStyle _blockStyle(
      BuildContext context, String? fontFamily, Color textColor) {
    return DefaultTextBlockStyle(
      TextStyle(
        fontSize: AppFontSize.noteBody,
        fontFamily: fontFamily,
        height: AppLineHeight.body(
          Provider.of<SettingsProvider>(context, listen: false).textScaleFactor,
          fontFamily,
        ),
        color: textColor,
      ),
      HorizontalSpacing.zero,
      VerticalSpacing.zero,
      VerticalSpacing.zero,
      null,
    );
  }

  static DefaultListBlockStyle _listStyle(
      BuildContext context, String? fontFamily, Color textColor) {
    return DefaultListBlockStyle(
      TextStyle(
        fontSize: AppFontSize.noteBody,
        fontFamily: fontFamily,
        height: AppLineHeight.body(
          Provider.of<SettingsProvider>(context, listen: false).textScaleFactor,
          fontFamily,
        ),
        color: textColor,
      ),
      HorizontalSpacing.zero,
      VerticalSpacing.zero,
      VerticalSpacing.zero,
      null,
      null,
    );
  }

  static Widget? _buildCheckboxLeading(LeadingConfig config, Color textColor) {
    final isCheck = config.attribute == Attribute.checked ||
        config.attribute == Attribute.unchecked;
    if (!isCheck) return null;

    final isChecked = config.value;
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

