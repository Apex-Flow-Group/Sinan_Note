// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sinan_note/domain/models/note_version.dart';
import 'package:sinan_note/domain/text/note_text.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';
import 'package:sinan_note/ui/core/platform/platform_helper.dart';
import 'package:sinan_note/ui/core/theme/app_colors.dart';
import 'package:sinan_note/ui/core/widgets/unified_notification_service.dart';
import 'package:sinan_note/ui/features/editor/widgets/diff_view.dart';
import 'package:sinan_note/ui/features/notes/view_models/notes_provider.dart';

// ── Main Sheet ───────────────────────────────────────────────────────────────
class NoteHistorySheet extends StatelessWidget {
  final int noteId;

  const NoteHistorySheet({super.key, required this.noteId});

  static void show(BuildContext context, int noteId) {
    final isDesktop = PlatformHelper.isWideDisplay(context);

    if (isDesktop) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: SizedBox(
            width: 560,
            height: 600,
            child: NoteHistorySheet(noteId: noteId),
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) => SafeArea(
          top: false,
          child: NoteHistorySheet(noteId: noteId),
        ),
      );
    }
  }

  String _toPlainText(String content) => NoteText.toDisplayText(content);

  void _showDiffDialog(
      BuildContext context, NoteVersion version, String newerContent) {
    final l10n = AppLocalizations.of(context)!;
    final oldText = _toPlainText(version.content);
    final newText = _toPlainText(newerContent);

    final screenSize = MediaQuery.of(context).size;
    final isSmall = screenSize.width < 600;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: EdgeInsets.symmetric(
          horizontal: isSmall ? 16 : 40,
          vertical: isSmall ? 24 : 40,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 600,
            maxHeight: screenSize.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
                child: Row(
                  children: [
                    const Icon(Icons.compare, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(l10n.preview,
                          style: ctx.text.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _legendDot(ctx.colors.success, ctx.colors.successContainer),
                    const SizedBox(width: 4),
                    Text(l10n.added, style: ctx.text.labelMedium),
                    const SizedBox(width: 12),
                    _legendDot(ctx.colors.danger, ctx.colors.dangerContainer),
                    const SizedBox(width: 4),
                    Text(l10n.deleted, style: ctx.text.labelMedium),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.maxFinite,
                    child: DiffView(oldText: oldText, newText: newText),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _legendDot(Color fg, Color bg) => Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            border: Border.all(color: fg, width: 1.5)),
      );

  @override
  Widget build(BuildContext context) {
    final isDesktop = PlatformHelper.isWideDisplay(context);

    if (isDesktop) {
      return _buildContent(context, null);
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      maxChildSize: 0.8,
      minChildSize: 0.3,
      builder: (_, scrollController) =>
          _buildContent(context, scrollController),
    );
  }

  Widget _buildContent(
      BuildContext context, ScrollController? scrollController) {
    final isDesktop = scrollController == null;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: isDesktop
            ? BorderRadius.circular(16)
            : const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          if (!isDesktop)
            Container(
              margin: const EdgeInsets.all(8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.scheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
            child: Row(
              children: [
                Icon(Icons.history_edu, color: context.scheme.primary),
                const SizedBox(width: 8),
                Text(
                  l10n.noteHistory,
                  style: context.text.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (isDesktop)
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: FutureBuilder<List<NoteVersion>>(
              future: context.read<NotesProvider>().history(noteId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final history = snapshot.data!;

                if (history.isEmpty) {
                  return Center(child: Text(l10n.noHistoryYet));
                }

                return ListView.builder(
                  controller: scrollController,
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final item = history[index];
                    final date = item.timestamp;
                    final isCreate = item.action == 'create';
                    final rawContent = _toPlainText(item.content);
                    final contentPreview = rawContent.replaceAll('\n', ' ');
                    // newerContent: النسخة الأحدث منها (index-1) أو نفسها إن كانت الأحدث
                    final newerContent =
                        index == 0 ? item.content : history[index - 1].content;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isCreate
                            ? context.colors.successContainer
                            : context.scheme.primaryContainer,
                        child: Icon(
                          isCreate ? Icons.add_circle_outline : Icons.edit,
                          color: isCreate
                              ? context.colors.success
                              : context.scheme.primary,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        isCreate ? l10n.created : l10n.edit,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${date.year}-${date.month}-${date.day}  ${date.hour}:${date.minute}",
                            style: context.text.bodySmall
                                ?.copyWith(color: context.colors.muted),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            contentPreview,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: context.text.bodyMedium?.fontSize,
                              color: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.color
                                  ?.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (index != 0)
                            IconButton(
                              icon: const Icon(Icons.compare, size: 20),
                              tooltip: l10n.preview,
                              onPressed: () =>
                                  _showDiffDialog(context, item, newerContent),
                            ),
                          IconButton(
                            icon: const Icon(Icons.copy, size: 20),
                            onPressed: () {
                              final textToCopy = _toPlainText(item.content);
                              Clipboard.setData(
                                  ClipboardData(text: textToCopy));
                              Navigator.pop(context);
                              UnifiedNotificationService.of(context).show(
                                context: context,
                                message: l10n.copiedOldVersion,
                                type: NotificationType.success,
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
