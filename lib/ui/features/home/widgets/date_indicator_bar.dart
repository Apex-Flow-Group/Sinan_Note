// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sinan_note/domain/categories.dart';
import 'package:sinan_note/domain/models/note.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';
import 'package:sinan_note/ui/core/theme/app_colors.dart';
import 'package:sinan_note/ui/core/theme/app_theme.dart';
import 'package:sinan_note/ui/features/categories/view_models/categories_provider.dart';
import 'package:sinan_note/ui/features/home/widgets/date_indicator/date_bar_category_picker.dart';
import 'package:sinan_note/ui/features/home/widgets/date_indicator/date_picker_sheet.dart';
import 'package:sinan_note/ui/features/home/widgets/date_indicator/sync_progress_bar.dart';

export 'date_indicator/date_bar_category_picker.dart';
export 'date_indicator/date_picker_sheet.dart';
export 'date_indicator/sync_progress_bar.dart';

class DateIndicatorBar extends StatefulWidget {
  final ScrollController scrollController;
  final ValueNotifier<List<Note>> filteredNotesNotifier;
  final Map<int, double> noteHeights;
  final ValueNotifier<String?> activeFilterNotifier;
  final ValueNotifier<bool>? isPullingNotifier;
  final ValueNotifier<double>? pullDistanceNotifier;
  final ValueNotifier<bool>? isRefreshingNotifier;

  const DateIndicatorBar({
    super.key,
    required this.scrollController,
    required this.filteredNotesNotifier,
    required this.noteHeights,
    required this.activeFilterNotifier,
    this.isPullingNotifier,
    this.pullDistanceNotifier,
    this.isRefreshingNotifier,
  });

  @override
  State<DateIndicatorBar> createState() => _DateIndicatorBarState();
}

class _DateIndicatorBarState extends State<DateIndicatorBar> {
  DateTime? _visibleDate;

