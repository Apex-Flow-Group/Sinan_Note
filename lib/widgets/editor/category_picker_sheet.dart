// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/controllers/categories/categories_provider.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => CategoryPickerSheet(
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

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ─── Handle ───
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: scheme.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),

            // ─── عنوان ───
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(Icons.label_rounded, size: 20, color: scheme.primary),
                  const SizedBox(width: 8),
                  Text(l10n.categories,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Divider(height: 1, color: scheme.outlineVariant),

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
                        return CheckboxListTile(
                          value: checked,
                          onChanged: (_) => setState(() {
                            if (checked) {
                              _selected.remove(cat.id);
                            } else {
                              _selected.add(cat.id);
                            }
                          }),
                          title: Text(cat.name),
                          secondary: Icon(
                            Icons.label_rounded,
                            size: 18,
                            color: checked
                                ? scheme.primary
                                : scheme.onSurfaceVariant,
                          ),
                          activeColor: scheme.primary,
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                          color: _hideFromHome ? scheme.primary : scheme.onSurfaceVariant,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.hideProFromHome,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: _hideFromHome ? scheme.primary : scheme.onSurface,
                                ),
                              ),
                              Text(
                                _hideFromHome
                                    ? AppLocalizations.of(context)!.hiddenFromHomeDesc
                                    : AppLocalizations.of(context)!.visibleInHomeDesc,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          _hideFromHome ? Icons.check_circle_rounded : Icons.circle_outlined,
                          color: _hideFromHome ? scheme.primary : scheme.outlineVariant,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 8),

            // ─── أزرار ───
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    tooltip: AppLocalizations.of(context)!.cancel,
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: () => Navigator.pop(context, {
                      'categoryIds': _selected.toList(),
                      'isHiddenFromHome': _hideFromHome,
                    }),
                    icon: const Icon(Icons.check_rounded),
                    tooltip: AppLocalizations.of(context)!.save,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}
