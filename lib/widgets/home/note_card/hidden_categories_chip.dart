// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sinan_note/controllers/categories/categories_provider.dart';
import 'package:sinan_note/domain/models/note.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';
import 'package:sinan_note/ui/core/theme/app_colors.dart';
import 'package:sinan_note/widgets/common/app_bottom_sheet.dart';

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
      // إذا الـ route مكتمل بالفعل — اظهر مباشرة بلا حركة: البطاقة تُبنى من
      // جديد كلما دخلت الشاشة أثناء التمرير، وتحريك ارتفاعها يزحزح الشبكة.
      if (_routeAnimation!.status == AnimationStatus.completed) {
        _ctrl.value = 1;
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
    AppBottomSheet.show(
      context,
      child: AppBottomSheet(
        title: AppLocalizations.of(context)!.hiddenInCatalogs,
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
    final l10n = AppLocalizations.of(context)!;
    final labelSmall = context.text.labelSmall;

    Widget content;

    if (widget.isProHidden) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.visibility_off_rounded,
              size: 12, color: widget.titleColor.withValues(alpha: 0.5)),
          const SizedBox(width: 4),
          Text(
            l10n.hiddenPro,
            style: labelSmall?.copyWith(
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
                l10n.hidden,
                style: labelSmall?.copyWith(
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
                        style: labelSmall?.copyWith(
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
                  style: labelSmall?.copyWith(
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
