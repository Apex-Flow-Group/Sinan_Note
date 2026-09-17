// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sinan_note/core/utils/platform_helper.dart';

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
    final isDesktop = PlatformHelper.isWideDisplay(context);

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
              // ⚠️ ثابت: يتغير مع كل إصدار — عنوان رئيسي يعكس محتوى التحديث
              Text(
                isAr
                    ? 'تمرير أهدأ وأقسام للمثبّت'
                    : 'Calmer Scrolling & Pinned Sections',
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
              // ⚠️ ثابت: يتغير مع كل إصدار — ملخص قصير للتحديث
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
                            ? 'التمرير صار يتباطأ بهدوء حتى التوقف ويقف عند آخر ملاحظة، والمثبّتة أصبحت في قسم خاص، ومعاينة البطاقات تُقرأ بلا اهتزاز.'
                            : 'Scrolling now eases to a calm stop and holds at the last note, pinned notes have their own section, and card previews read cleanly without jitter.',
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
              const SizedBox(height: 18),

              // ── Features ──
              // ⚠️ ثابت: يتغير مع كل إصدار — قائمة الميزات/الإصلاحات المرئية للمستخدم
              _FeatureRow(
                icon: Icons.swipe_vertical_rounded,
                color: Colors.indigo,
                title: isAr ? 'تمرير بتباطؤ هادئ' : 'Calm Scroll Deceleration',
                subtitle: isAr
                    ? 'السحبة تتباطأ تدريجياً حتى تسكن، وتميّز السحبة الخفيفة من القوية، وتتوقف عند آخر ملاحظة بلا ارتداد'
                    : 'Flings ease down to a full stop, light and strong swipes travel differently, and the list holds at the last note without bouncing',
              ),
              _FeatureRow(
                icon: Icons.push_pin_rounded,
                color: Colors.teal,
                title: isAr ? 'قسم للمثبّتة' : 'Pinned Section',
                subtitle: isAr
                    ? 'الملاحظات المثبّتة أصبحت في قسم مستقل أعلى الشاشة، وبقيتها تحت قسم «أخرى»'
                    : 'Pinned notes now sit in their own section at the top, with the rest grouped under “Others”',
              ),
              _FeatureRow(
                icon: Icons.text_fields_rounded,
                color: Colors.deepPurple,
                title: isAr ? 'معاينة بطاقات أنظف' : 'Cleaner Card Previews',
                subtitle: isAr
                    ? 'المعاينة تعرض نص الملاحظة دائماً بدل شيفرة التنسيق، وارتفاع البطاقة ثابت فلا يهتز النص أثناء التمرير'
                    : 'Previews always show the note text instead of formatting code, and card height stays fixed so text no longer jitters while scrolling',
              ),

              const SizedBox(height: 22),

              // ── Close Button ──
              // 🔒 ثابت في كل إصدار — زر الإغلاق لا يتغير
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
