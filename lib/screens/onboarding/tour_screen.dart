// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/controllers/settings/settings_provider.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:apex_note/screens/shared/main_layout_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

/// Max content width for large screens (tablets/desktop)
const double _kMaxContentWidth = 600.0;

class TourScreen extends StatefulWidget {
  const TourScreen({super.key});

  @override
  State<TourScreen> createState() => _TourScreenState();
}

class _TourScreenState extends State<TourScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isAgreed = false;

  static const int _totalPages = 8;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final systemLocale =
        View.of(context).platformDispatcher.locale.languageCode;
    final currentLang = settings.languageCode == 'system'
        ? systemLocale
        : settings.languageCode;
    final isArabic = currentLang == 'ar';

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A1929),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) =>
                      setState(() => _currentPage = index),
                  children: [
                    // 1. الترحيب — ما هو التطبيق
                    _buildPageWelcome(context),
                    // 2. أنواع الملاحظات — الجوهر الأساسي
                    _buildPage1(context),
                    // 3. التصنيفات — تنظيم الملاحظات
                    _buildPage8(context),
                    // 4. التذكيرات — إضافة قيمة
                    _buildPage3(context),
                    // 5. الخزنة — الأمان
                    _buildPage4(context),
                    // 6. المزامنة — الاستمرارية
                    _buildPage5(context),
                    // 7. مميزات إضافية — الختام
                    _buildPage6(context),
                    // 8. الاتفاقية + ابدأ — آخر صفحة دائماً
                    _buildPageAgreement(context),
                  ],
                ),
              ),
              _buildBottomBar(context),
            ],
          ),
        ),
      ),
    );
  }

  // ── صفحة الترحيب ──────────────────────────────────────────────────────────
  Widget _buildPageWelcome(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _TourPage(
      icon: Icons.edit_note,
      title: l10n.tourPage1Title,
      description: l10n.tourPage1Desc,
      features: [
        _FeatureItem(icon: Icons.note_outlined, text: '${l10n.simpleNote}: ${l10n.simpleNoteDesc}'),
        _FeatureItem(icon: Icons.format_paint_rounded, text: l10n.tourRichNote),
        _FeatureItem(icon: Icons.code, text: '${l10n.proEditor}: ${l10n.proEditorDesc}'),
        _FeatureItem(icon: Icons.alarm, text: '${l10n.reminder}: ${l10n.reminderDesc}'),
        _FeatureItem(icon: Icons.check_box, text: l10n.checklists),
      ],
    );
  }

  // ── أنواع الملاحظات ────────────────────────────────────────────────────────
  Widget _buildPage1(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _TourPage(
      icon: Icons.calculate,
      title: l10n.tourPage2Title,
      description: l10n.tourPage2Desc,
      features: [
        const _FeatureItem(icon: Icons.add, text: '50 + 20 ='),
        const _FeatureItem(icon: Icons.auto_awesome, text: '= 70'),
        const _FeatureItem(icon: Icons.functions, text: '+, -, ×, ÷'),
        _FeatureItem(icon: Icons.analytics_outlined, text: l10n.approximateSum),
      ],
    );
  }

  // ── التصنيفات ──────────────────────────────────────────────────────────────
  Widget _buildPage8(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _TourPage(
      icon: Icons.label_rounded,
      title: l10n.tourPage8Title,
      description: l10n.tourPage8Desc,
      features: [
        _FeatureItem(icon: Icons.create_new_folder_outlined, text: l10n.tourCatCreate),
        _FeatureItem(icon: Icons.filter_list_rounded, text: l10n.tourCatFilter),
        _FeatureItem(icon: Icons.edit_outlined, text: l10n.tourCatEdit),
        _FeatureItem(icon: Icons.playlist_add_check_rounded, text: l10n.tourCatAssign),
      ],
    );
  }

  // ── التذكيرات ──────────────────────────────────────────────────────────────
  Widget _buildPage3(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _TourPage(
      icon: Icons.calendar_today,
      title: l10n.tourPage3Title,
      description: l10n.tourPage3Desc,
      features: [
        _FeatureItem(icon: Icons.today, text: l10n.today),
        _FeatureItem(icon: Icons.date_range, text: l10n.thisWeek),
        _FeatureItem(icon: Icons.event, text: l10n.date),
        _FeatureItem(icon: Icons.alarm_add, text: l10n.addReminder),
      ],
    );
  }

  // ── الخزنة ─────────────────────────────────────────────────────────────────
  Widget _buildPage4(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _TourPage(
      icon: Icons.lock,
      title: l10n.tourPage4Title,
      description: l10n.tourPage4Desc,
      features: [
        _FeatureItem(icon: Icons.enhanced_encryption, text: l10n.encryptionUsed),
        _FeatureItem(icon: Icons.fingerprint, text: l10n.authenticateWithBiometric),
        _FeatureItem(icon: Icons.lock_clock, text: l10n.sessionProtection),
        _FeatureItem(icon: Icons.security, text: l10n.dataEncryptedOnExit),
      ],
    );
  }

  // ── المزامنة ───────────────────────────────────────────────────────────────
  Widget _buildPage5(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _TourPage(
      icon: Icons.cloud_sync,
      title: l10n.tourPage5Title,
      description: l10n.tourPage5Desc,
      features: [
        _FeatureItem(icon: Icons.cloud_upload, text: l10n.tourGoogleDriveSync),
        _FeatureItem(icon: Icons.merge, text: l10n.tourSmartMerge),
        _FeatureItem(icon: Icons.cloud_done, text: l10n.tourCloudBackup),
      ],
    );
  }

  // ── مميزات إضافية ──────────────────────────────────────────────────────────
  Widget _buildPage6(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _TourPage(
      icon: Icons.auto_awesome,
      title: l10n.tourPage6Title,
      description: l10n.tourPage6Desc,
      features: [
        _FeatureItem(icon: Icons.palette, text: l10n.noteColors),
        _FeatureItem(icon: Icons.dark_mode, text: l10n.theme),
        _FeatureItem(icon: Icons.history, text: l10n.tourVersionHistory),
        _FeatureItem(icon: Icons.widgets, text: l10n.tourHomeWidget),
        _FeatureItem(icon: Icons.swap_horiz, text: l10n.tourNoteConversion),
      ],
    );
  }

  // ── الاتفاقية + ابدأ (آخر صفحة) ───────────────────────────────────────────
  Widget _buildPageAgreement(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final systemLocale =
        View.of(context).platformDispatcher.locale.languageCode;
    final currentLang = settings.languageCode == 'system'
        ? systemLocale
        : settings.languageCode;
    final isArabic = currentLang == 'ar';

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _kMaxContentWidth),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.rocket_launch,
                          size: 80, color: Color(0xFFFFD700)),
                      const SizedBox(height: 32),
                      Text(
                        l10n.startNow,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 48),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Checkbox(
                            value: _isAgreed,
                            onChanged: (val) =>
                                setState(() => _isAgreed = val ?? false),
                            activeColor: const Color(0xFFFFD700),
                          ),
                          Flexible(
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: isArabic
                                        ? 'أوافق على '
                                        : 'I agree to the ',
                                    style:
                                        const TextStyle(color: Colors.white70),
                                  ),
                                  WidgetSpan(
                                    child: GestureDetector(
                                      onTap: _openTerms,
                                      child: Text(
                                        isArabic
                                            ? 'شروط الخدمة'
                                            : 'Terms of Service',
                                        style: const TextStyle(
                                          color: Colors.blue,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: _isAgreed ? _navigateToHome : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _isAgreed ? const Color(0xFFFFD700) : Colors.grey,
                          foregroundColor: const Color(0xFF0A1929),
                          minimumSize: const Size(double.infinity, 52),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(26)),
                        ),
                        child: Text(
                          l10n.startNow,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isLastPage = _currentPage == _totalPages - 1;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _kMaxContentWidth),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _totalPages,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? const Color(0xFFFFD700)
                          : const Color(0xFFFFD700).withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (!isLastPage) ...[
                ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    foregroundColor: const Color(0xFF0A1929),
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  child: Text(
                    l10n.next,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    _pageController.jumpToPage(_totalPages - 1);
                  },
                  child: Text(
                    l10n.skip,
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToHome() async {
    if (!_isAgreed) return;
    await Provider.of<SettingsProvider>(context, listen: false).completeSetup();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const MainLayoutScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
      (route) => false,
    );
  }

  static const _channel = MethodChannel('com.apexflow.app.sinan/launcher');

  void _openTerms() async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final systemLocale =
        View.of(context).platformDispatcher.locale.languageCode;
    final currentLang = settings.languageCode == 'system'
        ? systemLocale
        : settings.languageCode;
    final url = currentLang == 'ar'
        ? 'https://apexflow.now/ar/projects/sinan-note/terms'
        : 'https://apexflow.now/en/projects/sinan-note/terms';
    try {
      await _channel.invokeMethod('launch', url);
    } catch (_) {}
  }
}

class _TourPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final List<_FeatureItem> features;

  const _TourPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.features,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _kMaxContentWidth),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF132F4C),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 28, color: const Color(0xFFFFD700)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _kMaxContentWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      description,
                      style: const TextStyle(
                          fontSize: 16, color: Colors.white70, height: 1.5),
                    ),
                    const SizedBox(height: 24),
                    ...features.map((feature) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Icon(feature.icon,
                                  size: 20, color: const Color(0xFFFFD700)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  feature.text,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FeatureItem {
  final IconData icon;
  final String text;

  const _FeatureItem({required this.icon, required this.text});
}
