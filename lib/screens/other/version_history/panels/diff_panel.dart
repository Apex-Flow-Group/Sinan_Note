// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:sinan_note/controllers/version_history/version_history_controller.dart';
import 'package:sinan_note/core/utils/note_content_utils.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';
import 'package:sinan_note/models/note.dart';
import 'package:sinan_note/models/note_version.dart';
import 'package:sinan_note/widgets/editor/diff_view.dart';

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
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final idx = allVersions.indexWhere((v) => v.id == version.id);
    final older = idx < allVersions.length - 1 ? allVersions[idx + 1] : null;
    final newText = NoteContentUtils.toDisplayText(version.content);
    final oldText =
        older != null ? NoteContentUtils.toDisplayText(older.content) : '';
    final spans = older != null ? computeDiff(oldText, newText) : null;
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
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(_formatTimeAgo(context, version.timestamp),
                        style:
                            TextStyle(fontSize: 13, color: Colors.grey[600])),
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
        if (spans != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                _legendDot(const Color(0xFF2E7D32), const Color(0xFFE8F5E9)),
                const SizedBox(width: 4),
                Text(l10n.added, style: const TextStyle(fontSize: 13)),
                const SizedBox(width: 12),
                _legendDot(const Color(0xFFC62828), const Color(0xFFFFEBEE)),
                const SizedBox(width: 4),
                Text(l10n.deleted, style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
        const Divider(height: 1),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.maxFinite,
              child: spans != null
                  ? DiffView(spans: spans)
                  : Text(newText.isEmpty ? l10n.noHistory : newText,
                      style: const TextStyle(fontSize: 15, height: 1.6)),
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
