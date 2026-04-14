// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/controllers/categories/categories_provider.dart';
import 'package:apex_note/models/note.dart';
import 'package:apex_note/services/cloud/google_drive_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// شريط التاريخ الذكي — يظهر تاريخ أول نوت مرئي أثناء التمرير
/// ويتيح الضغط لاختيار تاريخ والقفز إليه
class DateIndicatorBar extends StatefulWidget {
  final ScrollController scrollController;
  final ValueNotifier<List<Note>> filteredNotesNotifier;
  final Map<int, double> noteHeights; // من NoteCardKeyRegistry

  const DateIndicatorBar({
    super.key,
    required this.scrollController,
    required this.filteredNotesNotifier,
    required this.noteHeights,
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
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    widget.filteredNotesNotifier.removeListener(_onNotesChanged);
    super.dispose();
  }

  void _onNotesChanged() {
    _lastScrollOffset = -1;
    _onScroll();
  }

  void _onScroll() {
    if (!widget.scrollController.hasClients) return;
    final notes = widget.filteredNotesNotifier.value;
    if (notes.isEmpty) return;

    // Throttle: تجاهل إذا لم يتغير الموضع بما يكفي (60px)
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
    if (newDate != _visibleDate) {
      setState(() => _visibleDate = newDate);
    }
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

  Future<void> _showDatePicker() async {
    final notes = widget.filteredNotesNotifier.value;
    if (notes.isEmpty) return;

    // جمع التواريخ الفريدة المتاحة
    final uniqueDates = notes
        .map((n) =>
            DateTime(n.updatedAt.year, n.updatedAt.month, n.updatedAt.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    if (!mounted) return;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    final selected = await showModalBottomSheet<DateTime>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.calendar_month_outlined, size: 20),
                const SizedBox(width: 8),
                Text(
                  isAr ? 'انتقل إلى تاريخ' : 'Jump to date',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.4,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: uniqueDates.length,
              itemBuilder: (ctx, i) {
                final date = uniqueDates[i];
                final isSelected = date == _visibleDate;
                final count = notes
                    .where((n) =>
                        n.updatedAt.year == date.year &&
                        n.updatedAt.month == date.month &&
                        n.updatedAt.day == date.day)
                    .length;
                return ListTile(
                  leading: Icon(
                    Icons.circle,
                    size: 10,
                    color: isSelected
                        ? Theme.of(ctx).colorScheme.primary
                        : Colors.transparent,
                  ),
                  title: Text(
                    _formatDateStatic(date, isAr),
                    style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color:
                          isSelected ? Theme.of(ctx).colorScheme.primary : null,
                    ),
                  ),
                  trailing: Text(
                    '$count',
                    style: TextStyle(color: Colors.grey[500], fontSize: 13),
                  ),
                  onTap: () => Navigator.pop(ctx, date),
                );
              },
            ),
          ),
          SizedBox(height: MediaQuery.of(ctx).padding.bottom + 8),
        ],
      ),
    );

    if (selected == null || !mounted) return;
    _scrollToDate(selected, notes);
  }

  void _scrollToDate(DateTime date, List<Note> notes) {
    if (!widget.scrollController.hasClients) return;
    const fallback = 80.0;
    double target = 0;

    for (final note in notes) {
      final noteDate = DateTime(
          note.updatedAt.year, note.updatedAt.month, note.updatedAt.day);
      if (noteDate == date) {
        break;
      }
      target += widget.noteHeights[note.id] ?? fallback;
    }

    widget.scrollController.animateTo(
      target.clamp(0.0, widget.scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _showCategoryPicker(CategoriesProvider categoriesProvider) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final categories = categoriesProvider.categories;
    final selectedId = categoriesProvider.selectedCategoryId;
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.label_outline_rounded, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      isAr ? 'اختر كتالوج' : 'Select Catalog',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.45,
                ),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    // خيار الكل
                    ListTile(
                      leading: Icon(
                        Icons.all_inbox_rounded,
                        color: selectedId == null
                            ? colorScheme.primary
                            : colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      title: Text(
                        isAr ? 'الكل' : 'All',
                        style: TextStyle(
                          fontWeight: selectedId == null
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color:
                              selectedId == null ? colorScheme.primary : null,
                        ),
                      ),
                      trailing: selectedId == null
                          ? Icon(Icons.check_rounded,
                              color: colorScheme.primary, size: 18)
                          : null,
                      onTap: () {
                        Navigator.pop(ctx);
                        categoriesProvider.selectCategory(null);
                      },
                    ),
                    // كتالوج المحترف
                    ListTile(
                      leading: Icon(
                        Icons.code_rounded,
                        color: selectedId == kProCategoryId
                            ? colorScheme.primary
                            : colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      title: Text(
                        isAr ? 'المحترف' : 'Professional',
                        style: TextStyle(
                          fontWeight: selectedId == kProCategoryId
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: selectedId == kProCategoryId
                              ? colorScheme.primary
                              : null,
                        ),
                      ),
                      trailing: selectedId == kProCategoryId
                          ? Icon(Icons.check_rounded,
                              color: colorScheme.primary, size: 18)
                          : null,
                      onTap: () {
                        Navigator.pop(ctx);
                        categoriesProvider.selectCategory(kProCategoryId);
                      },
                    ),
                    if (categories.isNotEmpty) const Divider(height: 1),
                    // باقي الكتالوجات
                    ...categories.map((cat) => ListTile(
                          leading: Icon(
                            Icons.label_rounded,
                            color: selectedId == cat.id
                                ? colorScheme.primary
                                : colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          title: Text(
                            cat.name,
                            style: TextStyle(
                              fontWeight: selectedId == cat.id
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: selectedId == cat.id
                                  ? colorScheme.primary
                                  : null,
                            ),
                          ),
                          trailing: selectedId == cat.id
                              ? Icon(Icons.check_rounded,
                                  color: colorScheme.primary, size: 18)
                              : null,
                          onTap: () {
                            Navigator.pop(ctx);
                            categoriesProvider.selectCategory(cat.id);
                          },
                        )),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDateStatic(DateTime date, bool isAr) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    if (date == today) return isAr ? 'اليوم' : 'Today';
    if (date == yesterday) return isAr ? 'أمس' : 'Yesterday';
    return DateFormat(isAr ? 'd MMMM yyyy' : 'MMMM d, yyyy', isAr ? 'ar' : 'en')
        .format(date);
  }

  @override
  Widget build(BuildContext context) {
    final notes = widget.filteredNotesNotifier.value;
    final colorScheme = Theme.of(context).colorScheme;
    final categoriesProvider = context.watch<CategoriesProvider>();
    final selectedId = categoriesProvider.selectedCategoryId;

    // ─── وضع التصنيف ───
    if (selectedId != null) {
      final isProCategory = selectedId == kProCategoryId;
      final cat = isProCategory
          ? null
          : categoriesProvider.categories
              .where((c) => c.id == selectedId)
              .firstOrNull;
      final isAr = Localizations.localeOf(context).languageCode == 'ar';
      final catName = isProCategory
          ? (isAr ? 'المحترف' : 'Professional')
          : (cat?.name ?? '');

      return _BarWithSyncProgress(
        child: Container(
          height: 28,
          color:
              Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.97),
          padding: const EdgeInsets.only(left: 16),
          child: Row(
            children: [
              Icon(Icons.label_rounded, size: 13, color: colorScheme.primary),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => _showCategoryPicker(categoriesProvider),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      catName,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(Icons.expand_more_rounded,
                        size: 14, color: colorScheme.primary),
                  ],
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => categoriesProvider.selectCategory(null),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(Icons.close_rounded,
                      size: 16,
                      color: colorScheme.onSurface.withValues(alpha: 0.5)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ─── وضع التاريخ الافتراضي ───
    if (notes.isEmpty || _visibleDate == null) {
      return const _BarWithSyncProgress(
        showLabelOnly: true,
        child: SizedBox.shrink(),
      );
    }

    return _BarWithSyncProgress(
      child: GestureDetector(
        onTap: _showDatePicker,
        child: Container(
          height: 28,
          color:
              Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.97),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(Icons.calendar_today_outlined,
                  size: 13,
                  color: colorScheme.onSurface.withValues(alpha: 0.5)),
              const SizedBox(width: 6),
              Text(
                _formatDate(_visibleDate!),
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Icon(Icons.expand_more_rounded,
                  size: 16,
                  color: colorScheme.onSurface.withValues(alpha: 0.4)),
            ],
          ),
        ),
      ),
    );
  }
}

/// يُغلّف أي شريط ويضيف LinearProgressIndicator + نص المزامنة أسفله
class _BarWithSyncProgress extends StatelessWidget {
  final Widget child;
  final bool showLabelOnly;
  const _BarWithSyncProgress({required this.child, this.showLabelOnly = false});

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final colorScheme = Theme.of(context).colorScheme;

    return ValueListenableBuilder<bool>(
      valueListenable: GoogleDriveService.isSyncing,
      builder: (context, syncing, _) {
        if (!syncing && showLabelOnly) return const SizedBox.shrink();
        return Stack(
          children: [
            if (!showLabelOnly) child,
            if (syncing) ...[
              // خلفية الشريط عند showLabelOnly
              if (showLabelOnly)
                Container(
                  height: 28,
                  color: Theme.of(context)
                      .scaffoldBackgroundColor
                      .withValues(alpha: 0.97),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Icon(Icons.sync_rounded,
                          size: 13,
                          color: colorScheme.primary.withValues(alpha: 0.7)),
                      const SizedBox(width: 6),
                      Text(
                        isAr ? 'جارٍ المزامنة...' : 'Syncing...',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.primary.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: LinearProgressIndicator(
                  minHeight: 2,
                  backgroundColor: Colors.transparent,
                  color: colorScheme.primary.withValues(alpha: 0.7),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// SliverPersistentHeaderDelegate للشريط
class DateIndicatorDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  const DateIndicatorDelegate({required this.child});

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  double get maxExtent => 28;

  @override
  double get minExtent => 28;

  @override
  bool shouldRebuild(covariant DateIndicatorDelegate old) => old.child != child;
}
