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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 480,
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header Icon ──
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      scheme.primary.withValues(alpha: 0.18),
                      scheme.tertiary.withValues(alpha: 0.18),
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: scheme.primary.withValues(alpha: 0.25),
                    width: 1.5,
                  ),
                ),
                child: Icon(Icons.verified_rounded, size: 36, color: scheme.primary),
              ),
              const SizedBox(height: 16),

              // ── Title ──
              Text(
                isAr ? 'سنان — الإصدار النهائي' : 'Sinan — Final Release',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold, height: 1.3),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'v$version',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: scheme.primary,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Message ──
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? scheme.surfaceContainerHighest.withValues(alpha: 0.5)
                      : scheme.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: scheme.primary.withValues(alpha: 0.15)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.format_quote_rounded,
                        size: 20, color: scheme.primary.withValues(alpha: 0.6)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isAr
                            ? 'وصلنا — بعد أشهر من البناء والصقل، سنان جاهز بكامل قوته.\n\nكل ملاحظة كتبتها، كل خزنة أنشأتها، كل تذكير ضبطته — كلها هنا، محفوظة ومزامنة.'
                            : 'We made it — after months of building and refining, Sinan is ready in full force.\n\nEvery note you wrote, every vault you created, every reminder you set — all here, preserved and synced.',
                        style: TextStyle(
                          fontSize: 13.5,
                          height: 1.75,
                          color: scheme.onSurface.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Divider with label ──
              Row(children: [
                Expanded(child: Divider(color: scheme.outlineVariant)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    isAr ? 'ما الجديد' : "What's New",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface.withValues(alpha: 0.45),
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: scheme.outlineVariant)),
              ]),
              const SizedBox(height: 14),

              // ── Features ──
              _FeatureRow(
                icon: Icons.lock_rounded,
                color: Colors.indigo,
                title: isAr ? 'خزنة ذكية' : 'Smart Vault',
                subtitle: isAr
                    ? 'تشفير AES-256 + بصمة + كود استرداد'
                    : 'AES-256 encryption + biometrics + recovery code',
              ),
              _FeatureRow(
                icon: Icons.code_rounded,
                color: Colors.teal,
                title: isAr ? 'محرر كود احترافي' : 'Pro Code Editor',
                subtitle: isAr
                    ? '26 لغة + معاينة SVG وJSON وMarkdown'
                    : '26 languages + SVG, JSON & Markdown preview',
              ),
              _FeatureRow(
                icon: Icons.cloud_sync_rounded,
                color: Colors.blue,
                title: isAr ? 'مزامنة Google Drive' : 'Google Drive Sync',
                subtitle: isAr
                    ? 'دمج ذكي تلقائي مع حماية الخزنة'
                    : 'Smart auto-merge with vault protection',
              ),
              _FeatureRow(
                icon: Icons.checklist_rounded,
                color: Colors.green,
                title: isAr ? 'قوائم المهام' : 'Checklists',
                subtitle: isAr
                    ? 'سحب لإعادة الترتيب + تقدم مرئي + Undo'
                    : 'Drag to reorder + progress bar + undo',
              ),
              _FeatureRow(
                icon: Icons.swipe_rounded,
                color: Colors.orange,
                title: isAr ? 'إيماءات قابلة للتخصيص' : 'Custom Swipe Actions',
                subtitle: isAr
                    ? 'اختر إجراء السحب يميناً ويساراً بحرية'
                    : 'Choose your left & right swipe actions freely',
              ),
              _FeatureRow(
                icon: Icons.monitor_rounded,
                color: Colors.purple,
                title: isAr ? 'دعم سطح المكتب' : 'Desktop Support',
                subtitle: isAr
                    ? 'تخطيط Master-Details لشاشات Windows وLinux'
                    : 'Master-Details layout for Windows & Linux',
              ),

              const SizedBox(height: 20),

              // ── Thanks ──
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: scheme.secondaryContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(Icons.favorite_rounded,
                        size: 20, color: scheme.secondary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isAr
                            ? 'شكراً لكل من رافق سنان منذ البداية — هذا الإصدار بُني بملاحظاتكم.'
                            : 'Thank you to everyone who followed Sinan from day one — this release was built with your feedback.',
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.6,
                          color: scheme.onSecondaryContainer.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Close Button ──
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: Text(
                    isAr ? 'ابدأ الاستخدام' : 'Get Started',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
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
  final String title;
  final String subtitle;

  const _FeatureRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 19, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 13.5, fontWeight: FontWeight.w600, height: 1.3)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: scheme.onSurface.withValues(alpha: 0.55))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
