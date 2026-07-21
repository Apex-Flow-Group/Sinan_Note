// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sinan_note/core/utils/platform_helper.dart';
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
                    ? 'شريط أدوات موحّد ومشاركة أذكى'
                    : 'Unified Toolbar & Smarter Sharing',
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
                            ? 'شريط القوائم والبحث أصبحا جزءاً واحداً، المشاركة عبر Apex أصبحت كالمزامنة، وكل وضع عرض يُحفظ منفصلاً.'
                            : 'Menu bar and search are now unified, sharing via Apex works like sync, and each layout saves its own view mode.',
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

              // ── GitHub Open Source ──
              // 🔒 ثابت في كل إصدار — لا يتغير
              // الرابط: https://github.com/Apex-Flow-Group/Sinan_Note
              InkWell(
                onTap: () => launchUrl(
                  Uri.parse('https://github.com/Apex-Flow-Group/Sinan_Note'),
                  mode: LaunchMode.externalApplication,
                ),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                              const Color(0xFF1a1a2e).withValues(alpha: 0.9),
                              const Color(0xFF16213e).withValues(alpha: 0.9),
                            ]
                          : [
                              const Color(0xFF24292e).withValues(alpha: 0.06),
                              const Color(0xFF0366d6).withValues(alpha: 0.06),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.12)
                          : const Color(0xFF24292e).withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : const Color(0xFF24292e).withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.code_rounded,
                          size: 22,
                          color:
                              isDark ? Colors.white : const Color(0xFF24292e),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isAr
                                  ? '🎉 سينان نوت أصبح مفتوح المصدر!'
                                  : '🎉 Sinan Note is now Open Source!',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF24292e),
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isAr
                                  ? 'الكود متاح على GitHub — استكشف، تعلّم، أو شارك في البناء'
                                  : 'Code is live on GitHub — explore, learn, or contribute',
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.4,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.6)
                                    : const Color(0xFF24292e)
                                        .withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.open_in_new_rounded,
                        size: 16,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.4)
                            : const Color(0xFF24292e).withValues(alpha: 0.4),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // ── Features ──
              // ⚠️ ثابت: يتغير مع كل إصدار — قائمة الميزات/الإصلاحات المرئية للمستخدم
              _FeatureRow(
                icon: Icons.menu_open_rounded,
                color: Colors.indigo,
                title: isAr ? 'شريط أدوات موحّد' : 'Unified Toolbar',
                subtitle: isAr
                    ? 'شريط القوائم (File, Edit, View, Help) مدمج مع البحث في شريط واحد أنيق على سطح المكتب'
                    : 'Menu bar (File, Edit, View, Help) merged with search into one sleek bar on desktop',
              ),
              _FeatureRow(
                icon: Icons.share_rounded,
                color: Colors.teal,
                title: isAr ? 'مشاركة ذكية عبر Apex' : 'Smart Sharing via Apex',
                subtitle: isAr
                    ? 'الملاحظات المشاركة تصل كاملة بنوعها — تشيك لست، كود، ريتش — وتُعرض بدون حفظ تلقائي'
                    : 'Shared notes arrive complete with their type — checklist, code, rich — previewed without auto-saving',
              ),
              _FeatureRow(
                icon: Icons.view_agenda_rounded,
                color: Colors.deepPurple,
                title: isAr ? 'حفظ عرض منفصل' : 'Separate View Modes',
                subtitle: isAr
                    ? 'وضع العرض (موسّع/مطوي/شبكة) يُحفظ منفصلاً للجوال وسطح المكتب'
                    : 'View mode (expanded/compact/grid) saved separately for mobile and desktop',
              ),
              _FeatureRow(
                icon: Icons.save_outlined,
                color: Colors.orange,
                title: isAr ? 'سؤال الحفظ عند الخروج' : 'Save Prompt on Exit',
                subtitle: isAr
                    ? 'الملاحظات المستلمة من الخارج لا تُحفظ تلقائياً — يُسألك عند الخروج'
                    : 'Received notes are not auto-saved — you\'re asked before closing',
              ),

              const SizedBox(height: 20),

              // ── Privacy Policy update notice ──
              // 🔒 ثابت في كل إصدار — لا يتغير
              // الرابط: https://apexflow.now/ar/projects/sinan-note/privacy
              InkWell(
                onTap: () => launchUrl(
                  Uri.parse(
                      'https://apexflow.now/ar/projects/sinan-note/privacy'),
                  mode: LaunchMode.externalApplication,
                ),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              // 🔒 ثابت في كل إصدار — نص الشكر لا يتغير
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
