// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/controllers/categories/categories_provider.dart';
import 'package:apex_note/core/utils/adaptive_color.dart';
import 'package:apex_note/widgets/common/app_bottom_sheet.dart';
import 'package:flutter/material.dart';

class DateBarCategoryPickerSheet {
  static void show(
      BuildContext context, CategoriesProvider categoriesProvider) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final categories = categoriesProvider.categories;
    final selectedId = categoriesProvider.selectedCategoryId;
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    const catColorIndices = [8, 2, 5, 10, 3, 6, 9, 11];
    Color catColor(int index) {
      final brightness = Theme.of(context).brightness;
      return AppColorPalette
          .palette[catColorIndices[index % catColorIndices.length]]
          .getColor(brightness);
    }

    final proColor =
        AppColorPalette.palette[6].getColor(Theme.of(context).brightness);

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
            color: isSelected
                ? accent.withValues(alpha: isDark ? 0.15 : 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            onTap: onTap,
            leading: Container(
              width: 36,
              height: 36,
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
            trailing: isSelected
                ? Icon(Icons.check_rounded, color: accent, size: 18)
                : null,
          ),
        ),
      );
    }

    AppBottomSheet.show(
      context,
      child: AppBottomSheet(
        title: isAr ? 'اختر كتالوج' : 'Select Catalog',
        titleIcon: Icons.label_outline_rounded,
        scrollable: false,
        child: Flexible(
          child: ConstrainedBox(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.45),
            child: ListView(
              shrinkWrap: true,
              children: [
                catTile(
                  label: isAr ? 'الكل' : 'All',
                  icon: Icons.all_inbox_rounded,
                  accent: scheme.primary,
                  isSelected: selectedId == null,
                  onTap: () {
                    Navigator.pop(context);
                    categoriesProvider.selectCategory(null);
                  },
                ),
                catTile(
                  label: isAr ? 'المحترف' : 'Professional',
                  icon: Icons.workspace_premium_rounded,
                  accent: proColor,
                  isSelected: selectedId == kProCategoryId,
                  onTap: () {
                    Navigator.pop(context);
                    categoriesProvider.selectCategory(kProCategoryId);
                  },
                ),
                ...categories.asMap().entries.map((e) => catTile(
                      label: e.value.name,
                      icon: Icons.bookmark_rounded,
                      accent: catColor(e.key),
                      isSelected: selectedId == e.value.id,
                      onTap: () {
                        Navigator.pop(context);
                        categoriesProvider.selectCategory(e.value.id);
                      },
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
