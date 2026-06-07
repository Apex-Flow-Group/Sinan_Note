// Copyright © 2025 Apex Flow Group. All rights reserved.


import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sinan_note/controllers/categories/categories_provider.dart';
import 'package:sinan_note/core/utils/adaptive_color.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';
import 'package:sinan_note/widgets/common/app_bottom_sheet.dart';

class CategoryPickerSheet extends StatefulWidget {
  final List<int> selectedIds;
  final bool isHiddenFromHome;

  const CategoryPickerSheet({
    super.key,
    required this.selectedIds,
    required this.isHiddenFromHome,
  });

  /// يفتح الـ sheet ويُرجع map بـ categoryIds و isHiddenFromHome أو null إذا أُلغي
  static Future<Map<String, dynamic>?> show(
      BuildContext context, List<int> current,
      {bool isHiddenFromHome = false}) {
    return AppBottomSheet.show<Map<String, dynamic>>(
      context,
      isScrollControlled: true,
      child: CategoryPickerSheet(
        selectedIds: current,
        isHiddenFromHome: isHiddenFromHome,
      ),
    );
  }

  @override
  State<CategoryPickerSheet> createState() => _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends State<CategoryPickerSheet> {
  late Set<int> _selected;
  bool _hideFromHome = false;

  static const _catColorIndices = [8, 2, 5, 10, 3, 6, 9, 11];

  Color _catColor(int index) {
    final brightness = Theme.of(context).brightness;
    final paletteIndex = _catColorIndices[index % _catColorIndices.length];
    return AppColorPalette.palette[paletteIndex].getColor(brightness);
  }

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.selectedIds);
    _hideFromHome = widget.isHiddenFromHome;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final cats = context.watch<CategoriesProvider>().categories;

    return AppBottomSheet(
      title: l10n.categories,
      titleIcon: Icons.label_rounded,
      scrollable: false,
      actions: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded),
          tooltip: l10n.cancel,
          visualDensity: VisualDensity.compact,
        ),
        IconButton.filled(
          onPressed: () => Navigator.pop(context, {
            'categoryIds': _selected.toList(),
            'isHiddenFromHome': _hideFromHome,
          }),
          icon: const Icon(Icons.check_rounded),
          tooltip: l10n.save,
          visualDensity: VisualDensity.compact,
        ),
        const SizedBox(width: 4),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ─── القائمة ───
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.45,
            ),
            child: cats.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(l10n.noResults,
                        style: TextStyle(color: scheme.onSurfaceVariant)),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: cats.length,
                    itemBuilder: (_, i) {
                      final cat = cats[i];
                      final checked = _selected.contains(cat.id);
                      final color = _catColor(i);
                      return CheckboxListTile(
                        value: checked,
                        onChanged: (_) => setState(() {
                          if (checked) {
                            _selected.remove(cat.id);
                            if (_selected.isEmpty) _hideFromHome = false;
                          } else {
                            _selected.add(cat.id);
                          }
                        }),
                        title: Text(cat.name),
                        secondary: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.bookmark_rounded,
                              size: 16, color: color),
                        ),
                        activeColor: color,
                        checkColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        controlAffinity: ListTileControlAffinity.trailing,
                      );
                    },
                  ),
          ),

          Divider(height: 1, color: scheme.outlineVariant),
          const SizedBox(height: 8),

          // ─── زر الإخفاء ───
          if (_selected.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: InkWell(
                onTap: () => setState(() => _hideFromHome = !_hideFromHome),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: _hideFromHome
                        ? scheme.primary.withValues(alpha: 0.12)
                        : scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _hideFromHome
                          ? scheme.primary
                          : scheme.outlineVariant,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _hideFromHome
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        color: _hideFromHome
                            ? scheme.primary
                            : scheme.onSurfaceVariant,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.hideProFromHome,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _hideFromHome
                                    ? scheme.primary
                                    : scheme.onSurface,
                              ),
                            ),
                            Text(
                              _hideFromHome
                                  ? l10n.hiddenFromHomeDesc
                                  : l10n.visibleInHomeDesc,
                              style: TextStyle(
                                  fontSize: 12, color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        _hideFromHome
                            ? Icons.check_circle_rounded
                            : Icons.circle_outlined,
                        color: _hideFromHome
                            ? scheme.primary
                            : scheme.outlineVariant,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

