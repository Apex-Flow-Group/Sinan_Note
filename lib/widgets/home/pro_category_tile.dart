// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sinan_note/controllers/categories/categories_provider.dart';
import 'package:sinan_note/core/utils/adaptive_color.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';

class ProCategoryTile extends StatefulWidget {
  final bool isSelected;
  final ColorScheme scheme;
  final bool isDark;
  final String label;
  final VoidCallback onTap;

  const ProCategoryTile({
    super.key,
    required this.isSelected,
    required this.scheme,
    required this.isDark,
    required this.label,
    required this.onTap,
  });

  @override
  State<ProCategoryTile> createState() => _ProCategoryTileState();
}

class _ProCategoryTileState extends State<ProCategoryTile> {
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
