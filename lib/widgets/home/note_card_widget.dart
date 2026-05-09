// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:ui' as ui;

import 'package:apex_note/controllers/categories/categories_provider.dart';
import 'package:apex_note/controllers/notes/notes_provider.dart';
import 'package:apex_note/controllers/settings/settings_provider.dart';
import 'package:apex_note/core/utils/adaptive_color.dart';
import 'package:apex_note/core/utils/checklist_formatter.dart';
import 'package:apex_note/core/utils/editor_page_route.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:apex_note/models/note.dart';
import 'package:apex_note/providers/selected_note_provider.dart';
import 'package:apex_note/screens/mobile/home_screen.dart' show ViewType;
import 'package:apex_note/screens/shared/note_editor.dart';
import 'package:apex_note/services/notification_service.dart';
import 'package:apex_note/services/unified_notification_service.dart';
import 'package:apex_note/widgets/desktop/note_context_menu.dart';
import 'package:apex_note/widgets/effects/premium_card_effect.dart';
import 'package:apex_note/widgets/home/note_card/hidden_categories_chip.dart';
import 'package:apex_note/widgets/home/note_card/slidable_auto_closer.dart';
import 'package:apex_note/widgets/home/note_card_actions.dart';
import 'package:apex_note/widgets/home/note_card_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class NoteCardWidget extends StatefulWidget {
  final Note note;
  final ViewType viewType;
  final ValueNotifier<int> closeAllSlidables;
  final VoidCallback onNoteChanged;
  final VoidCallback onLongPress;
  final VoidCallback? onTap;
  final bool isSelected;
  final bool selectionMode;
  final bool isCurrentlyOpen;
  final bool isFiltering;
  final String source;

  const NoteCardWidget({
    super.key,
    required this.note,
    required this.viewType,
    required this.closeAllSlidables,
    required this.onNoteChanged,
    required this.onLongPress,
    required this.source,
    required this.isFiltering,
    this.onTap,
    this.isSelected = false,
    this.selectionMode = false,
    this.isCurrentlyOpen = false,
  });

  @override
  State<NoteCardWidget> createState() => _NoteCardWidgetState();
}

class _NoteCardWidgetState extends State<NoteCardWidget> {
  late String _displayTitle;
  late String _displayContent;
  late bool _isChecklist;
  late bool _shouldShowExt;
  late String _fileExtension;
  late Color _baseColor;
  late Color _titleColor;
  late Color _contentColor;
  late ui.TextDirection _titleDirection;
  late ui.TextDirection _contentDirection;

  static final _rtlRegex = RegExp(
    r'[\u0600-\u06FF\u0590-\u05FF\u07C0-\u07FF\uFB1D-\uFDFF\uFE70-\uFEFF]',
  );

  static ui.TextDirection _detectDirection(String text) {
    if (text.isEmpty) return ui.TextDirection.rtl;
    for (final char in text.runes) {
      final c = String.fromCharCode(char);
      if (_rtlRegex.hasMatch(c)) return ui.TextDirection.rtl;
      if (RegExp(r'[a-zA-Z]').hasMatch(c)) return ui.TextDirection.ltr;
    }
    return ui.TextDirection.rtl;
  }

  @override
  void initState() {
    super.initState();
    _cacheNoteData();
  }

  @override
  void didUpdateWidget(NoteCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.note.updatedAt != widget.note.updatedAt ||
        oldWidget.note.id != widget.note.id) {
      setState(() {
        _cacheNoteData();
        _cacheColors();
      });
    } else if (oldWidget.note.colorIndex != widget.note.colorIndex) {
      setState(() => _cacheColors());
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _cacheColors();
  }

  void _cacheColors() {
    final brightness = Theme.of(context).brightness;
    _baseColor =
        AppColorPalette.palette[widget.note.colorIndex].getColor(brightness);
    final isLight = _baseColor.computeLuminance() > 0.5;
    _titleColor = isLight ? Colors.black87 : Colors.white;
    _contentColor = isLight ? Colors.grey[700]! : Colors.grey[300]!;
  }

