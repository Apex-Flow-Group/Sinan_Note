// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/controllers/settings/settings_provider.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HeroAnimationInfoSheet {
  static void show(BuildContext context, AppLocalizations l10n) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, _) => Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).padding.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Row(children: [
                const Icon(Icons.auto_awesome_outlined, color: Colors.orange),
                const SizedBox(width: 8),
                Text(isAr ? 'تأثير Hero — تجريبي' : 'Hero Animation — Beta',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 12),
              Text(
                isAr
                    ? 'يضيف تأثير انتقال بصري عند فتح النوتة — الكارد يتمدد ليملأ الشاشة.'
                    : 'Adds a visual transition when opening a note — the card expands to fill the screen.',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 16),
                      const SizedBox(width: 6),
                      Text(isAr ? 'مشاكل معروفة' : 'Known Issues',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ]),
                    const SizedBox(height: 8),
                    _issueRow(isAr ? 'التأثير يطير فوق شريط البحث والتنقل السفلي' : 'Animation flies above search bar and bottom nav'),
                    _issueRow(isAr ? 'تأخر بسيط عند فتح نوتات طويلة جداً' : 'Slight delay when opening very long notes'),
                    _issueRow(isAr ? 'قد يظهر وميض عند التبديل بين الأوضاع' : 'May flicker when switching between modes'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: Consumer<SettingsProvider>(
                  builder: (ctx, s, _) => ElevatedButton.icon(
                    icon: Icon(s.heroAnimationEnabled ? Icons.toggle_on : Icons.toggle_off),
                    label: Text(s.heroAnimationEnabled
                        ? (isAr ? 'تعطيل التأثير' : 'Disable Animation')
                        : (isAr ? 'تجربة التأثير' : 'Try Animation')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: s.heroAnimationEnabled ? Colors.red[400] : Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
