// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/controllers/categories/categories_provider.dart';
import 'package:apex_note/core/utils/adaptive_color.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:apex_note/models/category.dart';
import 'package:apex_note/services/unified_notification_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum CatPanelMode { normal, delete, edit }

class CategoriesPanel extends StatefulWidget {
  final CatPanelMode mode;
  final bool isAdding;
  final VoidCallback onAddDone;
  final VoidCallback? onCategorySelected;

  const CategoriesPanel({
    super.key,
    required this.mode,
    required this.isAdding,
    required this.onAddDone,
    this.onCategorySelected,
  });

  @override
  State<CategoriesPanel> createState() => _CategoriesPanelState();
}

class _CategoriesPanelState extends State<CategoriesPanel> {
  // ألوان الكتالوجات — من نظام الألوان الديناميكي (adaptive light/dark)
  static const _catColorIndices = [
    8,
    2,
    5,
    10,
    3,
    6,
    9,
    11
  ]; // Blue, Red, Green, Pink, Orange, Teal, Purple, Brown

  Color _catColor(int index, Brightness brightness) {
    final paletteIndex = _catColorIndices[index % _catColorIndices.length];
    return AppColorPalette.palette[paletteIndex].getColor(brightness);
  }

  int? _editingId;
  final _addCtrl = TextEditingController();
  final _editCtrl = TextEditingController();
  final _addFocus = FocusNode();
  final _editFocus = FocusNode();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final l10n = AppLocalizations.of(context)!;
    context.read<CategoriesProvider>().seedIfEmpty([
      l10n.catWork,
      l10n.catPersonal,
      l10n.catIdeas,
      l10n.catTasks,
    ]);
  }

  @override
  void didUpdateWidget(CategoriesPanel old) {
    super.didUpdateWidget(old);
    if (widget.isAdding && !old.isAdding) {
      _addCtrl.clear();
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _addFocus.requestFocus());
    }
  }

  @override
  void dispose() {
    _addCtrl.dispose();
    _editCtrl.dispose();
    _addFocus.dispose();
    _editFocus.dispose();
    super.dispose();
  }

  void _commitAdd(CategoriesProvider provider) async {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    if (provider.categories.length >= kMaxCategories) {
      _addCtrl.clear();
      widget.onAddDone();
      if (!mounted) return;
      UnifiedNotificationService().show(
        context: context,
        message: isArabic
            ? '🎯 وصلت للحد الأقصى! 20 كتالوج يكفي لتنظيم العالم كله 😄'
            : '🎯 Max reached! 20 catalogs is enough to organize the whole world 😄',
        type: NotificationType.info,
        duration: const Duration(seconds: 3),
      );
      return;
    }
    final success = await provider.addCategory(_addCtrl.text);
    _addCtrl.clear();
    widget.onAddDone();
    if (!success && mounted) {
      final isAr = Localizations.localeOf(context).languageCode == 'ar';
      UnifiedNotificationService().show(
        context: context,
        message:
            isAr ? '⚠️ اسم غير صالح أو مكرر' : '⚠️ Invalid or duplicate name',
        type: NotificationType.error,
      );
    }
  }

  void _startEditing(NoteCategory cat) {
    setState(() {
      _editingId = cat.id;
      _editCtrl.text = cat.name;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _editFocus.requestFocus();
      _editCtrl.selection =
          TextSelection(baseOffset: 0, extentOffset: _editCtrl.text.length);
    });
  }

  void _commitEdit(CategoriesProvider provider) async {
    if (_editingId != null) {
      await provider.renameCategory(_editingId!, _editCtrl.text);
    }
    setState(() => _editingId = null);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<CategoriesProvider>(
      builder: (context, provider, _) {
        final cats = provider.categories;
        final selected = provider.selectedCategoryId;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _CatTile(
              label: l10n.allNotes,
              icon: Icons.all_inbox_rounded,
              accentColor: scheme.primary,
              isSelected: selected == null,
              scheme: scheme,
              isDark: isDark,
              mode: CatPanelMode.normal,
              onTap: () {
                provider.selectCategory(null);
                Navigator.pop(context);
                Navigator.popUntil(context, (route) => route.isFirst);
                widget.onCategorySelected?.call();
              },
            ),
            // كتالوج المحترف الثابت
            _ProCategoryTile(
              isSelected: selected == kProCategoryId,
              scheme: scheme,
              isDark: isDark,
              label: l10n.professional,
              onTap: () {
                provider.selectCategory(kProCategoryId);
                Navigator.pop(context);
                Navigator.popUntil(context, (route) => route.isFirst);
                widget.onCategorySelected?.call();
              },
            ),
            ...cats.asMap().entries.map((entry) {
              final i = entry.key;
              final cat = entry.value;
              final color = _catColor(i, Theme.of(context).brightness);
              if (_editingId == cat.id) {
                return _InlineField(
                  controller: _editCtrl,
                  focusNode: _editFocus,
                  scheme: scheme,
                  accentColor: color,
                  onSubmit: () => _commitEdit(provider),
                  onCancel: () => setState(() => _editingId = null),
                );
              }
              return _CatTile(
                label: cat.name,
                icon: Icons.bookmark_rounded,
                accentColor: color,
                isSelected: selected == cat.id,
                scheme: scheme,
                isDark: isDark,
                mode: widget.mode,
                onTap: () {
                  if (widget.mode == CatPanelMode.edit) {
                    _startEditing(cat);
                  } else if (widget.mode == CatPanelMode.delete) {
                    _confirmDelete(context, provider, cat, l10n);
                  } else {
                    provider.selectCategory(cat.id);
                    Navigator.pop(context);
                    Navigator.popUntil(context, (route) => route.isFirst);
                    widget.onCategorySelected?.call();
                  }
                },
                onActionTap: widget.mode == CatPanelMode.delete
                    ? () => _confirmDelete(context, provider, cat, l10n)
                    : widget.mode == CatPanelMode.edit
                        ? () => _startEditing(cat)
                        : null,
              );
            }),
            if (widget.isAdding)
              _InlineField(
                controller: _addCtrl,
                focusNode: _addFocus,
                scheme: scheme,
                accentColor: _catColor(
                    provider.categories.length, Theme.of(context).brightness),
                onSubmit: () => _commitAdd(provider),
                onCancel: widget.onAddDone,
              ),
          ],
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, CategoriesProvider provider,
      NoteCategory cat, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteCategory),
        content: Text('"${cat.name}"'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              provider.deleteCategory(cat.id);
            },
            child: Text(l10n.delete,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }
}

