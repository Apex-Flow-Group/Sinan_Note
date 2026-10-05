// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sinan_note/core/utils/platform_helper.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';
import 'package:sinan_note/ui/core/theme/app_colors.dart';
import 'package:sinan_note/ui/core/theme/onboarding_palette.dart';
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
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // حبر بطاقة GitHub: لون GitHub في الفاتح، ونص السطح في الداكن.
    final githubInk = isDark ? scheme.onSurface : OnboardingPalette.githubInk;
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
                l10n.whatsNewHeadline,
                textAlign: TextAlign.center,
                style: context.text.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold, height: 1.3),
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
                  style: context.text.labelMedium?.copyWith(
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
                        l10n.whatsNewSummary,
                        style: context.text.bodySmall?.copyWith(
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
                    l10n.whatsNew,
                    style: context.text.labelSmall?.copyWith(
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
                              OnboardingPalette.githubNightStart
                                  .withValues(alpha: 0.9),
                              OnboardingPalette.githubNightEnd
                                  .withValues(alpha: 0.9),
                            ]
                          : [
                              OnboardingPalette.githubInk
                                  .withValues(alpha: 0.06),
                              OnboardingPalette.githubBlue
                                  .withValues(alpha: 0.06),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: githubInk.withValues(alpha: isDark ? 0.12 : 0.15),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: githubInk.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.code_rounded,
                          size: 22,
                          color: githubInk,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.whatsNewOpenSourceTitle,
                              style: context.text.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: githubInk,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.whatsNewOpenSourceSubtitle,
                              style: context.text.labelMedium?.copyWith(
                                height: 1.4,
                                color: githubInk.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.open_in_new_rounded,
                        size: 16,
                        color: githubInk.withValues(alpha: 0.4),
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
                color: context.colors.info,
                title: l10n.whatsNewUnifiedToolbarTitle,
                subtitle: l10n.whatsNewUnifiedToolbarDesc,
              ),
              _FeatureRow(
                icon: Icons.share_rounded,
                color: scheme.tertiary,
                title: l10n.whatsNewApexSharingTitle,
                subtitle: l10n.whatsNewApexSharingDesc,
              ),
              _FeatureRow(
                icon: Icons.view_agenda_rounded,
                color: scheme.secondary,
                title: l10n.whatsNewViewModesTitle,
                subtitle: l10n.whatsNewViewModesDesc,
              ),
              _FeatureRow(
                icon: Icons.save_outlined,
                color: context.colors.warning,
                title: l10n.whatsNewSavePromptTitle,
                subtitle: l10n.whatsNewSavePromptDesc,
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
                              l10n.privacyPolicyUpdatedTitle,
                              style: context.text.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: scheme.primary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              l10n.privacyPolicyUpdatedDesc,
                              style: context.text.labelSmall?.copyWith(
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
                        l10n.whatsNewThanks,
                        style: context.text.labelMedium?.copyWith(
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
                    l10n.gotIt,
                    style: context.text.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
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
                    style: context.text.bodySmall
                        ?.copyWith(fontWeight: FontWeight.w600, height: 1.3)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: context.text.labelMedium?.copyWith(
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
