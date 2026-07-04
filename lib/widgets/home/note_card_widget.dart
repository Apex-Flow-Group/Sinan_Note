// Copyright � 2025 Apex Flow Group. All rights reserved.

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sinan_note/controllers/categories/categories_provider.dart';
import 'package:sinan_note/controllers/notes/notes_provider.dart';
import 'package:sinan_note/controllers/settings/settings_provider.dart';
import 'package:sinan_note/core/utils/adaptive_color.dart';
import 'package:sinan_note/core/utils/app_navigator.dart';
import 'package:sinan_note/core/utils/checklist_formatter.dart';
import 'package:sinan_note/core/utils/platform_helper.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';
import 'package:sinan_note/models/note.dart';
import 'package:sinan_note/providers/selected_note_provider.dart';
import 'package:sinan_note/screens/mobile/home_screen.dart' show ViewType;
import 'package:sinan_note/services/notification_service.dart';
import 'package:sinan_note/services/unified_notification_service.dart';
import 'package:sinan_note/widgets/desktop/note_context_menu.dart';
import 'package:sinan_note/widgets/effects/premium_card_effect.dart';
import 'package:sinan_note/widgets/home/note_card/hidden_categories_chip.dart';
import 'package:sinan_note/widgets/home/note_card/slidable_auto_closer.dart';
import 'package:sinan_note/widgets/home/note_card_actions.dart';
import 'package:sinan_note/widgets/home/note_card_utils.dart';

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
  final _loadingNotifier = ValueNotifier<bool>(false);
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

  @override
  void dispose() {
    _loadingNotifier.dispose();
    super.dispose();
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
    final bool isTrash = widget.source == 'trash';
    final bool isArchive = widget.source == 'archive';
    final bool enableSwipe = !widget.selectionMode &&
        (isTrash ||
            isArchive ||
            (settings.swipeEnabled && !widget.note.isLocked));

    final String rightAction = isTrash
        ? 'restore'
        : isArchive
            ? 'unarchive'
            : settings.swipeRightAction;
    final String leftAction = isTrash
        ? 'permanent_delete'
        : isArchive
            ? 'trash_from_archive'
            : settings.swipeLeftAction;

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
                    action: rightAction,
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
                    action: leftAction,
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
                final isDesktop = PlatformHelper.isWideDisplay(context);
                if (isDesktop && !widget.selectionMode) {
                  NoteContextMenu.show(
                      context, widget.note, widget.onNoteChanged,
                      source: widget.source);
                }
              },
              onTap: () async {
                if (widget.selectionMode && widget.onTap != null) {
                  widget.onTap!();
                } else if (!widget.selectionMode) {
                  final isDesktop = PlatformHelper.isWideDisplay(context);
                  if (isDesktop) {
                    final selectedNoteProvider =
                        Provider.of<SelectedNoteProvider>(context,
                            listen: false);
                    selectedNoteProvider.selectNote(widget.note);
                  } else {
                    if (widget.note.isLocked && widget.source == 'locked') {
                      final mode = NoteCardUtils.getNoteMode(widget.note);
                      final decryptedNote =
                          widget.note.copyWith(isLocked: false);
                      final result = await AppNavigator.toEditor(
                        context,
                        note: decryptedNote,
                        mode: mode,
                        skipAuthentication: true,
                        originallyLocked: true,
                      );
                      if ((result == true || result == null) && mounted) {
                        widget.onNoteChanged();
                      }
                    } else {
                      final mode = NoteCardUtils.getNoteMode(widget.note);
                      _loadingNotifier.value = true;
                      final result = await AppNavigator.toEditor(
                        context,
                        note: widget.note,
                        mode: mode,
                        readOnly: true,
                      );
                      _loadingNotifier.value = false;
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
                                              // �� ���� ������ (source == 'locked') �������� ����� ������
                                              // ? ���� ������� ������ ����� �� "����� ����"
                                              (widget.note.isLocked &&
                                                      widget.source != 'locked')
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
                                            '${DateFormat('EEE, MMM d').format(widget.note.reminderDateTime!)} � ${DateFormat('h:mm a').format(widget.note.reminderDateTime!)}',
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
                            if (widget.viewType != ViewType.listCompact)
                              Builder(builder: (context) {
                                final hideProFromHome = context
                                    .read<CategoriesProvider>()
                                    .hideProFromHome;
                                final showChip = widget.note.isHiddenFromHome ||
                                    (widget.isFiltering &&
                                        widget.note.isProfessional &&
                                        hideProFromHome);
                                if (!showChip) return const SizedBox.shrink();
                                return HiddenCategoriesChip(
                                  note: widget.note,
                                  titleColor: titleColor,
                                  isProHidden: widget.note.isProfessional &&
                                      hideProFromHome &&
                                      !widget.note.isHiddenFromHome,
                                );
                              }),
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
                    // loading indicator ���� �� ������� ����� pre-build Quill
                    ValueListenableBuilder<bool>(
                      valueListenable: _loadingNotifier,
                      builder: (_, loading, __) => loading
                          ? Positioned(
                              top: 8,
                              right: 8,
                              child: SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  color: titleColor.withValues(alpha: 0.5),
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
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
