
import 'package:flutter/material.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';

class SelectionActionBar extends StatelessWidget {
  final ValueNotifier<Set<int>> selectedIdsNotifier;  // 🔥 FIX: Use notifier directly
  final VoidCallback onClear;
  final VoidCallback onPin;
  final VoidCallback onArchive;
  final VoidCallback onDelete;
  final VoidCallback? onShare;
  final VoidCallback? onCategory;
  final bool isDark;
  final bool allPinned;

  const SelectionActionBar({
    super.key,
    required this.selectedIdsNotifier,
    required this.onClear,
    required this.onPin,
    required this.onArchive,
    required this.onDelete,
    required this.onShare,
    this.onCategory,
    required this.isDark,
    this.allPinned = false,
  });

  void _confirmAction(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
    required VoidCallback onConfirm,
  }) {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 32),
              ),
              const SizedBox(height: 16),
              Text(title, style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(message, style: TextStyle(color: cs.onSurface.withValues(alpha: 0.6))),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(AppLocalizations.of(ctx)!.cancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        onConfirm();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: confirmColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 48),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(confirmLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Set<int>>(
      valueListenable: selectedIdsNotifier,  // 🔥 Listen directly
      builder: (context, selectedIds, _) {
        return Container(
          height: 60,
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[850] : Colors.grey[200],
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: onClear,
                tooltip: 'Clear',
              ),
              Expanded(
                child: Text(
                  '${selectedIds.length}',  // 🔥 Read from live data
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: Icon(allPinned ? Icons.push_pin : Icons.push_pin_outlined),
                onPressed: onPin,
                tooltip: allPinned ? 'Unpin' : 'Pin',
              ),
              IconButton(
                icon: const Icon(Icons.archive_outlined),
                onPressed: () => _confirmAction(
                  context,
                  icon: Icons.archive_outlined,
                  iconColor: Colors.orange,
                  title: AppLocalizations.of(context)!.archive,
                  message: '${selectedIds.length} ${AppLocalizations.of(context)!.notesArchived}',
                  confirmLabel: AppLocalizations.of(context)!.archive,
                  confirmColor: Colors.orange,
                  onConfirm: onArchive,
                ),
                tooltip: 'Archive',
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _confirmAction(
                  context,
                  icon: Icons.delete_outline_rounded,
                  iconColor: Colors.red,
                  title: AppLocalizations.of(context)!.deleteNote,
                  message: '${selectedIds.length} ${AppLocalizations.of(context)!.notesDeleted}',
                  confirmLabel: AppLocalizations.of(context)!.delete,
                  confirmColor: Colors.red,
                  onConfirm: onDelete,
                ),
                tooltip: 'Delete',
              ),
              IconButton(
                icon: const Icon(Icons.label_outline),
                onPressed: onCategory,
                tooltip: 'Category',
                color: onCategory == null ? Colors.grey : null,
              ),
              IconButton(
                icon: const Icon(Icons.share_outlined),
                onPressed: onShare,
                tooltip: 'Share',
                color: onShare == null ? Colors.grey : null,
              ),
              const SizedBox(width: 8),
            ],
          ),
        );
      },
    );
  }
}

