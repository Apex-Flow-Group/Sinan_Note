// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:sinan_note/domain/models/note.dart';
import 'package:sinan_note/domain/models/note_version.dart';
import 'package:sinan_note/domain/text/note_text.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';
import 'package:sinan_note/ui/core/theme/app_colors.dart';
import 'package:sinan_note/ui/features/editor/widgets/diff_view.dart';
import 'package:sinan_note/ui/features/version_history/view_models/version_history_controller.dart';

class DiffPanel extends StatelessWidget {
  final NoteVersion version;
  final Note note;
  final List<NoteVersion> allVersions;
  final bool isWide;
  final Future<void> Function(NoteVersion, Note) onRestore;
  final VoidCallback onBack;

  const DiffPanel({
    super.key,
    required this.version,
    required this.note,
    required this.allVersions,
    required this.isWide,
    required this.onRestore,
    required this.onBack,
  });

  String _formatTimeAgo(BuildContext context, DateTime dt) {
    final diff = DateTime.now().difference(dt);
    final l10n = AppLocalizations.of(context)!;
    if (diff.inMinutes < 1) return l10n.justNow;
    if (diff.inHours < 1) return l10n.minutesAgo(diff.inMinutes);
    if (diff.inDays < 1) return l10n.hoursAgo(diff.inHours);
    if (diff.inDays < 7) return l10n.daysAgo(diff.inDays);
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final idx = allVersions.indexWhere((v) => v.id == version.id);
    final older = idx < allVersions.length - 1 ? allVersions[idx + 1] : null;
    final newText = NoteText.toDisplayText(version.content);
    final oldText = older != null ? NoteText.toDisplayText(older.content) : '';
    final actionColor = VersionHistoryController.getActionColor(version.action);
    final actionIcon = VersionHistoryController.getActionIcon(version.action);

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(isWide ? 16 : 4, 14, 8, 10),
          child: Row(
            children: [
              if (!isWide)
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                  onPressed: onBack,
                ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: actionColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(actionIcon, color: actionColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(version.title.isEmpty ? l10n.untitled : version.title,
                        style: context.text.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(_formatTimeAgo(context, version.timestamp),
                        style: context.text.bodySmall
                            ?.copyWith(color: context.colors.muted)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.restore, size: 22),
                tooltip: l10n.restore,
                onPressed: () => onRestore(version, note),
              ),
            ],
          ),
        ),
        if (older != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                _legendDot(
                    context.colors.success, context.colors.successContainer),
                const SizedBox(width: 4),
                Text(l10n.added, style: context.text.bodySmall),
                const SizedBox(width: 12),
                _legendDot(
                    context.colors.danger, context.colors.dangerContainer),
                const SizedBox(width: 4),
                Text(l10n.deleted, style: context.text.bodySmall),
              ],
            ),
          ),
        const Divider(height: 1),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.maxFinite,
              child: older != null
                  ? DiffView(oldText: oldText, newText: newText)
                  : Text(newText.isEmpty ? l10n.noHistory : newText,
                      style: context.text.titleSmall?.copyWith(
                          fontWeight: FontWeight.normal, height: 1.6)),
            ),
          ),
        ),
      ],
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
}
