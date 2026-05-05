// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/controllers/categories/categories_provider.dart';
import 'package:apex_note/models/note.dart';
import 'package:apex_note/widgets/common/app_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HiddenCategoriesChip extends StatefulWidget {
  final Note note;
  final Color titleColor;
  final bool isProHidden;

  const HiddenCategoriesChip({
    super.key,
    required this.note,
    required this.titleColor,
    this.isProHidden = false,
  });

  @override
  State<HiddenCategoriesChip> createState() => _HiddenCategoriesChipState();
}

class _HiddenCategoriesChipState extends State<HiddenCategoriesChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;
  Animation<double>? _routeAnimation;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null && _routeAnimation == null) {
      _routeAnimation = route.animation;
      _routeAnimation!.addStatusListener(_onRouteStatus);
      // إذا الـ route مكتمل بالفعل — اظهر مباشرة
      if (_routeAnimation!.status == AnimationStatus.completed) {
        _ctrl.forward();
      }
    }
  }

  void _onRouteStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      _ctrl.forward();
    } else if (status == AnimationStatus.reverse && mounted) {
      _ctrl.reverse();
    }
  }

  @override
  void dispose() {
    _routeAnimation?.removeStatusListener(_onRouteStatus);
    _ctrl.dispose();
    super.dispose();
  }

  void _showAllCategories(BuildContext context, List<String> names) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    AppBottomSheet.show(
      context,
      child: AppBottomSheet(
        title: isAr ? 'مخفي في الكتالوجات' : 'Hidden in catalogs',
        titleIcon: Icons.visibility_off_rounded,
        scrollable: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...names.map((name) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.label_rounded, size: 18),
                  title: Text(name),
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final catProvider = context.read<CategoriesProvider>();
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    Widget content;

    if (widget.isProHidden) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.visibility_off_rounded,
              size: 12, color: widget.titleColor.withValues(alpha: 0.5)),
          const SizedBox(width: 4),
          Text(
            isAr ? 'مخفي (محترف)' : 'Hidden (Pro)',
            style: TextStyle(
              fontSize: 11,
              color: widget.titleColor.withValues(alpha: 0.5),
            ),
          ),
        ],
      );
    } else {
      final catNames = widget.note.categoryIds
          .map((id) => catProvider.categories
              .where((c) => c.id == id)
              .map((c) => c.name)
              .firstOrNull)
          .whereType<String>()
          .toList();

      final displayNames = catNames.take(2).toList();
      final extra = catNames.length - displayNames.length;

      content = GestureDetector(
        onTap: extra > 0 ? () => _showAllCategories(context, catNames) : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.visibility_off_rounded,
                size: 12, color: widget.titleColor.withValues(alpha: 0.5)),
            const SizedBox(width: 4),
            if (catNames.isEmpty)
              Text(
                isAr ? 'مخفي' : 'Hidden',
                style: TextStyle(
                    fontSize: 11,
                    color: widget.titleColor.withValues(alpha: 0.5)),
              )
            else
              ...displayNames.map((name) => Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: widget.titleColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        name,
                        style: TextStyle(
                          fontSize: 10,
                          color: widget.titleColor.withValues(alpha: 0.55),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )),
            if (extra > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: widget.titleColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '+$extra',
                  style: TextStyle(
                    fontSize: 10,
                    color: widget.titleColor.withValues(alpha: 0.55),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: SizeTransition(
          sizeFactor: _fade,
          axisAlignment: -1,
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: content,
          ),
        ),
      ),
    );
  }
}
