// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/note.dart';
import '../../controllers/notes/notes_provider.dart';
import '../../controllers/settings/settings_provider.dart';
import '../../services/notification_service.dart';
import '../../core/utils/adaptive_color.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import '../../screens/note_view_screen.dart';
import '../../screens/note_editor.dart';
import '../../screens/home_screen.dart' show ViewType;
import '../../core/utils/checklist_formatter.dart';
import '../../services/toast_service.dart';
import '../effects/premium_card_effect.dart';
import 'note_card_utils.dart';
import 'note_card_actions.dart';

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
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = Provider.of<SettingsProvider>(context, listen: false);

    final brightness = Theme.of(context).brightness;
    final baseColor = AppColorPalette.palette[widget.note.colorIndex].getColor(brightness);
    
    // حساب لون الحافة بذكاء
    final Color borderColor = brightness == Brightness.light
        ? baseColor.withValues(alpha: 0.4)
        : Color.lerp(baseColor, Colors.black, 0.3)!;
    
    final bool isLightColor = baseColor.computeLuminance() > 0.5;
    final Color titleColor = isLightColor ? Colors.black87 : Colors.white;
    final Color contentColor = isLightColor ? Colors.grey[700]! : Colors.grey[300]!;

    final bool enableSwipe = !widget.selectionMode && settings.swipeEnabled && !widget.note.isLocked && widget.source != 'archive';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Slidable(
        key: Key(widget.note.id.toString()),
        groupTag: 'notes_group',
        closeOnScroll: true,
        enabled: enableSwipe,
        startActionPane: enableSwipe
            ? ActionPane(
                motion: const DrawerMotion(),
                extentRatio: 0.25,
                dragDismissible: false,
                children: [
                  NoteCardActions.buildCustomSlidableAction(
                    action: settings.swipeRightAction,
                    context: context,
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                    note: widget.note,
                    onNoteChanged: widget.onNoteChanged,
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
                  NoteCardActions.buildCustomSlidableAction(
                    action: settings.swipeLeftAction,
                    context: context,
                    borderRadius: const BorderRadius.horizontal(right: Radius.circular(16)),
                    note: widget.note,
                    onNoteChanged: widget.onNoteChanged,
                  ),
                ],
              )
            : null,
        child: SlidableAutoCloser(
          closerNotifier: widget.closeAllSlidables,
          child: Listener(
            onPointerDown: (event) {
              // Increment to trigger close on ALL other cards
              widget.closeAllSlidables.value++;
            },
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () async {
                if (widget.selectionMode && widget.onTap != null) {
                  widget.onTap!();
                } else if (!widget.selectionMode) {
                if (widget.note.isLocked && widget.source == 'locked') {
                  final mode = NoteCardUtils.getNoteMode(widget.note);
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
                    isLocked: false,
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
                  final mode = NoteCardUtils.getNoteMode(widget.note);
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
                      builder: (context) => NoteViewScreen(note: widget.note, showRestore: false),
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
              tag: '${widget.source}_note_${widget.note.id}_${widget.note.createdAt.millisecondsSinceEpoch}',
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: widget.isSelected
                        ? Theme.of(context).colorScheme.secondary
                        : borderColor,
                    width: 0.8,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0F000000),
                      blurRadius: 2.0,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: PremiumCardEffect(
                  baseColor: baseColor,
                  enableMotion: settings.cardMotionEnabled,
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: widget.viewType == ViewType.listCompact
                                      ? Text(
                                          NoteCardUtils.getDisplayTitle(widget.note),
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: titleColor),
                                          overflow: TextOverflow.ellipsis,
                                        )
                                      : Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              NoteCardUtils.getDisplayTitle(widget.note),
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                  color: titleColor),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 8),
                                            widget.note.isLocked
                                                ? Text(
                                                    l10n.protectedContent,
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: contentColor.withValues(alpha: 0.6),
                                                      fontStyle: FontStyle.italic,
                                                    ),
                                                  )
                                                : ChecklistFormatter.isValidChecklist(widget.note.content)
                                                    ? NoteCardUtils.buildChecklistPreview(widget.note.content, titleColor)
                                                    : Text(
                                                        NoteCardUtils.fixNoteContent(widget.note.content),
                                                        maxLines: 4,
                                                        overflow: TextOverflow.ellipsis,
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
                                            color: titleColor.withValues(alpha: 0.7)),
                                      ),
                                    if (widget.note.isLocked)
                                      Padding(
                                        padding: const EdgeInsets.only(left: 4),
                                        child: Icon(Icons.lock, size: 20, color: titleColor),
                                      ),
                                    if (widget.note.isLocked && !widget.selectionMode)
                                      NoteCardActions.buildLockedNoteMenu(context, widget.note, titleColor, widget.onNoteChanged),
                                  ],
                                ),
                              ],
                            ),
                            if (widget.note.reminderDateTime != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.alarm, size: 14, color: Colors.orange),
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
                                        const Icon(Icons.repeat, size: 12, color: Colors.orange),
                                      ],
                                      const SizedBox(width: 4),
                                      InkWell(
                                        onTap: () async {
                                          HapticFeedback.lightImpact();
                                          final notesProvider = Provider.of<NotesProvider>(context, listen: false);
                                          await NotificationService().cancelNotification(widget.note.id!);
                                          final updatedNote = widget.note.copyWith(
                                            reminderDateTime: null,
                                            recurrenceRule: null,
                                          );
                                          await notesProvider.updateNote(updatedNote);
                                          widget.onNoteChanged();
                                          if (context.mounted) {
                                            ToastService().showToast(
                                              context: context,
                                              message: l10n.reminderRemoved,
                                              type: ToastType.info,
                                            );
                                          }
                                        },
                                        child: Icon(Icons.close, size: 14, color: titleColor.withValues(alpha: 0.7)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            if (NoteCardUtils.shouldShowExtension(widget.note.noteType))
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                                            color: widget.note.noteType == 'markdown'
                                                ? Colors.orange.shade700
                                                : Colors.blue.shade700,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            NoteCardUtils.getFileExtension(widget.note.content, widget.note.noteType),
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: widget.note.noteType == 'markdown'
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
                      if (widget.selectionMode)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            decoration: BoxDecoration(
                              color: baseColor,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              widget.isSelected ? Icons.check_circle : Icons.circle_outlined,
                              color: widget.isSelected
                                  ? Theme.of(context).primaryColor
                                  : titleColor.withValues(alpha: 0.5),
                              size: 24,
                            ),
                          ),
                        ),
                    ],
                  ),  // Stack
                ),  // PremiumCardEffect
              ),  // Container
            ),  // Hero
          ),  // GestureDetector
        ),  // Listener
      ),  // SlidableAutoCloser
    ),  // Slidable
  );  // Padding
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
