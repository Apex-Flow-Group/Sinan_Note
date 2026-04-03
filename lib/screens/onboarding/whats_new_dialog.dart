// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';

class WhatsNewDialog extends StatelessWidget {
  const WhatsNewDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const WhatsNewDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 600;
    final dialogWidth = isDesktop ? 520.0 : screenWidth * 0.9;

    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.celebration,
                            color: Colors.blue, size: 28),
                        const SizedBox(width: 12),
                        Text(
                          isArabic ? 'ما الجديد؟' : "What's New?",
                          style: TextStyle(
                            fontSize: isDesktop ? 22 : 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.rocket_launch,
                              color: Colors.blue, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            isArabic ? 'الإصدار 3.0.1' : 'Version 3.0.1',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: isDesktop ? 17 : 15,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _WhatsNewFeature(
                      icon: Icons.label_rounded,
                      color: Colors.blue,
                      title: isArabic
                          ? '🏷️ تحسينات الكتالوج'
                          : '🏷️ Catalog Improvements',
                      description: isArabic
                          ? 'اختر كتالوجاً مختلفاً مباشرة من شريط الكتالوج بنقرة واحدة، مع إصلاح عرض اسم كتالوج المحترف.'
                          : 'Switch catalogs directly from the catalog bar with one tap, with a fix for the Professional catalog name display.',
                      isDesktop: isDesktop,
                    ),
                    const SizedBox(height: 16),
                    _WhatsNewFeature(
                      icon: Icons.speed_rounded,
                      color: Colors.orange,
                      title: isArabic
                          ? '⚡ تمرير أسرع وأسلس'
                          : '⚡ Faster & Smoother Scrolling',
                      description: isArabic
                          ? 'تحسين كبير في أداء التمرير مع 600+ ملاحظة، وشريط تمرير جانبي بحركة ناعمة بدون قفز.'
                          : 'Major scrolling performance improvement with 600+ notes, and a smooth sidebar scrollbar without jumping.',
                      isDesktop: isDesktop,
                    ),
                    const SizedBox(height: 16),
                    _WhatsNewFeature(
                      icon: Icons.bug_report_rounded,
                      color: Colors.green,
                      title:
                          isArabic ? '🔧 إصلاحات متعددة' : '🔧 Multiple Fixes',
                      description: isArabic
                          ? 'إصلاح لون شريط البحث عند فتح التطبيق، إصلاح عرض النص الخام في السلة، وتحسين شريط الاستعادة في السلة.'
                          : 'Fixed search bar color on app launch, fixed raw text display in trash, and improved the restore bar in trash.',
                      isDesktop: isDesktop,
                    ),
                    const SizedBox(height: 16),
                    _WhatsNewFeature(
                      icon: Icons.cleaning_services_rounded,
                      color: Colors.purple,
                      title: isArabic ? '🧹 تنظيف الكود' : '🧹 Code Cleanup',
                      description: isArabic
                          ? 'توحيد منطق تحويل المحتوى في ملف واحد (NoteContentUtils) بدل تكراره في 7 أماكن مختلفة.'
                          : 'Unified content conversion logic in one file (NoteContentUtils) instead of repeating it in 7 different places.',
                      isDesktop: isDesktop,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.favorite,
                              color: Colors.red, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isArabic
                                  ? 'شكراً لاستخدامك سنان نوت! نحن نعمل باستمرار لتحسين تجربتك.'
                                  : "Thank you for using Sinan Note! We're constantly working to improve your experience.",
                              style: TextStyle(
                                fontSize: isDesktop ? 13 : 12,
                                color: Colors.grey[700],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    isArabic ? 'حسناً' : 'Got it',
                    style: TextStyle(fontSize: isDesktop ? 16 : 14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WhatsNewFeature extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final bool isDesktop;

  const _WhatsNewFeature({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    this.isDesktop = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: isDesktop ? 24 : 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isDesktop ? 16 : 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: isDesktop ? 14 : 13,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
