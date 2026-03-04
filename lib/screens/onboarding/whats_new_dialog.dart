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
                            isArabic ? 'الإصدار 2.2.2' : 'Version 2.2.2',
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
                      icon: Icons.edit,
                      color: Colors.blue,
                      title: isArabic
                          ? '📝 محرر جديد بالكامل'
                          : '📝 Completely New Editor',
                      description: isArabic
                          ? 'محرر محسّن مع دعم ذكي لاتجاه النص (RTL/LTR) لكل فقرة. كتابة عربية وإنجليزية بشكل مثالي.'
                          : 'Enhanced editor with smart text direction support (RTL/LTR) per paragraph. Perfect Arabic and English writing.',
                      isDesktop: isDesktop,
                    ),
                    const SizedBox(height: 16),
                    _WhatsNewFeature(
                      icon: Icons.code,
                      color: Colors.green,
                      title: isArabic
                          ? '💻 25+ لغة برمجة'
                          : '💻 25+ Programming Languages',
                      description: isArabic
                          ? 'دعم موسع لأكثر من 25 لغة برمجة مع تلوين تلقائي. Python, JavaScript, Java, C++, وغيرها.'
                          : 'Extended support for 25+ programming languages with syntax highlighting. Python, JavaScript, Java, C++, and more.',
                      isDesktop: isDesktop,
                    ),
                    const SizedBox(height: 16),
                    _WhatsNewFeature(
                      icon: Icons.transform,
                      color: Colors.purple,
                      title: isArabic
                          ? '🔄 تحويل النوت الذكي'
                          : '🔄 Smart Note Conversion',
                      description: isArabic
                          ? 'تحويل تلقائي بين أنواع الملاحظات (نص ← كود ← قائمة مهام). تنظيم أفضل لملاحظاتك.'
                          : 'Automatic conversion between note types (text ↔ code ↔ checklist). Better organization for your notes.',
                      isDesktop: isDesktop,
                    ),
                    const SizedBox(height: 16),
                    _WhatsNewFeature(
                      icon: Icons.desktop_windows,
                      color: Colors.orange,
                      title: isArabic
                          ? '🖥️ دعم سطح مكتب كامل'
                          : '🖥️ Full Desktop Support',
                      description: isArabic
                          ? 'واجهة محسّنة للتابلت والشاشات الكبيرة. تخطيط Master-Details، قوائم سياقية، وإنتاجية أعلى.'
                          : 'Enhanced interface for tablets and large screens. Master-Details layout, context menus, and higher productivity.',
                      isDesktop: isDesktop,
                    ),
                    const SizedBox(height: 16),
                    _WhatsNewFeature(
                      icon: Icons.notifications_active,
                      color: Colors.teal,
                      title: isArabic
                          ? '🔔 إشعارات ذكية'
                          : '🔔 Smart Notifications',
                      description: isArabic
                          ? 'نظام إشعارات موحد مع مؤقت دائري وتراجع ذكي. لديك 3 ثوانٍ للتراجع قبل تنفيذ أي عملية.'
                          : 'Unified notification system with circular timer and smart undo. You have 3 seconds to undo before any action.',
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
