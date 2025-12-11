// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';

class ChecklistBottomBar extends StatelessWidget {
  final Color backgroundColor;
  final Color textColor;
  final bool hasContent;
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
  final VoidCallback onBackgroundColorTap;
  final VoidCallback onShareTap;
  final VoidCallback onArchiveTap;
  final VoidCallback onDeleteTap;

  const ChecklistBottomBar({
    super.key,
    required this.backgroundColor,
    required this.textColor,
    required this.hasContent,
    this.onUndo,
    this.onRedo,
    required this.onBackgroundColorTap,
    required this.onShareTap,
    required this.onArchiveTap,
    required this.onDeleteTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
            top:
                BorderSide(color: textColor.withValues(alpha: 0.08), width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.palette_outlined, color: textColor),
                  onPressed: onBackgroundColorTap,
                  tooltip: 'Background Color',
                ),
                IconButton(
                  icon: Icon(Icons.undo_rounded,
                      color: onUndo != null ? textColor : Colors.grey),
                  onPressed: onUndo,
                  tooltip: 'Undo',
                ),
                IconButton(
                  icon: Icon(Icons.redo_rounded,
                      color: onRedo != null ? textColor : Colors.grey),
                  onPressed: onRedo,
                  tooltip: 'Redo',
                ),
              ],
            ),
            Flexible(
              child: Builder(
                builder: (ctx) => Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      final RenderBox button =
                          ctx.findRenderObject() as RenderBox;
                      final RenderBox overlay = Overlay.of(context)
                          .context
                          .findRenderObject() as RenderBox;
                      final RelativeRect position = RelativeRect.fromRect(
                        Rect.fromPoints(
                          button.localToGlobal(Offset.zero, ancestor: overlay),
                          button.localToGlobal(
                              button.size.bottomRight(Offset.zero),
                              ancestor: overlay),
                        ),
                        Offset.zero & overlay.size,
                      );
                      showMenu(
                        context: context,
                        position: position,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF2D2D2D)
                            : Colors.white,
                        elevation: 8,
                        items: [
                          PopupMenuItem(
                            value: 'share',
                            enabled: hasContent,
                            child: Row(
                              children: [
                                Icon(Icons.share_outlined,
                                    size: 20,
                                    color: hasContent ? null : Colors.grey),
                                const SizedBox(width: 12),
                                Text(l10n.actionShare,
                                    style: TextStyle(
                                        color:
                                            hasContent ? null : Colors.grey)),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'archive',
                            enabled: hasContent,
                            child: Row(
                              children: [
                                Icon(Icons.archive_outlined,
                                    size: 20,
                                    color: hasContent ? null : Colors.grey),
                                const SizedBox(width: 12),
                                Text(l10n.actionArchive,
                                    style: TextStyle(
                                        color:
                                            hasContent ? null : Colors.grey)),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            enabled: hasContent,
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline_rounded,
                                    color:
                                        hasContent ? Colors.red : Colors.grey,
                                    size: 20),
                                const SizedBox(width: 12),
                                Text(l10n.actionDelete,
                                    style: TextStyle(
                                        color: hasContent
                                            ? Colors.red
                                            : Colors.grey)),
                              ],
                            ),
                          ),
                        ],
                      ).then((value) {
                        if (value == 'share') {
                          onShareTap();
                        } else if (value == 'archive') {
                          onArchiveTap();
                        } else if (value == 'delete') {
                          onDeleteTap();
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: textColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: textColor.withValues(alpha: 0.2), width: 1),
                      ),
                      child: Icon(Icons.more_vert_rounded,
                          color: textColor, size: 22),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
