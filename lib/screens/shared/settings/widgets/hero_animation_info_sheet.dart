// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/controllers/settings/settings_provider.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:apex_note/widgets/common/app_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HeroAnimationInfoSheet {
  static void show(BuildContext context, AppLocalizations l10n) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    AppBottomSheet.show(
      context,
      child: AppBottomSheet(
        title: isAr ? 'تأثير Hero — تجريبي' : 'Hero Animation — Beta',
        titleIcon: Icons.auto_awesome_outlined,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              20, 8, 20, MediaQuery.of(context).padding.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isAr
                    ? 'يضيف تأثير انتقال بصري عند فتح النوتة — الكارد يتمدد ليملأ الشاشة بسلاسة.'
                    : 'Adds a smooth visual transition when opening a note — the card expands to fill the screen.',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.info_outline_rounded,
                          color: Colors.blue, size: 16),
                      const SizedBox(width: 6),
                      Text(isAr ? 'ملاحظة' : 'Note',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13)),
                    ]),
                    const SizedBox(height: 8),
                    Text(
                      isAr
                          ? 'التأثير يعمل عند فتح النوتة في وضع القراءة فقط. قد يختلف الأداء حسب الجهاز.'
                          : 'The effect works when opening notes in read-only mode. Performance may vary by device.',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: Consumer<SettingsProvider>(
                  builder: (ctx, s, _) => ElevatedButton.icon(
                    icon: Icon(s.heroAnimationEnabled
                        ? Icons.toggle_on
                        : Icons.toggle_off),
                    label: Text(s.heroAnimationEnabled
                        ? (isAr ? 'تعطيل التأثير' : 'Disable Animation')
                        : (isAr ? 'تجربة التأثير' : 'Try Animation')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: s.heroAnimationEnabled
                          ? Colors.red[400]
                          : Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      s.setHeroAnimationEnabled(!s.heroAnimationEnabled);
                      Navigator.pop(ctx);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _issueRow(String text) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('• ', style: TextStyle(color: Colors.orange)),
            Expanded(child: Text(text, style: const TextStyle(fontSize: 12))),
          ],
        ),
      );
}