class _CatTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color accentColor;
  final bool isSelected;
  final ColorScheme scheme;
  final bool isDark;
  final CatPanelMode mode;
  final VoidCallback onTap;
  final VoidCallback? onActionTap;

  const _CatTile({
    required this.label,
    required this.icon,
    required this.accentColor,
    required this.isSelected,
    required this.scheme,
    required this.isDark,
    required this.mode,
    required this.onTap,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final actionIcon = mode == CatPanelMode.delete
        ? Icons.delete_outline_rounded
        : mode == CatPanelMode.edit
            ? Icons.edit_outlined
            : null;
    final actionColor =
        mode == CatPanelMode.delete ? scheme.error : accentColor;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withValues(alpha: isDark ? 0.15 : 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          onTap: onTap,
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: isDark ? 0.2 : 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accentColor, size: 18),
          ),
          title: Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? accentColor : scheme.onSurface,
            ),
          ),
          trailing: actionIcon != null && onActionTap != null
              ? GestureDetector(
                  onTap: onActionTap,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(actionIcon,
                        size: 18, color: actionColor.withValues(alpha: 0.7)),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

class _ProCategoryTile extends StatefulWidget {
  final bool isSelected;
  final ColorScheme scheme;
  final bool isDark;
  final String label;
  final VoidCallback onTap;

  const _ProCategoryTile({
    required this.isSelected,
    required this.scheme,
    required this.isDark,
    required this.label,
    required this.onTap,
  });

  @override
  State<_ProCategoryTile> createState() => _ProCategoryTileState();
}

class _ProCategoryTileState extends State<_ProCategoryTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CategoriesProvider>();
    final proColor =
        AppColorPalette.palette[6].getColor(Theme.of(context).brightness);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? proColor.withValues(alpha: widget.isDark ? 0.15 : 0.08)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              onTap: widget.onTap,
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: proColor.withValues(alpha: widget.isDark ? 0.2 : 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.workspace_premium_rounded,
                    color: proColor, size: 18),
              ),
              title: Text(
                widget.label,
                style: TextStyle(
                  fontWeight:
                      widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: widget.isSelected ? proColor : widget.scheme.onSurface,
                ),
              ),
              trailing: GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    _expanded
                        ? Icons.expand_less_rounded
                        : Icons.settings_rounded,
                    size: 22,
                    color: proColor.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
          ),
          // خيارات الترس تتوسع للأسفل
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: _expanded
                ? Container(
                    margin: const EdgeInsets.only(top: 4, bottom: 4),
                    decoration: BoxDecoration(
                      color: proColor.withValues(
                          alpha: widget.isDark ? 0.08 : 0.04),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: proColor.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SwitchListTile(
                          dense: true,
                          value: provider.hideProFromHome,
                          onChanged: (v) => provider.setHideProFromHome(v),
                          title: Text(
                            AppLocalizations.of(context)!.hideProFromHome,
                            style: const TextStyle(fontSize: 13),
                          ),
                          activeThumbColor: proColor,
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _InlineField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ColorScheme scheme;
  final Color accentColor;
  final VoidCallback onSubmit;
  final VoidCallback onCancel;

  const _InlineField({
    required this.controller,
    required this.focusNode,
    required this.scheme,
    required this.accentColor,
    required this.onSubmit,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              textInputAction: TextInputAction.done,
              maxLength: kMaxCategoryNameLength,
              maxLines: 1,
              onSubmitted: (_) => onSubmit(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: scheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.categoryNameHint,
                isDense: true,
                counterText: '',
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: accentColor, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onSubmit,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.check_rounded, size: 18, color: accentColor),
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onCancel,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: scheme.onSurfaceVariant.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.close_rounded,
                  size: 18, color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
