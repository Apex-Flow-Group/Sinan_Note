// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/note.dart';
import '../../services/notes_provider.dart';
import '../../services/settings_provider.dart';
import '../../services/language_detector.dart';
import '../../utils/adaptive_color.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import '../../screens/note_view_screen.dart';
import '../../screens/note_editor.dart';
import '../../screens/home_screen.dart' show ViewType;
import '../../models/note_mode.dart';
import '../../utils/checklist_formatter.dart';
import '../../services/toast_service.dart';
import '../premium_card_effect.dart';
import '../custom_share_sheet.dart';

class NoteCardWidget extends StatefulWidget {
  final Note note;
  final ViewType viewType;
  final ValueNotifier<int> closeAllSlidables;
  final VoidCallback onNoteChanged;
  final VoidCallback onLongPress;
  final VoidCallback? onTap;
  final bool isSelected;
  final bool selectionMode;
  final String source;

  const NoteCardWidget({
    super.key,
    required this.note,
    required this.viewType,
    required this.closeAllSlidables,
    required this.onNoteChanged,
    required this.onLongPress,
    required this.source,
    this.onTap,
    this.isSelected = false,
    this.selectionMode = false,
  });

  @override
  State<NoteCardWidget> createState() => _NoteCardWidgetState();
}

class _NoteCardWidgetState extends State<NoteCardWidget> {
  NoteMode _getNoteMode(Note note) {
    // CRITICAL: Check isChecklist flag first
    if (note.isChecklist) {
      return NoteMode.checklist;
    }
    
    // Map noteType to NoteMode
    final codeTypes = [
      'python', 'javascript', 'java', 'dart', 'html', 'css', 'sql',
      'cpp', 'c', 'csharp', 'swift', 'kotlin', 'go', 'rust', 'php',
      'ruby', 'bash', 'json', 'xml', 'code', 'pro', 'professional'
    ];

    if (codeTypes.contains(note.noteType)) {
      return NoteMode.code;
    } else {
      return NoteMode.values.firstWhere(
        (m) => m.name == note.noteType,
        orElse: () => NoteMode.simple,
      );
    }
  }

