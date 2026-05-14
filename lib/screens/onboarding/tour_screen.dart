// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/controllers/settings/settings_provider.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:apex_note/screens/shared/main_layout_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

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
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final systemLocale =
        View.of(context).platformDispatcher.locale.languageCode;
    final lang = settings.languageCode == 'system'
        ? systemLocale
        : settings.languageCode;
    final url = lang == 'ar'
        ? 'https://apexflow.now/ar/projects/sinan-note/terms'
        : 'https://apexflow.now/en/projects/sinan-note/terms';
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
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final systemLocale =
        View.of(context).platformDispatcher.locale.languageCode;
    final lang = settings.languageCode == 'system'
        ? systemLocale
        : settings.languageCode;
    final isAr = lang == 'ar';

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A1929),
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
                              color: Color(0xFFFFD700), size: 36),
                          const SizedBox(height: 12),
                          Text(
                            isAr ? 'كل ما تحتاجه في مكان واحد' : 'Everything you need in one place',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
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
                          _Item(Icons.notes_rounded, isAr ? 'ملاحظة نصية بسيطة وسريعة' : 'Simple plain text note'),
                          _Item(Icons.format_paint_rounded, l10n.tourRichNote),
                          _Item(Icons.code_rounded, isAr ? 'محرر كود مع تمييز الصياغة' : 'Code editor with syntax highlighting'),
                          _Item(Icons.alarm_rounded, isAr ? 'تذكير بتاريخ ووقت محدد' : 'Reminder with date and time'),
                          _Item(Icons.check_box_rounded, isAr ? 'قائمة مهام تفاعلية' : 'Interactive checklist'),
                        ],
                      ),
                      _TourSection(
                        icon: Icons.label_rounded,
                        title: l10n.tourPage8Title,
                        subtitle: l10n.tourPage8Desc,
                        items: [
                          _Item(Icons.create_new_folder_outlined, l10n.tourCatCreate),
                          _Item(Icons.filter_list_rounded, l10n.tourCatFilter),
                          _Item(Icons.edit_outlined, l10n.tourCatEdit),
                          _Item(Icons.playlist_add_check_rounded, l10n.tourCatAssign),
                        ],
                      ),
                      _TourSection(
                        icon: Icons.alarm_rounded,
                        title: l10n.tourPage3Title,
                        subtitle: l10n.tourPage3Desc,
                        items: [
                          _Item(Icons.today_rounded, isAr ? 'تذكيرات لمرة واحدة' : 'One-time reminders'),
                          _Item(Icons.repeat_rounded, isAr ? 'تذكيرات متكررة يومياً أو أسبوعياً' : 'Daily or weekly recurring reminders'),
                          _Item(Icons.notifications_active_rounded, isAr ? 'إشعار فوري في الوقت المحدد' : 'Instant notification at set time'),
                        ],
                      ),
                      _TourSection(
                        icon: Icons.lock_rounded,
                        title: l10n.tourPage4Title,
                        subtitle: l10n.tourPage4Desc,
                        items: [
                          _Item(Icons.enhanced_encryption_rounded, l10n.encryptionUsed),
                          _Item(Icons.fingerprint_rounded, l10n.authenticateWithBiometric),
                          _Item(Icons.cloud_off_rounded, isAr ? 'الخزنة محلية فقط — لا تُرفع أبداً' : 'Vault is local only — never uploaded'),
                        ],
                      ),
                      _TourSection(
                        icon: Icons.cloud_sync_rounded,
                        title: l10n.tourPage5Title,
                        subtitle: l10n.tourPage5Desc,
                        items: [
                          _Item(Icons.cloud_upload_rounded, l10n.tourGoogleDriveSync),
                          _Item(Icons.merge_rounded, l10n.tourSmartMerge),
                          _Item(Icons.devices_rounded, isAr ? 'مزامنة بين أجهزة متعددة' : 'Sync across multiple devices'),
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
                          _Item(Icons.swap_horiz_rounded, l10n.tourNoteConversion),
                        ],
                      ),

                      // ── Agreement ──────────────────────────────────────
                      const SizedBox(height: 8),
                      _AgreementSection(
                        isAgreed: _isAgreed,
                        isAr: isAr,
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
                              backgroundColor: const Color(0xFFFFD700),
                              disabledBackgroundColor: const Color(0xFF444444),
                              foregroundColor: const Color(0xFF0A1929),
                              disabledForegroundColor: Colors.grey[600],
                              minimumSize: const Size(double.infinity, 54),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(27),
                              ),
                              elevation: _isAgreed ? 4 : 0,
                            ),
                            child: Text(
                              l10n.startNow,
                              style: const TextStyle(
                                fontSize: 18,
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
          color: const Color(0xFF132F4C),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFFFD700).withValues(alpha: 0.12),
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
                      color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: const Color(0xFFFFD700), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontSize: 12,
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
              color: const Color(0xFFFFD700).withValues(alpha: 0.1),
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
                                  color: const Color(0xFFFFD700)
                                      .withValues(alpha: 0.8)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  item.text,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
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
  final bool isAr;
  final ValueChanged<bool> onChanged;
  final VoidCallback onTermsTap;
  final AppLocalizations l10n;

  const _AgreementSection({
    required this.isAgreed,
    required this.isAr,
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
          color: const Color(0xFF132F4C),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isAgreed
                ? const Color(0xFFFFD700).withValues(alpha: 0.4)
                : const Color(0xFFFFD700).withValues(alpha: 0.12),
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
                  color: isAgreed
                      ? const Color(0xFFFFD700)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isAgreed
                        ? const Color(0xFFFFD700)
                        : Colors.white38,
                    width: 2,
                  ),
                ),
                child: isAgreed
                    ? const Icon(Icons.check_rounded,
                        size: 16, color: Color(0xFF0A1929))
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: isAr ? 'أوافق على ' : 'I agree to the ',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 14),
                      ),
                      WidgetSpan(
                        child: GestureDetector(
                          onTap: onTermsTap,
                          child: Text(
                            l10n.termsOfService,
                            style: const TextStyle(
                              color: Color(0xFF64B5F6),
                              fontSize: 14,
                              decoration: TextDecoration.underline,
                              decorationColor: Color(0xFF64B5F6),
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
