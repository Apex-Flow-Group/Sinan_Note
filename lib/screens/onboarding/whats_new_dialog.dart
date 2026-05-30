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
                isAr
                    ? 'إصلاحات المحرر وتحسينات التجربة'
                    : 'Editor Fixes & Experience Improvements',
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
                            ? 'إصلاحات دقيقة في المحرر، اتجاه النص، والمشاركة — مع تحسينات أداء تجعل المحرر أسرع مع النصوص الطويلة.'
                            : 'Precise fixes in the editor, text direction, and sharing — plus performance improvements that make the editor faster with long texts.',
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
                          color: isDark ? Colors.white : const Color(0xFF24292e),
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
              _FeatureRow(
                icon: Icons.label_rounded,
                color: Colors.teal,
                title: isAr ? 'كتالوج من التحديد المتعدد' : 'Catalog in Multi-Select',
                subtitle: isAr
                    ? 'عيّن عدة ملاحظات لكتالوج دفعة واحدة من شريط التحديد'
                    : 'Assign multiple notes to a catalog at once from the selection bar',
              ),
              _FeatureRow(
                icon: Icons.share_rounded,
                color: Colors.blue,
                title: isAr ? 'مشاركة المحتوى كاملاً' : 'Full Content Sharing',
                subtitle: isAr
                    ? 'إصلاح قطع المحتوى عند المشاركة — الملاحظة تُرسل كاملة'
                    : 'Fixed content truncation on share — full note is always sent',
              ),
              _FeatureRow(
                icon: Icons.speed_rounded,
                color: Colors.purple,
                title: isAr ? 'محرر أسرع مع النصوص الطويلة' : 'Faster Editor for Long Texts',
                subtitle: isAr
                    ? 'debounce + hash comparison + مسح سريع للخلف — أداء أفضل مع الروايات'
                    : 'Debounce + hash comparison + fast backward scan — better with novels',
              ),
              _FeatureRow(
                icon: Icons.format_textdirection_r_to_l_rounded,
                color: Colors.orange,
                title: isAr ? 'اتجاه النص محفوظ بعد الحفظ' : 'Text Direction Preserved After Save',
                subtitle: isAr
                    ? 'إصلاح عودة الاتجاه لليسار بعد الحفظ، وتوقف اتجاه اللصق في المنتصف'
                    : 'Fixed direction resetting to LTR after save and paste direction stopping mid-text',
              ),
              _FeatureRow(
                icon: Icons.security_rounded,
                color: Colors.indigo,
                title:
                    isAr ? 'خزنة أقوى وأكثر أماناً' : 'Stronger Vault Security',
                subtitle: isAr
                    ? 'تشفير PBKDF2 بـ 100,000 تكرار + إصلاح ظهور أول ملاحظة فوراً'
                    : 'PBKDF2 with 100,000 iterations + first note appears instantly',
              ),
              _FeatureRow(
                icon: Icons.checklist_rounded,
                color: Colors.green,
                title: isAr ? 'قائمة المهام محسّنة' : 'Improved Checklist',
                subtitle: isAr
                    ? 'سحب يساراً للحذف مع تراجع، زر إضافة واحد في الأسفل، تصميم أنظف'
                    : 'Swipe left to delete with undo, single add button, cleaner design',
              ),
              _FeatureRow(
                icon: Icons.touch_app_rounded,
                color: Colors.orange,
                title: isAr ? 'سحب الكارد المخصص' : 'Custom Card Swipe',
                subtitle: isAr
                    ? 'أضف تذكيراً أو تصنيفاً أو انسخ الملاحظة مباشرة من السحب'
                    : 'Add reminder, category, or duplicate note directly from swipe',
              ),
              _FeatureRow(
                icon: Icons.check_box_rounded,
                color: Colors.teal,
                title: isAr
                    ? 'Checkbox تفاعلي في Rich Note'
                    : 'Interactive Checkbox in Rich Note',
                subtitle: isAr
                    ? 'اضغط على الـ checkbox لتبديل حالته مباشرة بألوان الملاحظة'
                    : 'Tap to toggle checkbox instantly with note accent colors',
              ),
              _FeatureRow(
                icon: Icons.code_rounded,
                color: Colors.blue,
                title: isAr
                    ? 'محرر الكود — معاينة وتحميل'
                    : 'Code Editor — Preview & Download',
                subtitle: isAr
                    ? 'SVG كصورة حقيقية، JSON منسق، تحميل بالامتداد الصحيح للتنزيلات'
                    : 'SVG as real image, formatted JSON, download with correct extension',
              ),
              _FeatureRow(
                icon: Icons.speed_rounded,
                color: Colors.purple,
                title: isAr
                    ? 'أداء أسرع وسكرول أسلس'
                    : 'Faster Performance & Smoother Scroll',
                subtitle: isAr
                    ? 'حذف الظلال الثقيلة من الكاردات + تحسينات شاملة في إعادة البناء'
                    : 'Removed heavy card shadows + comprehensive rebuild optimizations',
              ),
              _FeatureRow(
                icon: Icons.bug_report_rounded,
                color: Colors.red,
                title: isAr ? 'إصلاحات متعددة' : 'Multiple Bug Fixes',
                subtitle: isAr
                    ? 'إصلاح ترجمة وقت المزامنة، SnackBar خارج الشاشة، وغيرها'
                    : 'Fixed sync time translation, off-screen SnackBar, and more',
              ),

              const SizedBox(height: 20),

              // ── Privacy Policy update notice ──
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
