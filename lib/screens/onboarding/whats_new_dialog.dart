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
                        const Icon(Icons.celebration, color: Colors.blue, size: 28),
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
                          const Icon(Icons.rocket_launch, color: Colors.blue, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            isArabic ? 'الإصدار 3.0.2' : 'Version 3.0.2',
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
                      icon: Icons.cloud_sync_rounded,
                      color: Colors.blue,
                      title: isArabic ? '☁️ مزامنة Google Drive أذكى' : '☁️ Smarter Google Drive Sync',
                      description: isArabic
                          ? 'المزامنة الآن تعمل على مستوى كل ملاحظة — لا تضيع تعديلاتك عند فتح التطبيق من جهازين. الكتالوجات تُزامَن أيضاً.'
                          : 'Sync now works at the note level — your edits won\'t be lost when opening from two devices. Catalogs are synced too.',
                      isDesktop: isDesktop,
                    ),
                    const SizedBox(height: 16),
                    _WhatsNewFeature(
                      icon: Icons.lock_rounded,
                      color: Colors.orange,
                      title: isArabic ? '🔐 الخزنة محلية بالكامل' : '🔐 Vault is Fully Local',
                      description: isArabic
                          ? 'الملاحظات المشفرة لا تُرفع إلى Google Drive أبداً. الخزنة محلية 100% لحماية خصوصيتك.'
                          : 'Encrypted notes are never uploaded to Google Drive. The vault is 100% local to protect your privacy.',
                      isDesktop: isDesktop,
                    ),
                    const SizedBox(height: 16),
                    _WhatsNewFeature(
                      icon: Icons.speed_rounded,
                      color: Colors.green,
                      title: isArabic ? '⚡ فتح الخزنة أسرع' : '⚡ Faster Vault Opening',
                      description: isArabic
                          ? 'فك تشفير الملاحظات الآن يعمل بشكل متوازٍ — وقت التحميل أقل بكثير مع عدد كبير من الملاحظات.'
                          : 'Note decryption now runs in parallel — much faster loading with large numbers of notes.',
                      isDesktop: isDesktop,
                    ),
                    const SizedBox(height: 16),
                    _WhatsNewFeature(
                      icon: Icons.bug_report_rounded,
                      color: Colors.purple,
                      title: isArabic ? '🔧 إصلاحات متعددة' : '🔧 Multiple Fixes',
                      description: isArabic
                          ? 'إصلاح حفظ تغيير اللون في الخزنة، إضافة الجيك لست لقائمة الإضافة، وتحسينات في شريط التمرير.'
                          : 'Fixed color change saving in vault, added checklist to the add menu, and scrollbar improvements.',
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
                          const Icon(Icons.favorite, color: Colors.red, size: 18),
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
