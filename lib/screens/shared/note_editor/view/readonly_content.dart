// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:sinan_note/core/constants/app_text_styles.dart';
import 'package:sinan_note/core/utils/text_direction_utils.dart';
import 'package:sinan_note/models/note_mode.dart';
import 'package:sinan_note/screens/shared/note_editor/core/editor_coordinator.dart';
import 'package:sinan_note/screens/shared/note_editor/view/readonly_checklist_view.dart';
import 'package:sinan_note/widgets/editor/markdown_viewer.dart';

/// يعرض محتوى الملاحظة في وضع العرض حسب النوع
class ReadOnlyContent extends StatefulWidget {
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
  final VoidCallback? onEditReminder;

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
    this.onEditReminder,
  });

  @override
  State<ReadOnlyContent> createState() => _ReadOnlyContentState();
}

class _ReadOnlyContentState extends State<ReadOnlyContent> {
  String? _plainText;

  @override
  void initState() {
    super.initState();
    _extractPlainText();
  }

  @override
  void didUpdateWidget(ReadOnlyContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.quillKey != widget.quillKey) {
      _extractPlainText();
    }
  }

  Future<void> _extractPlainText() async {
    if (widget.mode == NoteMode.checklist ||
        widget.mode == NoteMode.code ||
        widget.showMarkdown) {
      return;
    }

    final raw = widget.coordinator.contentController.text;

    // نستخرج النص في postFrameCallback لعدم تجميد أول frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      String text;
      if (raw.trimLeft().startsWith('[')) {
        try {
          text = (jsonDecode(raw) as List)
              .where((op) => op is Map && op['insert'] is String)
              .map((op) => op['insert'] as String)
              .join()
              .trimRight();
        } catch (_) {
          text = raw.trimRight();
        }
      } else {
        text = raw.trimRight();
      }
      setState(() => _plainText = text);
    });
  }

  @override
  Widget build(BuildContext context) {
    final reminder = widget.reminderDateTime;
    final hasReminder = reminder != null;
    const double badgeBottomPadding = 60.0;

    final content = _buildContent(context, hasReminder ? badgeBottomPadding : 0);
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
            textColor: widget.textColor,
            noteColor: widget.noteColor,
            onRemove: widget.onRemoveReminder,
            onEdit: widget.onEditReminder,
          ),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, double extraBottomPadding) {
    if (widget.mode == NoteMode.checklist) {
      return ReadOnlyChecklistView(
        coordinator: widget.coordinator,
        textColor: widget.textColor,
        noteColor: widget.noteColor,
        scrollController: widget.scrollController,
        onSave: widget.onSave,
        isTrashed: widget.isTrashed,
      );
    }

    if (widget.showMarkdown) {
      final content = widget.coordinator.codeController?.text ??
          widget.coordinator.contentController.text;
      return Padding(
        padding: EdgeInsets.only(top: 12, bottom: 80 + extraBottomPadding),
        child: MarkdownViewer(content: content, textColor: widget.textColor),
      );
    }

    if (widget.mode == NoteMode.code) {
      final content = widget.coordinator.codeController?.text ??
          widget.coordinator.contentController.text;
      return ScrollbarTheme(
        data: const ScrollbarThemeData(thickness: WidgetStatePropertyAll(0)),
        child: SingleChildScrollView(
          controller: widget.scrollController,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Padding(
              padding: EdgeInsets.only(top: 20, bottom: 80 + extraBottomPadding),
              child: SelectableText(
                content,
                style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                    height: 1.6,
                    color: widget.textColor),
              ),
            ),
          ),
        ),
      );
    }

    // ── وضع العرض: plain text بدل QuillEditor ──────────────────────
    if (_plainText == null) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    final fontFamily = Theme.of(context).textTheme.bodyMedium?.fontFamily;
    const double fontSize = AppFontSize.noteBody;
    final paragraphs = _plainText!.split('\n');

    return ScrollbarTheme(
      data: const ScrollbarThemeData(thickness: WidgetStatePropertyAll(0)),
      child: ListView.builder(
        controller: widget.scrollController,
        padding: EdgeInsets.only(top: 20, bottom: 40 + extraBottomPadding),
        itemCount: paragraphs.length,
        itemBuilder: (_, i) {
          final para = paragraphs[i];
          final dir = TextDirectionUtils.getDirectionForParagraph(para);
          return Directionality(
            textDirection: dir,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: SelectableText(
                para,
                style: TextStyle(
                  fontSize: fontSize,
                  fontFamily: fontFamily,
                  height: AppLineHeight.body(1.0, fontFamily),
                  color: widget.textColor,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Reminder Badge ───────────────────────────────────────────────
class _ReminderBadge extends StatelessWidget {
  final DateTime reminderDateTime;
  final Color textColor;
  final Color noteColor;
  final VoidCallback? onRemove;
  final VoidCallback? onEdit;

  const _ReminderBadge({
    required this.reminderDateTime,
    required this.textColor,
    required this.noteColor,
    this.onRemove,
    this.onEdit,
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
        timeText = isAr ? 'منذ ${ago.inMinutes} دقيقة' : '${ago.inMinutes}m ago';
      } else if (ago.inHours < 24) {
        timeText = isAr ? 'منذ ${ago.inHours} ساعة' : '${ago.inHours}h ago';
      } else {
        timeText = isAr ? 'منذ ${ago.inDays} يوم' : '${ago.inDays}d ago';
      }
    } else if (diff.inMinutes < 60) {
      timeText = isAr ? 'خلال ${diff.inMinutes} دقيقة' : 'In ${diff.inMinutes}m';
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
    final bgColor = isDark
        ? Color.alphaBlend(Colors.white.withValues(alpha: 0.15), noteColor)
        : Color.alphaBlend(Colors.black.withValues(alpha: 0.1), noteColor);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.25)
        : Colors.black.withValues(alpha: 0.18);
    final dimText = textColor.withValues(alpha: isPast ? 0.55 : 0.85);
    final dimIcon = textColor.withValues(alpha: 0.45);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              child: Row(
                children: [
                  Icon(
                    isPast ? Icons.alarm_off_rounded : Icons.alarm_rounded,
                    size: 16,
                    color: dimText,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      '$timeText  •  $dateStr',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: dimText,
                        height: 1.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(width: 1, height: 30, color: borderColor),
          if (onEdit != null)
            _IconBtn(icon: Icons.tune_rounded, color: dimIcon, onTap: onEdit!),
          if (onEdit != null && onRemove != null)
            Container(width: 1, height: 30, color: borderColor),
          if (onRemove != null)
            _IconBtn(
                icon: Icons.delete_outline_rounded,
                color: dimIcon,
                onTap: onRemove!),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}
