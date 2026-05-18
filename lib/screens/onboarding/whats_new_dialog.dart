// Copyright © 2025 Apex Flow Group. All rights reserved.


import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

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
    final isDesktop = MediaQuery.of(context).size.width >= 600;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 80 : 16,
        vertical: isDesktop ? 40 : 24,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isDesktop ? 520 : 480,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
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
                child: Icon(Icons.rocket_launch_rounded,
                    size: 36, color: scheme.primary),
              ),
              const SizedBox(height: 16),

              // ── Title ──
              Text(
                isAr ? 'سطح المكتب والمزامنة الذكية' : 'Desktop & Smart Sync',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 21, fontWeight: FontWeight.bold, height: 1.3),
              ),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                  border:
                      Border.all(color: scheme.primary.withValues(alpha: 0.15)),
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
                            ? 'تحديث كبير يجلب تجربة سطح مكتب احترافية، مزامنة أذكى مع Google Drive، وتحسينات جذرية في العارض والسلة.'
                            : 'A major update bringing a professional desktop experience, smarter Google Drive sync, and deep improvements to the viewer and trash.',
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

              // ── Divider ──
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
                icon: Icons.desktop_windows_rounded,
                color: Colors.indigo,
                title: isAr ? 'سطح مكتب Master-Details' : 'Master-Details Desktop',
                subtitle: isAr
                    ? 'عرض القائمة والمحتوى جنباً إلى جنب مع اختصارات لوحة المفاتيح'
                    : 'Side-by-side list and content with full keyboard shortcuts',
              ),
              _FeatureRow(
                icon: Icons.cloud_sync_rounded,
                color: Colors.blue,
                title: isAr ? 'مزامنة MD5 Fast Path' : 'MD5 Fast Path Sync',
                subtitle: isAr
                    ? 'المزامنة تتخطى الدمج تلقائياً إذا لم يتغير Drive — أسرع وأذكى'
                    : 'Sync skips merge automatically if Drive is unchanged — faster and smarter',
              ),
              _FeatureRow(
                icon: Icons.delete_sweep_rounded,
                color: Colors.red,
                title: isAr ? 'عارض السلة المحسّن' : 'Improved Trash Viewer',
                subtitle: isAr
                    ? 'شريط سفلي قابل للسحب + منع التعديل للملاحظات المحذوفة'
                    : 'Swipeable bottom sheet + edit blocked for trashed notes',
              ),
              _FeatureRow(
                icon: Icons.palette_rounded,
                color: Colors.orange,
                title: isAr ? 'تغيير اللون من العارض' : 'Color Picker in Viewer',
                subtitle: isAr
                    ? 'غيّر لون الملاحظة مباشرة من شاشة العرض بدون فتح المحرر'
                    : 'Change note color directly from the read-only view',
              ),
              _FeatureRow(
                icon: Icons.swap_horiz_rounded,
                color: Colors.teal,
                title: isAr ? 'تحويل النوع من العارض' : 'Convert Type in Viewer',
                subtitle: isAr
                    ? 'حوّل الملاحظة بين النصي والكود والـ Rich Text من شريط الإجراءات'
                    : 'Convert between text, code, and rich text from the action bar',
              ),
              _FeatureRow(
                icon: Icons.check_box_rounded,
                color: Colors.green,
                title: isAr ? 'Checkbox تفاعلي في Rich Note' : 'Interactive Checkbox in Rich Note',
                subtitle: isAr
                    ? 'الضغط على الـ checkbox يُبدّل حالته مباشرة بألوان النوتة'
                    : 'Tap checkbox to toggle it instantly with note colors',
              ),

              const SizedBox(height: 20),

              // ── Privacy Policy update notice ──
              InkWell(
                onTap: () => launchUrl(
                  Uri.parse('https://apexflow.now/ar/projects/sinan-note/privacy'),
                  mode: LaunchMode.externalApplication,
                ),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: scheme.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.privacy_tip_rounded,
                          size: 20, color: scheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isAr
                                  ? 'تحديث سياسة الخصوصية'
                                  : 'Privacy Policy Updated',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: scheme.primary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isAr
                                  ? 'تم تحديث السياسة لتعكس المميزات الجديدة — اضغط للمراجعة'
                                  : 'Policy updated to reflect new features — tap to review',
                              style: TextStyle(
                                fontSize: 11.5,
                                height: 1.4,
                                color: scheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.open_in_new_rounded,
                          size: 16,
                          color: scheme.primary.withValues(alpha: 0.7)),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── Thanks ──
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                            ? 'شكراً لملاحظاتكم — كل تحسين هنا جاء من تجربتكم الحقيقية.'
                            : 'Thanks for your feedback — every improvement here came from your real experience.',
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.6,
                          color: scheme.onSecondaryContainer
                              .withValues(alpha: 0.85),
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
                    isAr ? 'تم' : 'Got it',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
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
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        height: 1.3)),
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

