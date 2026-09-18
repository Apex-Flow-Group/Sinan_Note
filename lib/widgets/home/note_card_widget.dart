// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:sinan_note/controllers/selected_note_provider.dart';
import 'package:sinan_note/controllers/settings/settings_provider.dart';
import 'package:sinan_note/core/utils/adaptive_color.dart';
import 'package:sinan_note/core/utils/app_navigator.dart';
import 'package:sinan_note/core/utils/checklist_formatter.dart';
import 'package:sinan_note/core/utils/note_content_utils.dart';
import 'package:sinan_note/core/utils/platform_helper.dart';
import 'package:sinan_note/models/note.dart';
import 'package:sinan_note/screens/mobile/home_screen.dart' show ViewType;
import 'package:sinan_note/widgets/desktop/note_context_menu.dart';
import 'package:sinan_note/widgets/effects/premium_card_effect.dart';
import 'package:sinan_note/widgets/home/note_card/note_card_content.dart';
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
  List<ChecklistItem> _checklistItems = const [];
  final _loadingNotifier = ValueNotifier<bool>(false);

  /// أول حرف ذي اتجاه يحدد اتجاه النص. نقارن مدى الأكواد مباشرة بدل بناء
  /// `RegExp` لكل حرف — البطاقة تُبنى مئات المرات أثناء التمرير.
  static ui.TextDirection _detectDirection(String text) {
    for (final code in text.runes) {
      if (_isRtlCode(code)) return ui.TextDirection.rtl;
      if (_isLatinCode(code)) return ui.TextDirection.ltr;
    }
    return ui.TextDirection.rtl;
  }

  static bool _isRtlCode(int code) {
    return (code >= 0x0590 && code <= 0x05FF) || // عبري
        (code >= 0x0600 && code <= 0x06FF) || // عربي
        (code >= 0x07C0 && code <= 0x07FF) || // نكو
        (code >= 0xFB1D && code <= 0xFDFF) || // أشكال تقديمية أ
        (code >= 0xFE70 && code <= 0xFEFF); // أشكال تقديمية ب
  }

  static bool _isLatinCode(int code) {
    return (code >= 0x41 && code <= 0x5A) || (code >= 0x61 && code <= 0x7A);
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
    _displayTitle = NoteContentUtils.limitRunes(
      NoteCardUtils.getDisplayTitle(widget.note),
      NoteContentUtils.cardTitleChars,
    );
    _displayContent = widget.note.previewPlain;
    _isChecklist = widget.note.isChecklist;
    if (!_isChecklist && !widget.note.isLocked) {
      _isChecklist = ChecklistFormatter.isValidChecklist(widget.note.content);
    }
    _checklistItems = _isChecklist && !widget.note.isLocked
        ? ChecklistFormatter.parseJson(widget.note.content)
            .where((item) => item.text.trim().isNotEmpty)
            .take(3)
            .toList()
        : const [];
    _shouldShowExt = NoteCardUtils.shouldShowExtension(widget.note.noteType);
    _fileExtension = _shouldShowExt
        ? NoteCardUtils.getFileExtension(
            widget.note.content, widget.note.noteType)
        : '';
    _titleDirection = _detectDirection(_displayTitle);
    _contentDirection = _detectDirection(_displayContent);
  }

  // ── التخطيط: طبقة السحب، فالإيماءات، فالسطح، فالمحتوى ──

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final isTrash = widget.source == 'trash';
    final isArchive = widget.source == 'archive';
    final enableSwipe = !widget.selectionMode &&
        (isTrash ||
            isArchive ||
            (settings.swipeEnabled && !widget.note.isLocked));

    final startAction = isTrash
        ? 'restore'
        : isArchive
            ? 'unarchive'
            : settings.swipeRightAction;
    final endAction = isTrash
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
        startActionPane:
            enableSwipe ? _buildActionPane(context, startAction, true) : null,
        endActionPane:
            enableSwipe ? _buildActionPane(context, endAction, false) : null,
        child: SlidableAutoCloser(
          closerNotifier: widget.closeAllSlidables,
          child: _buildInteractionLayer(context),
        ),
      ),
    );
  }

  ActionPane _buildActionPane(
    BuildContext context,
    String action,
    bool atStart,
  ) {
    return ActionPane(
      motion: const DrawerMotion(),
      extentRatio: 0.25,
      dragDismissible: false,
      children: [
        NoteCardActions.buildCustomSlidableAction(
          action: action,
          context: context,
          borderRadius: atStart
              ? const BorderRadius.horizontal(left: Radius.circular(16))
              : const BorderRadius.horizontal(right: Radius.circular(16)),
          note: widget.note,
          onNoteChanged: widget.onNoteChanged,
        ),
      ],
    );
  }

  Widget _buildInteractionLayer(BuildContext context) {
    return Listener(
      onPointerDown: (_) => widget.closeAllSlidables.value++,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onSecondaryTapDown: (_) => _showContextMenu(context),
        onTap: _handleTap,
        onLongPress: () {
          HapticFeedback.mediumImpact();
          widget.onLongPress();
        },
        child: _buildSurface(context),
      ),
    );
  }

  Widget _buildSurface(BuildContext context) {
    return PremiumCardEffect(
      baseColor: _baseColor,
      enableMotion: false,
      isSelected: widget.isSelected,
      // القصّ مسؤولية PremiumCardEffect وحده — كان مكرراً ثلاث مرات لكل بطاقة
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: NoteCardContent(
              note: widget.note,
              viewType: widget.viewType,
              source: widget.source,
              title: _displayTitle,
              preview: _displayContent,
              titleDirection: _titleDirection,
              previewDirection: _contentDirection,
              titleColor: _titleColor,
              contentColor: _contentColor,
              isChecklist: _isChecklist,
              checklistItems: _checklistItems,
              fileExtension: _shouldShowExt ? _fileExtension : '',
              selectionMode: widget.selectionMode,
              isFiltering: widget.isFiltering,
              onNoteChanged: widget.onNoteChanged,
            ),
          ),
          if (widget.selectionMode) _buildSelectionMark(context),
          _buildLoadingMark(),
        ],
      ),
    );
  }

  Widget _buildSelectionMark(BuildContext context) {
    return Positioned(
      top: 8,
      left: 8,
      child: Container(
        decoration: BoxDecoration(color: _baseColor, shape: BoxShape.circle),
        child: Icon(
          widget.isSelected ? Icons.check_circle : Icons.circle_outlined,
          color: widget.isSelected
              ? Theme.of(context).primaryColor
              : _titleColor.withValues(alpha: 0.5),
          size: 24,
        ),
      ),
    );
  }

  /// مؤشر انتظار أثناء تهيئة المحرر قبل فتح الملاحظة
  Widget _buildLoadingMark() {
    return ValueListenableBuilder<bool>(
      valueListenable: _loadingNotifier,
      builder: (_, loading, __) {
        if (!loading) return const SizedBox.shrink();
        return Positioned(
          top: 8,
          right: 8,
          child: SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: _titleColor.withValues(alpha: 0.5),
            ),
          ),
        );
      },
    );
  }

  // ── الإيماءات ──

  void _showContextMenu(BuildContext context) {
    if (!PlatformHelper.isWideDisplay(context) || widget.selectionMode) return;
    NoteContextMenu.show(
      context,
      widget.note,
      widget.onNoteChanged,
      source: widget.source,
    );
  }

  Future<void> _handleTap() async {
    if (widget.selectionMode) {
      widget.onTap?.call();
      return;
    }

    if (PlatformHelper.isWideDisplay(context)) {
      Provider.of<SelectedNoteProvider>(context, listen: false)
          .selectNote(widget.note);
      return;
    }

    // الملاحظة المقفلة في شاشتها الخاصة سبق أن تحققت الهوية، فتُفتح مباشرة
    final openedFromVault = widget.note.isLocked && widget.source == 'locked';
    final mode = NoteCardUtils.getNoteMode(widget.note);

    if (!openedFromVault) _loadingNotifier.value = true;
    final result = await AppNavigator.toEditor(
      context,
      note:
          openedFromVault ? widget.note.copyWith(isLocked: false) : widget.note,
      mode: mode,
      readOnly: !openedFromVault,
      skipAuthentication: openedFromVault,
      originallyLocked: openedFromVault,
    );
    if (!openedFromVault) _loadingNotifier.value = false;

    if ((result == true || result == null) && mounted) {
      widget.onNoteChanged();
    }
  }
}
