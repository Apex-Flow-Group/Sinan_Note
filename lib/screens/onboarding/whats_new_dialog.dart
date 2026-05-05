// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class WhatsNewDialog extends StatelessWidget {
  final String version;
  const WhatsNewDialog({super.key, required this.version});

  static Future<void> show(BuildContext context) async {
    final info = await PackageInfo.fromPlatform();
    if (!context.mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => WhatsNewDialog(version: info.version),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final scheme = Theme.of(context).colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 480,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── أيقونة ──
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      scheme.primary.withValues(alpha: 0.15),
                      Colors.purple.withValues(alpha: 0.15),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.rocket_launch_rounded,
                    size: 40, color: scheme.primary),
              ),
              const SizedBox(height: 16),

              // ── العنوان ──
              Text(
                isAr ? '🎉 قريباً — النسخة النهائية' : '🎉 Coming Soon — Final Release',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                isAr
                    ? 'الوصول المبكر · الإصدار $version'
                    : 'Early Access · Version $version',
                style: TextStyle(
                    fontSize: 13,
                    color: scheme.onSurface.withValues(alpha: 0.5)),
              ),
              const SizedBox(height: 20),

              // ── الرسالة ──
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: scheme.primary.withValues(alpha: 0.2)),
                ),
                child: Text(
                  isAr
                      ? 'شكراً لكونك جزءاً من رحلة Sinan Note منذ البداية.\n\nهذا آخر تحديث في مرحلة الوصول المبكر — النسخة النهائية في الطريق، وستحمل معها تجربة مصقولة بالكامل بناءً على ملاحظاتكم.\n\nاستمر في استخدام التطبيق، كل ملاحظة تكتبها الآن ستنتقل معك إلى النسخة النهائية.'
                      : 'Thank you for being part of the Sinan Note journey from the start.\n\nThis is the last update in the Early Access phase — the Final Release is on its way, fully polished based on your feedback.\n\nKeep using the app, every note you write now will carry over to the final version.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 14,
                      height: 1.7,
                      color: scheme.onSurface.withValues(alpha: 0.85)),
                ),
              ),
              const SizedBox(height: 16),

              // ── ما الجديد ──
              _FeatureRow(
                icon: Icons.auto_awesome_rounded,
                color: Colors.amber,
                text: isAr
                    ? 'خيارات سحب مخصصة بالكامل'
                    : 'Fully customizable swipe actions',
              ),
              _FeatureRow(
                icon: Icons.alarm_rounded,
                color: Colors.orange,
                text: isAr
                    ? 'تذكير وكتالوج مباشرة من السحب'
                    : 'Reminder & category directly from swipe',
              ),
              _FeatureRow(
                icon: Icons.sync_rounded,
                color: Colors.blue,
                text: isAr
                    ? 'مزامنة ذكية بعد كل حفظ'
                    : 'Smart sync after every save',
              ),
              _FeatureRow(
                icon: Icons.rocket_launch_rounded,
                color: scheme.primary,
                text: isAr
                    ? 'النسخة النهائية قادمة قريباً 🚀'
                    : 'Final version coming soon 🚀',
              ),

              const SizedBox(height: 20),

              // ── شكر المجتمع ──
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.pink.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: Colors.pink.withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    const Text('💙', style: TextStyle(fontSize: 28)),
                    const SizedBox(height: 8),
                    Text(
                      isAr
                          ? 'شكر خاص لكل من جرّب التطبيق، أرسل ملاحظة، أو أبلغ عن مشكلة — أنتم من شكّل هذا التطبيق وجعله أفضل يوماً بعد يوم.'
                          : 'A special thank you to everyone who tried the app, sent feedback, or reported an issue — you shaped this app and made it better day by day.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 13,
                          height: 1.7,
                          color: scheme.onSurface.withValues(alpha: 0.75)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── زر الإغلاق ──
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    isAr ? 'لا يسعدني الانتظار! 🎯' : "Can't wait! 🎯",
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _FeatureRow({
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text,
                style: const TextStyle(fontSize: 13, height: 1.4)),
          ),
        ],
      ),
    );
  }
}