  /// موضع آخر حساب أثناء التمرير: التمرير يُعاد حسابه كل 60 بكسل فقط.
  double? _computedAt;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
    widget.filteredNotesNotifier.addListener(_onNotesChanged);
    widget.activeFilterNotifier.addListener(_rebuild);
    _visibleDate = _dateAt(_scrollOffset);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    widget.filteredNotesNotifier.removeListener(_onNotesChanged);
    widget.activeFilterNotifier.removeListener(_rebuild);
    super.dispose();
  }

  double get _scrollOffset =>
      widget.scrollController.hasClients ? widget.scrollController.offset : 0;

  void _rebuild() {
    if (mounted) setState(() {});
  }

  /// الملاحظات تغيّرت (وصل التحميل، فلتر، ملاحظة جديدة): يُحسب دائماً.
  void _onNotesChanged() => _update(_scrollOffset);

  void _onScroll() {
    final offset = _scrollOffset;
    final last = _computedAt;
    if (last != null && (offset - last).abs() < 60) return;
    _update(offset);
  }

  void _update(double offset) {
    _computedAt = offset;
    final date = _dateAt(offset);
    if (date != _visibleDate && mounted) setState(() => _visibleDate = date);
  }

  /// يوم الملاحظة الظاهرة أعلى القائمة عند [offset]، أو null بلا ملاحظات.
  DateTime? _dateAt(double offset) {
    final notes = widget.filteredNotesNotifier.value;
    if (notes.isEmpty) return null;
    const fallback = 80.0;
    var accumulated = 0.0;
    var top = notes.first;
    for (final note in notes) {
      final h = widget.noteHeights[note.id] ?? fallback;
      if (accumulated + h > offset) {
        top = note;
        break;
      }
      accumulated += h;
    }
    final at = top.updatedAt;
    return DateTime(at.year, at.month, at.day);
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final l10n = AppLocalizations.of(context)!;
    if (date == today) return l10n.today;
    if (date == yesterday) return l10n.yesterday;
    if (now.difference(date).inDays < 7) {
      return DateFormat.EEEE(l10n.localeName).format(date);
    }
    return DateFormat.yMMMd(l10n.localeName).format(date);
  }

  String _filterLabel(String filter, AppLocalizations l10n) {
    switch (filter) {
      case 'type:simple':
        return l10n.noteTypeSimple;
      case 'type:rich':
        return l10n.noteTypeRich;
      case 'type:checklist':
        return l10n.checklistNote;
      case 'pinned:true':
        return l10n.pinned;
      case 'category:none':
        return l10n.noCategory;
      default:
        return filter;
    }
  }

  Future<void> _showDatePicker() async {
    final notes = widget.filteredNotesNotifier.value;
    if (notes.isEmpty || !mounted) return;
    final selected = await DatePickerSheet.show(context,
        notes: notes, currentDate: _visibleDate);
    if (selected == null || !mounted) return;
    _scrollToDate(selected, notes);
  }

  void _scrollToDate(DateTime date, List<Note> notes) {
    if (!widget.scrollController.hasClients) return;
    double target = 0;
    for (final note in notes) {
      final noteDate = DateTime(
          note.updatedAt.year, note.updatedAt.month, note.updatedAt.day);
      if (noteDate == date) break;
      target += widget.noteHeights[note.id] ?? 80.0;
    }
    widget.scrollController.animateTo(
      target.clamp(0.0, widget.scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final notes = widget.filteredNotesNotifier.value;
    final colorScheme = Theme.of(context).colorScheme;
    final secondaryBg = AppTheme.secondaryBackground(colorScheme);
    final categoriesProvider = context.watch<CategoriesProvider>();
    final selectedId = categoriesProvider.selectedCategoryId;
    final activeFilter = widget.activeFilterNotifier.value;
    final l10n = AppLocalizations.of(context)!;
    final labelStyle = context.text.labelMedium;

    Widget barChild;

    if (activeFilter != null) {
      barChild = Container(
        height: 28,
        color: secondaryBg,
        padding: const EdgeInsets.only(left: 16),
        child: Row(children: [
          Icon(Icons.filter_list_rounded, size: 13, color: colorScheme.primary),
          const SizedBox(width: 6),
          Text(_filterLabel(activeFilter, l10n),
              style: labelStyle?.copyWith(
                  color: colorScheme.primary, fontWeight: FontWeight.w600)),
          const Spacer(),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              widget.activeFilterNotifier.value = null;
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Icon(Icons.close_rounded,
                  size: 16,
                  color: colorScheme.onSurface.withValues(alpha: 0.5)),
            ),
          ),
        ]),
      );
    } else if (selectedId != null) {
      final isProCategory = selectedId == CategoryPolicy.proCategoryId;
      final cat = isProCategory
          ? null
          : categoriesProvider.categories
              .where((c) => c.id == selectedId)
              .firstOrNull;
      final catName = isProCategory ? l10n.professional : (cat?.name ?? '');

      barChild = Container(
        height: 28,
        color: secondaryBg,
        padding: const EdgeInsets.only(left: 16),
        child: Row(children: [
          Icon(Icons.label_rounded, size: 13, color: colorScheme.primary),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () =>
                DateBarCategoryPickerSheet.show(context, categoriesProvider),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(catName,
                  style: labelStyle?.copyWith(
                      color: colorScheme.primary, fontWeight: FontWeight.w600)),
              const SizedBox(width: 2),
              Icon(Icons.expand_more_rounded,
                  size: 14, color: colorScheme.primary),
            ]),
          ),
          const Spacer(),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => categoriesProvider.selectCategory(null),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Icon(Icons.close_rounded,
                  size: 16,
                  color: colorScheme.onSurface.withValues(alpha: 0.5)),
            ),
          ),
        ]),
      );
    } else if (notes.isEmpty || _visibleDate == null) {
      return SyncProgressBar(
        showLabelOnly: true,
        pullDistanceNotifier: widget.pullDistanceNotifier,
        isRefreshingNotifier: widget.isRefreshingNotifier,
        child: const SizedBox.shrink(),
      );
    } else {
      barChild = GestureDetector(
        onTap: _showDatePicker,
        child: Container(
          height: 28,
          color: secondaryBg,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            Icon(Icons.calendar_today_outlined,
                size: 13, color: colorScheme.onSurface.withValues(alpha: 0.5)),
            const SizedBox(width: 6),
            Text(_formatDate(_visibleDate!),
                style: labelStyle?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500)),
            const Spacer(),
            Icon(Icons.expand_more_rounded,
                size: 16, color: colorScheme.onSurface.withValues(alpha: 0.4)),
          ]),
        ),
      );
    }

    return SyncProgressBar(
      pullDistanceNotifier: widget.pullDistanceNotifier,
      isRefreshingNotifier: widget.isRefreshingNotifier,
      child: barChild,
    );
  }
}

/// SliverPersistentHeaderDelegate للشريط
class DateIndicatorDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  const DateIndicatorDelegate({required this.child});

  @override
  Widget build(
          BuildContext context, double shrinkOffset, bool overlapsContent) =>
      child;

  @override
  double get maxExtent => 28;

  @override
  double get minExtent => 28;

  @override
  bool shouldRebuild(covariant DateIndicatorDelegate old) => old.child != child;
}
