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
  final DateTime? reminderDateTime;
  final VoidCallback? onRemoveReminder;

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
    this.reminderDateTime,
    this.onRemoveReminder,
  });

  @override
  Widget build(BuildContext context) {
    final reminder = reminderDateTime;
    final hasReminder = reminder != null;
    // ارتفاع الـ badge + padding أسفله
    const badgeBottomPadding = 60.0;

    Widget content =
        _buildContent(context, hasReminder ? badgeBottomPadding : 0);

    if (!hasReminder) return content;

    return Stack(
      children: [
        content,
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _ReminderBadge(
            reminderDateTime: reminder,
            textColor: textColor,
            noteColor: noteColor,
            onRemove: onRemoveReminder,
          ),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, double extraBottomPadding) {
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
        padding: EdgeInsets.only(top: 12, bottom: 80 + extraBottomPadding),
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
              padding:
                  EdgeInsets.only(top: 20, bottom: 80 + extraBottomPadding),
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
              padding:
                  EdgeInsets.only(top: 20, bottom: 40 + extraBottomPadding),
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

// ─── Reminder Badge ───────────────────────────────────────────────
class _ReminderBadge extends StatelessWidget {
  final DateTime reminderDateTime;
  final Color textColor;
  final Color noteColor;
  final VoidCallback? onRemove;

  const _ReminderBadge({
    required this.reminderDateTime,
    required this.textColor,
    required this.noteColor,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final now = DateTime.now();
    final diff = reminderDateTime.difference(now);
    final isPast = diff.isNegative;

    String timeText;
    if (isPast) {
      final ago = now.difference(reminderDateTime);
      if (ago.inMinutes < 60) {
        timeText =
            isAr ? 'منذ ${ago.inMinutes} دقيقة' : '${ago.inMinutes}m ago';
      } else if (ago.inHours < 24) {
        timeText = isAr ? 'منذ ${ago.inHours} ساعة' : '${ago.inHours}h ago';
      } else {
        timeText = isAr ? 'منذ ${ago.inDays} يوم' : '${ago.inDays}d ago';
      }
    } else if (diff.inMinutes < 60) {
      timeText =
          isAr ? 'خلال ${diff.inMinutes} دقيقة' : 'In ${diff.inMinutes}m';
    } else if (diff.inHours < 24) {
      timeText = isAr ? 'خلال ${diff.inHours} ساعة' : 'In ${diff.inHours}h';
    } else if (diff.inDays == 1) {
      timeText = isAr ? 'غداً' : 'Tomorrow';
    } else {
      timeText = isAr ? 'بعد ${diff.inDays} أيام' : 'In ${diff.inDays}d';
    }

    final hour = reminderDateTime.hour.toString().padLeft(2, '0');
    final minute = reminderDateTime.minute.toString().padLeft(2, '0');
    final d = reminderDateTime;
    final dateStr = '${d.day}/${d.month}/${d.year}  $hour:$minute';

    final isDark = noteColor.computeLuminance() < 0.5;
    // خلفية معتمة بلون النوتة + طبقة خفيفة للتمييز
    final bgColor = isDark
        ? Color.alphaBlend(Colors.white.withValues(alpha: 0.15), noteColor)
        : Color.alphaBlend(Colors.black.withValues(alpha: 0.1), noteColor);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.25)
        : Colors.black.withValues(alpha: 0.18);
    final iconColor = isPast
        ? textColor.withValues(alpha: 0.6)
        : textColor.withValues(alpha: 0.9);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPast ? Icons.alarm_off_rounded : Icons.alarm_rounded,
            size: 16,
            color: iconColor,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              '$timeText  •  $dateStr',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: textColor.withValues(alpha: isPast ? 0.6 : 0.9),
                height: 1.2,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (onRemove != null) ...[
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onRemove,
              child: Icon(
                Icons.close_rounded,
                size: 15,
                color: textColor.withValues(alpha: 0.5),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