  Color _getDarkerColor(Color color) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness - 0.15).clamp(0.0, 1.0)).toColor();
  }

  String fixNoteContent(String content) {
    if (ChecklistFormatter.isValidChecklist(content)) {
      return ChecklistFormatter.toDisplayText(content);
    }
    return content;
  }

  String _getDisplayTitle(Note note) {
    // For checklist notes, extract title from JSON content
    if (note.isChecklist && ChecklistFormatter.isValidChecklist(note.content)) {
      try {
        final decoded = jsonDecode(note.content);
        if (decoded is Map && decoded['title'] != null) {
          final title = decoded['title'].toString().trim();
          if (title.isNotEmpty) return title;
        }
      } catch (e) {
        // Invalid JSON, fall through to default
      }
      return 'Checklist';
    }
    // For regular notes, use the title field
    return note.title.isEmpty ? 'Untitled' : note.title;
  }

  bool _shouldShowExtension(String noteType) {
    final codeTypes = [
      'pro',
      'code',
      'markdown',
      'python',
      'javascript',
      'java',
      'dart',
      'html',
      'css',
      'sql',
      'cpp',
      'c',
      'csharp',
      'swift',
      'kotlin',
      'go',
      'rust',
      'php',
      'ruby',
      'bash',
      'json',
      'xml',
      'professional'
    ];
    return codeTypes.contains(noteType);
  }

  String _getFileExtension(String content, String noteType) {
    // Map noteType to extension directly
    final typeToExt = {
      'markdown': '.md',
      'python': '.py',
      'javascript': '.js',
      'java': '.java',
      'dart': '.dart',
      'html': '.html',
      'css': '.css',
      'sql': '.sql',
      'cpp': '.cpp',
      'c': '.c',
      'csharp': '.cs',
      'swift': '.swift',
      'kotlin': '.kt',
      'go': '.go',
      'rust': '.rs',
      'php': '.php',
      'ruby': '.rb',
      'bash': '.sh',
      'json': '.json',
      'xml': '.xml',
    };

    // Use stored noteType if available
    if (typeToExt.containsKey(noteType)) {
      return typeToExt[noteType]!;
    }

    // Fallback: detect from content for old notes
    final detectedLang = LanguageDetector.detectLanguage(content);
    if (detectedLang != null) {
      return LanguageDetector.getFileExtension(detectedLang);
    }

    return '.txt';
  }

  Widget _buildChecklistPreview(String content, Color titleColor) {
    final items = ChecklistFormatter.parseJson(content).take(3).toList();
    if (items.isEmpty) {
      return Text(
        content,
        maxLines: 4,
        overflow: TextOverflow.ellipsis,
        style:
            TextStyle(fontSize: 14, color: titleColor.withValues(alpha: 0.7)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              Icon(
                item.isDone ? Icons.check_box : Icons.check_box_outline_blank,
                size: 18,
                color: item.isDone
                    ? Colors.green
                    : titleColor.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.text.isEmpty ? 'Mission...' : item.text,
                  style: TextStyle(
                    fontSize: 14,
                    color: item.isDone
                        ? titleColor.withValues(alpha: 0.5)
                        : titleColor.withValues(alpha: 0.8),
                    decoration: item.isDone ? TextDecoration.lineThrough : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = Provider.of<SettingsProvider>(context, listen: false);

    final brightness = Theme.of(context).brightness;
    final baseColor = AppColorPalette.palette[widget.note.colorIndex].getColor(brightness);
    final bool isLightColor = baseColor.computeLuminance() > 0.5;
    final Color titleColor = isLightColor ? Colors.black87 : Colors.white;
    final Color contentColor =
        isLightColor ? Colors.grey[700]! : Colors.grey[300]!;

    // SECURITY: Locked notes use PopupMenu instead of swipe
    // Disable swipe in archive screen (like trash screen)
    final bool enableSwipe = !widget.selectionMode && settings.swipeEnabled && !widget.note.isLocked && widget.source != 'archive';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Slidable(
        key: Key(widget.note.id.toString()),
        groupTag: '0',
        closeOnScroll: true,
        enabled: enableSwipe,
        startActionPane: enableSwipe
            ? ActionPane(
                motion: const DrawerMotion(),
                extentRatio: 0.25,
                dragDismissible: false,
                children: [
                  _buildCustomSlidableAction(
                    action: settings.swipeRightAction,
                    context: context,
                    borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(16)),
                  ),
                ],
              )
            : null,
        endActionPane: enableSwipe
            ? ActionPane(
                motion: const DrawerMotion(),
                extentRatio: 0.25,
                dragDismissible: false,
                children: [
                  _buildCustomSlidableAction(
                    action: settings.swipeLeftAction,
                    context: context,
                    borderRadius: const BorderRadius.horizontal(
                        right: Radius.circular(16)),
                  ),
                ],
              )
            : null,
        child: SlidableAutoCloser(
          closerNotifier: widget.closeAllSlidables,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () async {
              if (widget.selectionMode && widget.onTap != null) {
                widget.onTap!();
              } else if (!widget.selectionMode) {
                // SECURITY: Locked notes open editor directly (faster + more secure)
                if (widget.note.isLocked && widget.source == 'locked') {
                  final mode = _getNoteMode(widget.note);
                  // CRITICAL: Pass decrypted note with isLocked=false to prevent double encryption
                  final decryptedNote = Note(
                    id: widget.note.id,
                    title: widget.note.title,
                    content: widget.note.content,
                    createdAt: widget.note.createdAt,
                    updatedAt: widget.note.updatedAt,
                    colorIndex: widget.note.colorIndex,
                    isArchived: widget.note.isArchived,
                    isTrashed: widget.note.isTrashed,
                    reminderDateTime: widget.note.reminderDateTime,
                    isLocked: false, // Temporarily false to prevent double encryption
                    noteType: widget.note.noteType,
                    recurrenceRule: widget.note.recurrenceRule,
                    isCompleted: widget.note.isCompleted,
                    isProfessional: widget.note.isProfessional,
                    isPinned: widget.note.isPinned,
                    isChecklist: widget.note.isChecklist,
                  );
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NoteEditorImmersive(
                        note: decryptedNote,
                        mode: mode,
                        skipAuthentication: true,
                        originallyLocked: true,
                      ),
                    ),
                  );
                  if (result == true || result == null) {
                    widget.onNoteChanged();
                  }
                } else if (widget.source == 'archive') {
                  // Archive notes open editor directly for editing
                  final mode = _getNoteMode(widget.note);
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NoteEditorImmersive(
                        note: widget.note,
                        mode: mode,
                      ),
                    ),
                  );
                  if (result == true || result == null) {
                    widget.onNoteChanged();
                  }
                } else {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          NoteViewScreen(note: widget.note, showRestore: false),
                    ),
                  );
                  if (result == true || result == null) {
                    widget.onNoteChanged();
                  }
                }
              }
            },
            onLongPress: () {
              HapticFeedback.mediumImpact();
              widget.onLongPress();
            },
            child: Hero(
              tag: '${widget.source}_note_${widget.note.id}',
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: widget.isSelected
                        ? Theme.of(context).colorScheme.secondary
                        : _getDarkerColor(baseColor),
                    width: widget.isSelected ? 3.0 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: PremiumCardEffect(
                  baseColor: baseColor,
                  enableMotion: settings.cardMotionEnabled,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (widget.selectionMode)
                              Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: Icon(
                                  widget.isSelected
                                      ? Icons.check_circle
                                      : Icons.circle_outlined,
                                  color: widget.isSelected
                                      ? Theme.of(context).primaryColor
                                      : titleColor.withValues(alpha: 0.5),
                                  size: 24,
                                ),
                              ),
                            Expanded(
                              child: widget.viewType == ViewType.listCompact
                                  ? Text(
                                      _getDisplayTitle(widget.note),
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: titleColor),
                                      overflow: TextOverflow.ellipsis,
                                    )
                                  : Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          _getDisplayTitle(widget.note),
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: titleColor),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 8),
                                        // SECURITY: Never render body content for locked notes
                                        widget.note.isLocked
                                            ? Text(
                                                l10n.protectedContent,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: contentColor
                                                      .withValues(alpha: 0.6),
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              )
                                            : ChecklistFormatter
                                                    .isValidChecklist(
                                                        widget.note.content)
                                                ? _buildChecklistPreview(
                                                    widget.note.content,
                                                    titleColor)
                                                : Text(
                                                    fixNoteContent(
                                                        widget.note.content),
                                                    maxLines: 4,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: contentColor,
                                                    ),
                                                  ),
                                      ],
                                    ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (widget.note.isPinned)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 4),
                                    child: Icon(Icons.push_pin,
                                        size: 18,
                                        color:
                                            titleColor.withValues(alpha: 0.7)),
                                  ),
                                if (widget.note.isLocked)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 4),
                                    child: Icon(Icons.lock,
                                        size: 20, color: titleColor),
                                  ),
                                if (widget.note.isLocked && !widget.selectionMode)
                                  _buildLockedNoteMenu(context, titleColor),
                              ],
                            ),
                          ],
                        ),
                        if (widget.note.reminderDateTime != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.alarm,
                                      size: 14, color: Colors.orange),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      '${DateFormat('EEE, MMM d').format(widget.note.reminderDateTime!)} • ${DateFormat('h:mm a').format(widget.note.reminderDateTime!)}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: titleColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                  if (widget.note.recurrenceRule != null) ...[
                                    const SizedBox(width: 4),
                                    const Icon(Icons.repeat,
                                        size: 12, color: Colors.orange),
                                  ]
                                ],
                              ),
                            ),
                          ),
                        if (_shouldShowExtension(widget.note.noteType))
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: widget.note.noteType == 'markdown'
                                        ? Colors.orange.withValues(alpha: 0.15)
                                        : Colors.blue.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.code,
                                        size: 12,
                                        color:
                                            widget.note.noteType == 'markdown'
                                                ? Colors.orange.shade700
                                                : Colors.blue.shade700,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _getFileExtension(widget.note.content,
                                            widget.note.noteType),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color:
                                              widget.note.noteType == 'markdown'
                                                  ? Colors.orange.shade700
                                                  : Colors.blue.shade700,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLockedNoteMenu(BuildContext context, Color titleColor) {
    final l10n = AppLocalizations.of(context)!;
    final notesProvider = Provider.of<NotesProvider>(context, listen: false);

    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, size: 20, color: titleColor),
      onSelected: (value) async {
        if (value == 'unlock') {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(l10n.unlockNote),
              content: Text(l10n.unlockNoteConfirmation),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(l10n.cancel),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(l10n.unlock),
                ),
              ],
            ),
          );

          if (confirmed == true) {
            await notesProvider.toggleLockStatus(widget.note.id!, false);
            widget.onNoteChanged();
            ToastService().showToast(
              context: context,
              message: l10n.noteUnlocked,
              type: ToastType.success,
            );
          }
        } else if (value == 'delete') {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(l10n.permanentDelete),
              content: Text(l10n.confirmPermanentDelete),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(l10n.cancel),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(l10n.delete),
                ),
              ],
            ),
          );

          if (confirmed == true) {
            HapticFeedback.mediumImpact();
            final noteId = widget.note.id!;
            await notesProvider.trashNote(noteId);
            widget.onNoteChanged();
            ToastService().showToast(
              context: context,
              message: l10n.noteDeleted,
              type: ToastType.info,
            );
          }
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'unlock',
          child: Row(
            children: [
              const Icon(Icons.lock_open, size: 18),
              const SizedBox(width: 8),
              Text(l10n.unlock),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              const Icon(Icons.delete, size: 18, color: Colors.red),
              const SizedBox(width: 8),
              Text(l10n.delete, style: const TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCustomSlidableAction({
    required String action,
    required BuildContext context,
    required BorderRadius borderRadius,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final notesProvider = Provider.of<NotesProvider>(context, listen: false);

    IconData icon;
    Color color;
    VoidCallback onTap;

    switch (action) {
      case 'delete':
        icon = Icons.delete_outline;
        color = Colors.red.shade600;
        onTap = () async {
          HapticFeedback.mediumImpact();
          Slidable.of(context)?.close();
          final noteId = widget.note.id!;
          final noteTitle = widget.note.title;
          
          await notesProvider.trashNote(noteId);
          
          if (!context.mounted) return;
          
          ToastService().showUndoToast(
            context: context,
            message: '${l10n.movedTo} "$noteTitle" ${l10n.toTrash}',
            actionKey: 'swipe_delete_$noteId',
            type: ToastType.info,
            onExecute: () {},
            onUndo: () async {
              await notesProvider.restoreNote(noteId);
            },
            undoLabel: l10n.undo,
          );
        };
        break;
      case 'archive':
        icon = Icons.archive_outlined;
        color = Colors.green.shade600;
        onTap = () async {
          HapticFeedback.mediumImpact();
          Slidable.of(context)?.close();
          final noteId = widget.note.id!;
          final noteTitle = widget.note.title;
          
          await notesProvider.archiveNote(noteId);
          
          if (!context.mounted) return;
          
          ToastService().showUndoToast(
            context: context,
            message: '${l10n.movedTo} "$noteTitle" ${l10n.toArchive}',
            actionKey: 'swipe_archive_$noteId',
            type: ToastType.success,
            onExecute: () {},
            onUndo: () async {
              await notesProvider.unarchiveNote(noteId);
            },
            undoLabel: l10n.undo,
          );
        };
        break;
      case 'share':
        icon = Icons.share_outlined;
        color = Colors.blue.shade600;
        onTap = () {
          HapticFeedback.mediumImpact();
          Slidable.of(context)?.close();
          CustomShareSheet.show(context, '${widget.note.title}\n\n${widget.note.content}',
              subject: widget.note.title);
        };
        break;
      default:
        return const SizedBox.shrink();
    }

    return CustomSlidableAction(
      onPressed: (_) => onTap(),
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      borderRadius: borderRadius,
      child: Align(
        alignment: borderRadius ==
                const BorderRadius.horizontal(right: Radius.circular(16))
            ? Alignment.centerRight
            : Alignment.centerLeft,
        child: Padding(
          padding: borderRadius ==
                  const BorderRadius.horizontal(right: Radius.circular(16))
              ? const EdgeInsets.only(right: 8)
              : const EdgeInsets.only(left: 8),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 26, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class SlidableAutoCloser extends StatefulWidget {
  final ValueNotifier<int> closerNotifier;
  final Widget child;

  const SlidableAutoCloser({
    super.key,
    required this.closerNotifier,
    required this.child,
  });

  @override
  State<SlidableAutoCloser> createState() => _SlidableAutoCloserState();
}

class _SlidableAutoCloserState extends State<SlidableAutoCloser> {
  @override
  void initState() {
    super.initState();
    widget.closerNotifier.addListener(_onGlobalTouch);
  }

  @override
  void dispose() {
    widget.closerNotifier.removeListener(_onGlobalTouch);
    super.dispose();
  }

  void _onGlobalTouch() {
    final slidableController = Slidable.of(context);
    if (slidableController != null) {
      slidableController.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
