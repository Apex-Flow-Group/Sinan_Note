// Copyright © 2025 Apex Flow Group. All rights reserved.


import 'package:flutter/material.dart';
import 'package:sinan_note/controllers/settings/settings_provider.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';

class FontFamilySheet extends StatefulWidget {
  final SettingsProvider settings;
  final AppLocalizations l10n;

  const FontFamilySheet({super.key, required this.settings, required this.l10n});

  @override
  State<FontFamilySheet> createState() => _FontFamilySheetState();
}

class _FontFamilySheetState extends State<FontFamilySheet> {
  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.settings.fontFamily;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final cs = Theme.of(context).colorScheme;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    final fonts = [
      ('system', l10n.fontFamilySystem, l10n.fontFamilySystemDesc),
      ('Cairo', 'Cairo', l10n.fontFamilyCairoDesc),
      ('Tajawal', 'Tajawal', l10n.fontFamilyTajawalDesc),
      ('Vazirmatn', 'Vazirmatn', l10n.fontFamilyVazirmatnDesc),
    ];

    final previewFont = _selected == 'system' ? null : _selected;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  const Icon(Icons.font_download_outlined, size: 20),
                  const SizedBox(width: 8),
                  Text(l10n.fontFamily,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.check_rounded, color: cs.primary),
                    tooltip: l10n.ok,
                    onPressed: () {
                      widget.settings.setFontFamily(_selected);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ...fonts.map((f) {
              final isSelected = _selected == f.$1;
              final itemFont = f.$1 == 'system' ? null : f.$1;
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? cs.primary.withValues(alpha: 0.12)
                            : cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isAr ? 'سنان' : 'Sinan',
                        style: TextStyle(
                          fontFamily: itemFont,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? cs.primary : cs.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(f.$2,
                            style: TextStyle(
                              fontFamily: itemFont,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? cs.primary : null,
                            ),
                          ),
                          Text(f.$3,
                            style: TextStyle(
                              fontFamily: itemFont,
                              fontSize: 12,
                              color: cs.onSurface.withValues(alpha: 0.55),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                trailing: isSelected
                    ? Icon(Icons.check_circle_rounded, color: cs.primary)
                    : null,
                onTap: () => setState(() => _selected = f.$1),
              );
            }),
            const Divider(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'سنان نوت — رفيقك الحاد والموثوق',
                      style: TextStyle(
                        fontFamily: previewFont,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sinan Note — Your sharp and reliable companion',
                      style: TextStyle(
                        fontFamily: previewFont,
                        fontSize: 13,
                        color: cs.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

