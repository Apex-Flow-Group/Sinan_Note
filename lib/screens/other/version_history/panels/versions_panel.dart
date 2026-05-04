// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:apex_note/models/note.dart';
import 'package:apex_note/models/note_version.dart';
import 'package:apex_note/screens/other/version_history/version_history_controller.dart';
import 'package:flutter/material.dart';

class VersionsPanel extends StatelessWidget {
  final Note selectedNote;
  final List<NoteVersion> versions;
  final bool loading;
  final NoteVersion? selectedVersion;
  final bool isWide;
  final void Function(NoteVersion) onSelectVersion;
  final VoidCallback onBack;

  const VersionsPanel({
    super.key,
    required this.selectedNote,
    required this.versions,
    required this.loading,
    required this.selectedVersion,
    required this.isWide,
    required this.onSelectVersion,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (loading) return const Center(child: CircularProgressIndicator());
    if (versions.isEmpty) {
      return Center(child: Text(l10n.noHistory, style: Theme.of(context).textTheme.bodyLarge));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(isWide ? 16 : 4, 10, 16, 6),
          child: Row(
            children: [
              if (!isWide)
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                  onPressed: onBack,
                ),
              Expanded(
                child: Text(
                  selectedNote.title.isEmpty ? l10n.untitled : selectedNote.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            itemCount: versions.length,
            itemBuilder: (_, i) => _VersionItem(
              version: versions[i],
              isSelected: selectedVersion?.id == versions[i].id,
              onTap: () => onSelectVersion(versions[i]),
            ),
          ),
        ),
      ],
    );
  }
}

class _VersionItem extends StatelessWidget {
  final NoteVersion version;
  final bool isSelected;
  final VoidCallback onTap;

  const _VersionItem({required this.version, required this.isSelected, required this.onTap});

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
    final actionColor = VersionHistoryController.getActionColor(version.action);
    final actionIcon = VersionHistoryController.getActionIcon(version.action);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isSelected ? 3 : 0.5,
      color: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: actionColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(actionIcon, color: actionColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      version.title.isEmpty ? l10n.untitled : version.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 3),
                    Text(_formatTimeAgo(context, version.timestamp),
                        style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.primary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
