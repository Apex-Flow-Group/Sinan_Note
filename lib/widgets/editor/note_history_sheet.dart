// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:convert';

import 'package:apex_note/core/utils/checklist_formatter.dart';
import 'package:apex_note/core/utils/quill_migration.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:apex_note/models/note_version.dart';
import 'package:apex_note/services/storage/isar_database_service.dart';
import 'package:apex_note/services/unified_notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ── Diff types ──────────────────────────────────────────────────────────────
enum _DiffType { equal, added, removed }

class _DiffSpan {
  final _DiffType type;
  final String text;
  const _DiffSpan(this.type, this.text);
}

// ── Word-level LCS diff ──────────────────────────────────────────────────────
List<_DiffSpan> _computeDiff(String oldText, String newText) {
  final a = oldText.split(RegExp(r'(?<=\s)|(?=\s)'));
  final b = newText.split(RegExp(r'(?<=\s)|(?=\s)'));

  final m = a.length, n = b.length;
  // LCS table
  final dp = List.generate(m + 1, (_) => List.filled(n + 1, 0));
  for (var i = m - 1; i >= 0; i--) {
    for (var j = n - 1; j >= 0; j--) {
      if (a[i] == b[j]) {
        dp[i][j] = dp[i + 1][j + 1] + 1;
      } else {
        dp[i][j] = dp[i + 1][j] > dp[i][j + 1] ? dp[i + 1][j] : dp[i][j + 1];
      }
    }
  }

  final spans = <_DiffSpan>[];
  var i = 0, j = 0;
  while (i < m && j < n) {
    if (a[i] == b[j]) {
      spans.add(_DiffSpan(_DiffType.equal, a[i]));
      i++;
      j++;
    } else if (dp[i + 1][j] >= dp[i][j + 1]) {
      spans.add(_DiffSpan(_DiffType.removed, a[i]));
      i++;
    } else {
      spans.add(_DiffSpan(_DiffType.added, b[j]));
      j++;
    }
  }
  while (i < m) {
    spans.add(_DiffSpan(_DiffType.removed, a[i++]));
  }
  while (j < n) {
    spans.add(_DiffSpan(_DiffType.added, b[j++]));
  }
  return spans;
}

// ── Diff View Widget ─────────────────────────────────────────────────────────
class _DiffView extends StatelessWidget {
  final List<_DiffSpan> spans;
  const _DiffView({required this.spans});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: spans.map((s) {
          switch (s.type) {
            case _DiffType.added:
              return TextSpan(
                text: s.text,
                style: const TextStyle(
                  color: Color(0xFF2E7D32),
                  backgroundColor: Color(0xFFE8F5E9),
                  fontWeight: FontWeight.w500,
                ),
              );
            case _DiffType.removed:
              return TextSpan(
                text: s.text,
                style: const TextStyle(
                  color: Color(0xFFC62828),
                  backgroundColor: Color(0xFFFFEBEE),
                  decoration: TextDecoration.lineThrough,
                ),
              );
            case _DiffType.equal:
              return TextSpan(text: s.text);
          }
        }).toList(),
      ),
      style: const TextStyle(fontSize: 14, height: 1.6),
    );
  }
}

// ── Main Sheet ───────────────────────────────────────────────────────────────
class NoteHistorySheet extends StatelessWidget {
  final int noteId;

  const NoteHistorySheet({super.key, required this.noteId});

  static void show(BuildContext context, int noteId) {
    final isDesktop = MediaQuery.of(context).size.width >= 600;

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
        builder: (context) => NoteHistorySheet(noteId: noteId),
      );
    }
  }

  String _toPlainText(String content) {
    debugPrint('[History] raw content: ${content.substring(0, content.length.clamp(0, 100))}');
    if (ChecklistFormatter.isValidChecklist(content)) {
      debugPrint('[History] detected: checklist');
      return ChecklistFormatter.toDisplayText(content);
    }
    if (QuillMigration.isDelta(content)) {
      debugPrint('[History] detected: delta JSON');
      try {
        final list = jsonDecode(content) as List;
        final buffer = StringBuffer();
        for (final op in list) {
          if (op is Map && op['insert'] is String) {
            buffer.write(op['insert'] as String);
          }
        }
        final result = buffer.toString().trimRight();
        debugPrint('[History] converted to: ${result.substring(0, result.length.clamp(0, 100))}');
        return result;
      } catch (e) {
        debugPrint('[History] delta parse error: $e');
      }
    }
    debugPrint('[History] detected: plain text');
    return content;
  }

  void _showDiffDialog(
      BuildContext context, NoteVersion version, String newerContent) {
    final l10n = AppLocalizations.of(context)!;
    final oldText = _toPlainText(version.content);
    final newText = _toPlainText(newerContent);
    final spans = _computeDiff(oldText, newText);

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
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
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
                    _legendDot(
                        const Color(0xFF2E7D32), const Color(0xFFE8F5E9)),
                    const SizedBox(width: 4),
                    Text(l10n.added, style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 12),
                    _legendDot(
                        const Color(0xFFC62828), const Color(0xFFFFEBEE)),
                    const SizedBox(width: 4),
                    Text(l10n.deleted, style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.maxFinite,
                    child: _DiffView(spans: spans),
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
    final isDesktop = MediaQuery.of(context).size.width >= 600;

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
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
            child: Row(
              children: [
                const Icon(Icons.history_edu, color: Colors.blueAccent),
                const SizedBox(width: 8),
                Text(
                  l10n.noteHistory,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18),
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
              future: IsarDatabaseService().getNoteHistory(noteId),
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
                        backgroundColor:
                            isCreate ? Colors.green[100] : Colors.blue[100],
                        child: Icon(
                          isCreate ? Icons.add_circle_outline : Icons.edit,
                          color: isCreate ? Colors.green : Colors.blue,
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
                            style: const TextStyle(
                                fontSize: 13, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            contentPreview,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
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
                              UnifiedNotificationService().show(
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
