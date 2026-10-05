// Copyright © 2025 Apex Flow Group. All rights reserved.


import 'package:flutter/material.dart';
import 'package:sinan_note/domain/models/note.dart';
import 'package:sinan_note/domain/models/note_version.dart';
import 'package:sinan_note/domain/text/checklist.dart';
import 'package:sinan_note/domain/text/note_text.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';
import 'package:sinan_note/ui/core/theme/app_colors.dart';
import 'package:sinan_note/widgets/editor/diff_view.dart';
import 'package:sinan_note/widgets/home/note_card_utils.dart';

class VersionsBottomSheet extends StatelessWidget {
  final Note note;
  final List<NoteVersion> versions;
  final int totalVersions;
  final ScrollController scrollController;
  final Function(NoteVersion) onRestore;
  final bool isDesktop;

  const VersionsBottomSheet({
    super.key,
    required this.note,
    required this.versions,
    required this.totalVersions,
    required this.scrollController,
    required this.onRestore,
    this.isDesktop = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        if (!isDesktop)
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 16),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: context.scheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        Padding(
          padding: EdgeInsets.fromLTRB(20, isDesktop ? 12 : 0, 8, 0),
          child: Row(
            children: [
              const Icon(Icons.history, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.noteHistory,
                  style: context.text.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: context.scheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '$totalVersions',
                  style: context.text.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.scheme.primary),
                ),
              ),
              if (isDesktop)
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
            ],
          ),
        ),
        if (isDesktop) const Divider(height: 1),
        const SizedBox(height: 8),
        Expanded(
          child: versions.isEmpty
              ? Center(child: Text(l10n.noHistory))
              : ListView.builder(
                  controller: scrollController,
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: MediaQuery.of(context).padding.bottom + 16,
                  ),
                  itemCount: versions.length,
                  itemBuilder: (context, index) {
                    final version = versions[index];
                    final timeAgo = _formatTimeAgo(context, version.timestamp);
                    final actionIcon = _getActionIcon(version.action);
                    final actionColor =
                        _getActionColor(context, version.action);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: actionColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(actionIcon,
                                  color: actionColor, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    version.title.isEmpty
                                        ? l10n.untitled
                                        : version.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(timeAgo,
                                      style: context.text.labelMedium?.copyWith(
                                          color: context.colors.muted)),
                                ],
                              ),
                            ),
                            if (index < versions.length - 1)
                              IconButton(
                                icon: const Icon(Icons.compare, size: 20),
                                tooltip: l10n.preview,
                                onPressed: () => _showDiffDialog(context,
                                    versions[index + 1], version, l10n),
                              ),
                            IconButton(
                              icon: const Icon(Icons.visibility_outlined,
                                  size: 20),
                              onPressed: () =>
                                  _showVersionPreview(context, version, l10n),
                            ),
                            IconButton(
                              icon: const Icon(Icons.restore, size: 20),
                              onPressed: () => onRestore(version),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  IconData _getActionIcon(String action) {
    switch (action) {
      case 'manual_save':
        return Icons.save;
      case 'auto_save':
        return Icons.update;
      case 'created':
        return Icons.add_circle;
      case 'archived':
        return Icons.archive;
      case 'restored':
        return Icons.restore;
      default:
        return Icons.edit;
    }
  }

  Color _getActionColor(BuildContext context, String action) {
    switch (action) {
      case 'manual_save':
        return context.colors.success;
      case 'auto_save':
        return context.scheme.primary;
      case 'created':
        return context.scheme.secondary;
      case 'archived':
        return context.colors.warning;
      case 'restored':
        return context.scheme.tertiary;
      default:
        return context.colors.muted;
    }
  }

  String _toPlainText(String content) =>
      NoteText.toDisplayText(content);
  void _showDiffDialog(BuildContext context, NoteVersion older,
      NoteVersion newer, AppLocalizations l10n) {
    final oldText = _toPlainText(older.content);
    final newText = _toPlainText(newer.content);
    final spans = computeDiff(oldText, newText);
    final isSmall = MediaQuery.of(context).size.width < 600;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: EdgeInsets.symmetric(
            horizontal: isSmall ? 16 : 40, vertical: isSmall ? 24 : 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxWidth: 600,
              maxHeight: MediaQuery.of(context).size.height * 0.8),
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
                        onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _legendDot(
                        ctx.colors.success, ctx.colors.successContainer),
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
                      width: double.maxFinite, child: DiffView(spans: spans)),
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
          border: Border.all(color: fg, width: 1.5),
        ),
      );

  void _showVersionPreview(
      BuildContext context, NoteVersion version, AppLocalizations l10n) {
    final isChecklist = ChecklistFormatter.isValidChecklist(version.content);
    final displayContent = _toPlainText(version.content);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(version.title.isEmpty ? l10n.untitled : version.title),
        content: SingleChildScrollView(
          child: isChecklist
              ? NoteCardUtils.buildChecklistPreview(
                  version.content, Theme.of(ctx).textTheme.bodyMedium!.color!)
              : Text(displayContent.isEmpty ? l10n.noHistory : displayContent),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: Text(l10n.close)),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onRestore(version);
            },
            child: Text(l10n.restore),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(BuildContext context, DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    final l10n = AppLocalizations.of(context)!;
    if (diff.inMinutes < 1) return l10n.justNow;
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}

