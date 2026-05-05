// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/controllers/categories/categories_provider.dart';
import 'package:apex_note/core/theme/app_theme.dart';
import 'package:apex_note/models/note.dart';
import 'package:apex_note/widgets/home/date_indicator/date_bar_category_picker.dart';
import 'package:apex_note/widgets/home/date_indicator/date_picker_sheet.dart';
import 'package:apex_note/widgets/home/date_indicator/sync_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

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

  const DateIndicatorBar({
    super.key,
    required this.scrollController,
    required this.filteredNotesNotifier,
    required this.noteHeights,
    required this.activeFilterNotifier,
    this.isPullingNotifier,
    this.pullDistanceNotifier,
  });

  @override
  State<DateIndicatorBar> createState() => _DateIndicatorBarState();
}

class _DateIndicatorBarState extends State<DateIndicatorBar> {
  DateTime? _visibleDate;
  int _lastScrollOffset = -1;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
    widget.filteredNotesNotifier.addListener(_onNotesChanged);
    widget.activeFilterNotifier.addListener(_rebuild);
    _initVisibleDate();
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    widget.filteredNotesNotifier.removeListener(_onNotesChanged);
    widget.activeFilterNotifier.removeListener(_rebuild);
    super.dispose();
  }

  void _initVisibleDate() {
    final notes = widget.filteredNotesNotifier.value;
    if (notes.isNotEmpty && _visibleDate == null) {
      final date = notes.first.updatedAt;
      _visibleDate = DateTime(date.year, date.month, date.day);
    }
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  void _onNotesChanged() {
    _lastScrollOffset = -1;
    _initVisibleDate();
    _onScroll();
  }

  void _onScroll() {
    if (!widget.scrollController.hasClients) return;
    final notes = widget.filteredNotesNotifier.value;
    if (notes.isEmpty) return;

    final offset = widget.scrollController.offset.toInt();
    if ((_lastScrollOffset - offset).abs() < 60) return;
    _lastScrollOffset = offset;

    final scrollOffset = widget.scrollController.offset;
    double accumulated = 0;
    const fallback = 80.0;

    Note? topNote;
    for (final note in notes) {
      final h = widget.noteHeights[note.id] ?? fallback;
      if (accumulated + h > scrollOffset) {
        topNote = note;
        break;
      }
      accumulated += h;
    }

    final date = (topNote ?? notes.first).updatedAt;
    final newDate = DateTime(date.year, date.month, date.day);
    if (newDate != _visibleDate) setState(() => _visibleDate = newDate);
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    if (date == today) return isAr ? 'اليوم' : 'Today';
    if (date == yesterday) return isAr ? 'أمس' : 'Yesterday';
    if (now.difference(date).inDays < 7) {
      return DateFormat(isAr ? 'EEEE' : 'EEEE', isAr ? 'ar' : 'en')
          .format(date);
    }
    return DateFormat(isAr ? 'd MMM yyyy' : 'MMM d, yyyy', isAr ? 'ar' : 'en')
        .format(date);
  }

  String _filterLabel(String filter, bool isAr) {
    switch (filter) {
      case 'type:simple':
        return isAr ? 'نص بسيط' : 'Simple';
      case 'type:checklist':
        return isAr ? 'قائمة مهام' : 'Checklist';
      case 'pinned:true':
        return isAr ? 'مثبتة' : 'Pinned';
      case 'category:none':
        return isAr ? 'بدون تصنيف' : 'No category';
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
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    Widget barChild;

    if (activeFilter != null) {
      barChild = Container(
        height: 28,
        color: secondaryBg,
        padding: const EdgeInsets.only(left: 16),
        child: Row(children: [
          Icon(Icons.filter_list_rounded, size: 13, color: colorScheme.primary),
          const SizedBox(width: 6),
          Text(_filterLabel(activeFilter, isAr),
              style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600)),
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
      final isProCategory = selectedId == kProCategoryId;
      final cat = isProCategory
          ? null
          : categoriesProvider.categories
              .where((c) => c.id == selectedId)
              .firstOrNull;
      final catName = isProCategory
          ? (isAr ? 'المحترف' : 'Professional')
          : (cat?.name ?? '');

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
                  style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600)),
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
                style: TextStyle(
                    fontSize: 12,
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
