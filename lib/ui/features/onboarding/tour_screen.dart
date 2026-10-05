// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';
import 'package:sinan_note/ui/core/theme/app_colors.dart';
import 'package:sinan_note/ui/core/theme/onboarding_palette.dart';
import 'package:sinan_note/ui/features/layout/main_layout_screen.dart';
import 'package:sinan_note/ui/features/settings/view_models/settings_provider.dart';

const double _kMaxWidth = 600.0;

class TourScreen extends StatefulWidget {
  const TourScreen({super.key});

  @override
  State<TourScreen> createState() => _TourScreenState();
}

class _TourScreenState extends State<TourScreen> {
  bool _isAgreed = false;

  static const _channel = MethodChannel('com.apexflow.app.sinan/launcher');

  void _openTerms() async {
    final url = AppLocalizations.of(context)!.termsOfServiceUrl;
    try {
      await _channel.invokeMethod('launch', url);
    } catch (_) {}
  }

  void _navigateToHome() async {
    if (!_isAgreed) return;
    await Provider.of<SettingsProvider>(context, listen: false).completeSetup();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const MainLayoutScreen(),
        settings: const RouteSettings(name: '/main'),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: OnboardingPalette.night,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _kMaxWidth),
            child: CustomScrollView(
              slivers: [
                // ── Header ──────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 8),
                    child: Column(
                      children: [
                        const Icon(Icons.auto_awesome,
                            color: OnboardingPalette.gold, size: 36),
                        const SizedBox(height: 12),
                        Text(
                          l10n.tourHeadline,
                          style: context.text.headlineSmall?.copyWith(
                            color: OnboardingPalette.ink,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Sections ─────────────────────────────────────────────
                SliverList(
                  delegate: SliverChildListDelegate([
                    _TourSection(
                      icon: Icons.edit_note_rounded,
                      title: l10n.tourPage1Title,
                      subtitle: l10n.tourPage1Desc,
                      items: [
                        _Item(Icons.notes_rounded, l10n.tourPlainNote),
                        _Item(Icons.format_paint_rounded, l10n.tourRichNote),
                        _Item(Icons.code_rounded, l10n.tourCodeNote),
                        _Item(Icons.alarm_rounded, l10n.tourReminderNote),
                        _Item(Icons.check_box_rounded, l10n.tourChecklistNote),
                      ],
                    ),
                    _TourSection(
                      icon: Icons.label_rounded,
                      title: l10n.tourPage8Title,
                      subtitle: l10n.tourPage8Desc,
                      items: [
                        _Item(Icons.create_new_folder_outlined,
                            l10n.tourCatCreate),
                        _Item(Icons.filter_list_rounded, l10n.tourCatFilter),
                        _Item(Icons.edit_outlined, l10n.tourCatEdit),
                        _Item(Icons.playlist_add_check_rounded,
                            l10n.tourCatAssign),
                      ],
                    ),
                    _TourSection(
                      icon: Icons.alarm_rounded,
                      title: l10n.tourPage3Title,
                      subtitle: l10n.tourPage3Desc,
                      items: [
                        _Item(Icons.today_rounded, l10n.tourOneTimeReminders),
                        _Item(
                            Icons.repeat_rounded, l10n.tourRecurringReminders),
                        _Item(Icons.notifications_active_rounded,
                            l10n.tourInstantNotification),
                      ],
                    ),
                    _TourSection(
                      icon: Icons.lock_rounded,
                      title: l10n.tourPage4Title,
                      subtitle: l10n.tourPage4Desc,
                      items: [
                        _Item(Icons.enhanced_encryption_rounded,
                            l10n.encryptionUsed),
                        _Item(Icons.fingerprint_rounded,
                            l10n.authenticateWithBiometric),
                        _Item(Icons.cloud_off_rounded, l10n.tourVaultLocalOnly),
                      ],
                    ),
                    _TourSection(
                      icon: Icons.cloud_sync_rounded,
                      title: l10n.tourPage5Title,
                      subtitle: l10n.tourPage5Desc,
                      items: [
                        _Item(Icons.cloud_upload_rounded,
                            l10n.tourGoogleDriveSync),
                        _Item(Icons.merge_rounded, l10n.tourSmartMerge),
                        _Item(Icons.devices_rounded, l10n.tourMultiDeviceSync),
                      ],
                    ),
                    _TourSection(
                      icon: Icons.auto_awesome_rounded,
                      title: l10n.tourPage6Title,
                      subtitle: l10n.tourPage6Desc,
                      items: [
                        _Item(Icons.palette_rounded, l10n.noteColors),
                        _Item(Icons.history_rounded, l10n.tourVersionHistory),
                        _Item(Icons.widgets_rounded, l10n.tourHomeWidget),
                        _Item(
                            Icons.swap_horiz_rounded, l10n.tourNoteConversion),
                      ],
                    ),

                    // ── Agreement ──────────────────────────────────────
                    const SizedBox(height: 8),
                    _AgreementSection(
                      isAgreed: _isAgreed,
                      onChanged: (v) => setState(() => _isAgreed = v),
                      onTermsTap: _openTerms,
                      l10n: l10n,
                    ),

                    // ── Start Button ───────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                      child: AnimatedOpacity(
                        opacity: _isAgreed ? 1.0 : 0.4,
                        duration: const Duration(milliseconds: 300),
                        child: ElevatedButton(
                          onPressed: _isAgreed ? _navigateToHome : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: OnboardingPalette.gold,
                            disabledBackgroundColor:
                                OnboardingPalette.disabledButton,
                            foregroundColor: OnboardingPalette.night,
                            disabledForegroundColor:
                                OnboardingPalette.disabledInk,
                            minimumSize: const Size(double.infinity, 54),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(27),
                            ),
                            elevation: _isAgreed ? 4 : 0,
                          ),
                          child: Text(
                            l10n.startNow,
                            style: context.text.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Section Widget ────────────────────────────────────────────────────────────

class _Item {
  final IconData icon;
  final String text;
  const _Item(this.icon, this.text);
}

class _TourSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<_Item> items;

  const _TourSection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Container(
        decoration: BoxDecoration(
          color: OnboardingPalette.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: OnboardingPalette.gold.withValues(alpha: 0.12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: OnboardingPalette.gold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: OnboardingPalette.gold, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: context.text.titleMedium?.copyWith(
                            color: OnboardingPalette.ink,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: context.text.labelMedium?.copyWith(
                            color:
                                OnboardingPalette.ink.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Divider
            Divider(
              height: 1,
              color: OnboardingPalette.gold.withValues(alpha: 0.1),
            ),
            // Items
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: Column(
                children: items
                    .map((item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(
                            children: [
                              Icon(item.icon,
                                  size: 18,
                                  color: OnboardingPalette.gold
                                      .withValues(alpha: 0.8)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  item.text,
                                  style: context.text.bodyMedium?.copyWith(
                                    color: OnboardingPalette.ink,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Agreement Widget ──────────────────────────────────────────────────────────

class _AgreementSection extends StatelessWidget {
  final bool isAgreed;
  final ValueChanged<bool> onChanged;
  final VoidCallback onTermsTap;
  final AppLocalizations l10n;

  const _AgreementSection({
    required this.isAgreed,
    required this.onChanged,
    required this.onTermsTap,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: OnboardingPalette.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isAgreed
                ? OnboardingPalette.gold.withValues(alpha: 0.4)
                : OnboardingPalette.gold.withValues(alpha: 0.12),
          ),
        ),
        child: GestureDetector(
          onTap: () => onChanged(!isAgreed),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isAgreed ? OnboardingPalette.gold : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isAgreed
                        ? OnboardingPalette.gold
                        : OnboardingPalette.ink.withValues(alpha: 0.38),
                    width: 2,
                  ),
                ),
                child: isAgreed
                    ? const Icon(Icons.check_rounded,
                        size: 16, color: OnboardingPalette.night)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: l10n.tourAgreePrefix,
                        style: context.text.bodyMedium?.copyWith(
                            color:
                                OnboardingPalette.ink.withValues(alpha: 0.7)),
                      ),
                      WidgetSpan(
                        child: GestureDetector(
                          onTap: onTermsTap,
                          child: Text(
                            l10n.termsOfService,
                            style: context.text.bodyMedium?.copyWith(
                              color: OnboardingPalette.link,
                              decoration: TextDecoration.underline,
                              decorationColor: OnboardingPalette.link,
                            ),
                          ),
                        ),
                      ),
                    ],
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
