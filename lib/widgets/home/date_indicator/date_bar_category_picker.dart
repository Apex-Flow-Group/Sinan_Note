// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/controllers/categories/categories_provider.dart';
import 'package:apex_note/core/utils/adaptive_color.dart';
import 'package:flutter/material.dart';

class DateBarCategoryPickerSheet {
  static void show(BuildContext context, CategoriesProvider categoriesProvider) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final categories = categoriesProvider.categories;
    final selectedId = categoriesProvider.selectedCategoryId;
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    const catColorIndices = [8, 2, 5, 10, 3, 6, 9, 11];
    Color catColor(int index) {
      final brightness = Theme.of(context).brightness;
      return AppColorPalette.palette[catColorIndices[index % catColorIndices.length]].getColor(brightness);
    }

    final proColor = AppColorPalette.palette[6].getColor(Theme.of(context).brightness);

    Widget catTile({
      required String label,
      required IconData icon,
      required Color accent,
      required bool isSelected,
      required VoidCallback onTap,
    }) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected ? accent.withValues(alpha: isDark ? 0.15 : 0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            onTap: onTap,
            leading: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: isDark ? 0.2 : 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accent, size: 18),
            ),
            title: Text(label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? accent : scheme.onSurface,
                )),
            trailing: isSelected ? Icon(Icons.check_rounded, color: accent, size: 18) : null,
          ),
        ),
      );
    }

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
              decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(children: [
                const Icon(Icons.label_outline_rounded, size: 20),
                const SizedBox(width: 8),
                Text(isAr ? 'اختر كتالوج' : 'Select Catalog',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ]),
            ),
            const Divider(height: 1),
            Flexible(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.45),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    catTile(
                      label: isAr ? 'الكل' : 'All',
                      icon: Icons.all_inbox_rounded,
                      accent: scheme.primary,
                      isSelected: selectedId == null,
                      onTap: () { Navigator.pop(ctx); categoriesProvider.selectCategory(null); },
                    ),
                    catTile(
                      label: isAr ? 'المحترف' : 'Professional',
                      icon: Icons.workspace_premium_rounded,
                      accent: proColor,
                      isSelected: selectedId == kProCategoryId,
                      onTap: () { Navigator.pop(ctx); categoriesProvider.selectCategory(kProCategoryId); },
                    ),
                    ...categories.asMap().entries.map((e) => catTile(
                          label: e.value.name,
                          icon: Icons.bookmark_rounded,
                          accent: catColor(e.key),
                          isSelected: selectedId == e.value.id,
                          onTap: () { Navigator.pop(ctx); categoriesProvider.selectCategory(e.value.id); },
                        )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
