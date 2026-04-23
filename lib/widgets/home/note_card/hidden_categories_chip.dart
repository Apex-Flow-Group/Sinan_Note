// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/controllers/categories/categories_provider.dart';
import 'package:apex_note/models/note.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HiddenCategoriesChip extends StatelessWidget {
  final Note note;
  final Color titleColor;
  final bool isProHidden;

  const HiddenCategoriesChip({
    super.key,
    required this.note,
    required this.titleColor,
    this.isProHidden = false,
  });

  void _showAllCategories(BuildContext context, List<String> names) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.visibility_off_rounded, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    isAr ? 'مخفي في الكتالوجات' : 'Hidden in catalogs',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
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

    if (isProHidden) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.visibility_off_rounded, size: 12,
                color: titleColor.withValues(alpha: 0.5)),
            const SizedBox(width: 4),
            Text(
              isAr ? 'مخفي (محترف)' : 'Hidden (Pro)',
              style: TextStyle(
                fontSize: 11,
                color: titleColor.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    final catNames = note.categoryIds
        .map((id) => catProvider.categories
            .where((c) => c.id == id)
            .map((c) => c.name)
            .firstOrNull)
        .whereType<String>()
        .toList();

    final displayNames = catNames.take(2).toList();
    final extra = catNames.length - displayNames.length;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: GestureDetector(
        onTap: extra > 0 ? () => _showAllCategories(context, catNames) : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.visibility_off_rounded, size: 12,
                color: titleColor.withValues(alpha: 0.5)),
            const SizedBox(width: 4),
            if (catNames.isEmpty)
              Text(
                isAr ? 'مخفي' : 'Hidden',
                style: TextStyle(fontSize: 11, color: titleColor.withValues(alpha: 0.5)),
              )
            else
              ...displayNames.map((name) => Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: titleColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    name,
                    style: TextStyle(
                      fontSize: 10,
                      color: titleColor.withValues(alpha: 0.55),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              )),
            if (extra > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: titleColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '+$extra',
                  style: TextStyle(
                    fontSize: 10,
                    color: titleColor.withValues(alpha: 0.55),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