  void _cacheNoteData() {
    _displayTitle = NoteCardUtils.getDisplayTitle(widget.note);
    _displayContent = NoteCardUtils.fixNoteContent(widget.note.content);
    _isChecklist = ChecklistFormatter.isValidChecklist(widget.note.content);
    _shouldShowExt = NoteCardUtils.shouldShowExtension(widget.note.noteType);
    _fileExtension = _shouldShowExt
        ? NoteCardUtils.getFileExtension(
            widget.note.content, widget.note.noteType)
        : '';
    _titleDirection = _detectDirection(_displayTitle);
    _contentDirection = _detectDirection(_displayContent);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = Provider.of<SettingsProvider>(context, listen: false);

    final noteColor = _baseColor;
    final Color titleColor = _titleColor;
    final Color contentColor = _contentColor;
    final bool enableSwipe = !widget.selectionMode &&
        settings.swipeEnabled &&
        !widget.note.isLocked &&
        widget.source != 'archive';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Slidable(
        key: Key(widget.note.id.toString()),
        groupTag: 'notes_group',
        closeOnScroll: false,
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
                    borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(16)),
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
                    borderRadius: const BorderRadius.horizontal(
                        right: Radius.circular(16)),
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
              widget.closeAllSlidables.value++;
            },
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onSecondaryTapDown: (details) {
                final isDesktop = MediaQuery.of(context).size.width >= 600;
                if (isDesktop && !widget.selectionMode) {
                  NoteContextMenu.show(
                      context, widget.note, widget.onNoteChanged);
                }
              },
              onTap: () async {
                if (widget.selectionMode && widget.onTap != null) {
                  widget.onTap!();
                } else if (!widget.selectionMode) {
                  final isDesktop = MediaQuery.of(context).size.width >= 600;
                  if (isDesktop) {
                    final selectedNoteProvider =
                        Provider.of<SelectedNoteProvider>(context,
                            listen: false);
                    selectedNoteProvider.selectNote(widget.note);
                  } else {
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
                        categoryIds: widget.note.categoryIds,
                        isHiddenFromHome: widget.note.isHiddenFromHome,
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
                      if ((result == true || result == null) && mounted) {
                        widget.onNoteChanged();
                      }
                    } else if (widget.source == 'archive') {
                      final mode = NoteCardUtils.getNoteMode(widget.note);
                      final result = await Navigator.push(
                        context,
                        EditorPageRoute(
                          builder: (context) => NoteEditorImmersive(
                            note: widget.note,
                            mode: mode,
                            readOnly: true,
                            heroTag:
                                'note_card_${widget.source}_${widget.note.id}',
                          ),
                        ),
                      );
                      if ((result == true || result == null) && mounted) {
                        widget.onNoteChanged();
                      }
                    } else {
                      final mode = NoteCardUtils.getNoteMode(widget.note);
                      final result = await Navigator.push(
                        context,
                        EditorPageRoute(
                          builder: (context) => NoteEditorImmersive(
                            note: widget.note,
                            mode: mode,
                            readOnly: true,
                            heroTag:
                                'note_card_${widget.source}_${widget.note.id}',
                          ),
                        ),
                      );
                      if ((result == true || result == null) && mounted) {
                        widget.onNoteChanged();
                      }
                    }
                  }
                }
              },
              onLongPress: () {
                HapticFeedback.mediumImpact();
                widget.onLongPress();
              },
              child: PremiumCardEffect(
                baseColor: noteColor,
                enableMotion: false,
                isSelected: widget.isSelected,
                heroTag: 'note_card_${widget.source}_${widget.note.id}',
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    ClipRect(
                      clipBehavior: Clip.hardEdge,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: widget.viewType == ViewType.listCompact
                                      ? Text(
                                          _displayTitle,
                                          textDirection: _titleDirection,
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: titleColor),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        )
                                      : Directionality(
                                          textDirection: _titleDirection,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                _displayTitle,
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
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: contentColor
                                                            .withValues(
                                                                alpha: 0.6),
                                                        fontStyle:
                                                            FontStyle.italic,
                                                      ),
                                                    )
                                                  : _isChecklist
                                                      ? NoteCardUtils
                                                          .buildChecklistPreview(
                                                              widget
                                                                  .note.content,
                                                              titleColor)
                                                      : Text(
                                                          _displayContent,
                                                          textDirection:
                                                              _contentDirection,
                                                          maxLines: 4,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style: TextStyle(
                                                            fontSize: 14,
                                                            color: contentColor,
                                                          ),
                                                        ),
                                            ],
                                          ),
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
                                            color: titleColor.withValues(
                                                alpha: 0.7)),
                                      ),
                                    if (widget.note.isLocked)
                                      Padding(
                                        padding: const EdgeInsets.only(left: 4),
                                        child: Icon(Icons.lock,
                                            size: 20, color: titleColor),
                                      ),
                                    if (widget.note.isLocked &&
                                        !widget.selectionMode)
                                      NoteCardActions.buildLockedNoteMenu(
                                          context,
                                          widget.note,
                                          titleColor,
                                          widget.onNoteChanged),
                                  ],
                                ),
                              ],
                            ),
                            if (widget.note.reminderDateTime != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Builder(builder: (context) {
                                  final isExpired = widget
                                      .note.reminderDateTime!
                                      .isBefore(DateTime.now());
                                  final badgeColor =
                                      isExpired ? Colors.red : Colors.orange;
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: badgeColor.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color:
                                              badgeColor.withValues(alpha: 0.4),
                                          width: 0.8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                            isExpired
                                                ? Icons.alarm_off
                                                : Icons.alarm,
                                            size: 14,
                                            color: badgeColor),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            '${DateFormat('EEE, MMM d').format(widget.note.reminderDateTime!)} • ${DateFormat('h:mm a').format(widget.note.reminderDateTime!)}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: badgeColor,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                        if (widget.note.recurrenceRule !=
                                            null) ...[
                                          const SizedBox(width: 4),
                                          Icon(Icons.repeat,
                                              size: 12, color: badgeColor),
                                        ],
                                        const SizedBox(width: 4),
                                        InkWell(
                                          onTap: () async {
                                            HapticFeedback.lightImpact();
                                            final notesProvider =
                                                Provider.of<NotesProvider>(
                                                    context,
                                                    listen: false);
                                            await NotificationService()
                                                .cancelNotification(
                                                    widget.note.id!);
                                            final updatedNote =
                                                widget.note.copyWith(
                                              reminderDateTime: null,
                                              recurrenceRule: null,
                                            );
                                            await notesProvider
                                                .updateNote(updatedNote);
                                            widget.onNoteChanged();
                                            if (context.mounted) {
                                              UnifiedNotificationService().show(
                                                context: context,
                                                message: l10n.reminderRemoved,
                                                type: NotificationType.info,
                                              );
                                            }
                                          },
                                          child: Icon(Icons.close,
                                              size: 14,
                                              color: badgeColor.withValues(
                                                  alpha: 0.8)),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ),
                            if (_shouldShowExt)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color:
                                            widget.note.noteType == 'markdown'
                                                ? Colors.orange
                                                    .withValues(alpha: 0.15)
                                                : Colors.blue
                                                    .withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.code,
                                            size: 12,
                                            color: widget.note.noteType ==
                                                    'markdown'
                                                ? Colors.orange.shade700
                                                : Colors.blue.shade700,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            _fileExtension,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: widget.note.noteType ==
                                                      'markdown'
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
                            if (widget.viewType != ViewType.listCompact &&
                                (widget.note.isHiddenFromHome ||
                                    (widget.isFiltering &&
                                        widget.note.isProfessional &&
                                        context
                                            .read<CategoriesProvider>()
                                            .hideProFromHome)))
                              HiddenCategoriesChip(
                                note: widget.note,
                                titleColor: titleColor,
                                isProHidden: widget.note.isProfessional &&
                                    context
                                        .read<CategoriesProvider>()
                                        .hideProFromHome &&
                                    !widget.note.isHiddenFromHome,
                              ),
                          ],
                        ),
                      ),
                    ), // ClipRect
                    if (widget.selectionMode)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          decoration: BoxDecoration(
                            color: noteColor,
                            shape: BoxShape.circle,
                          ),
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
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
