// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:sinan_note/domain/categories.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';
import 'package:sinan_note/ui/core/theme/note_palette.dart';
import 'package:sinan_note/ui/core/widgets/app_bottom_sheet.dart';
import 'package:sinan_note/ui/features/categories/view_models/categories_provider.dart';

class DateBarCategoryPickerSheet {
  static void show(
      BuildContext context, CategoriesProvider categoriesProvider) {
    final l10n = AppLocalizations.of(context)!;
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
        title: l10n.selectCatalog,
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
                  label: l10n.all,
                  icon: Icons.all_inbox_rounded,
                  accent: scheme.primary,
                  isSelected: selectedId == null,
                  onTap: () {
                    Navigator.pop(context);
                    categoriesProvider.selectCategory(null);
                  },
                ),
                catTile(
                  label: l10n.professional,
                  icon: Icons.workspace_premium_rounded,
                  accent: proColor,
                  isSelected: selectedId == CategoryPolicy.proCategoryId,
                  onTap: () {
                    Navigator.pop(context);
                    categoriesProvider
                        .selectCategory(CategoryPolicy.proCategoryId);
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
