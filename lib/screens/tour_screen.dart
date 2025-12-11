// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/settings_provider.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'main_layout_screen.dart';
import 'transfer_screen.dart';
import '../config/flavor_config.dart';

class TourScreen extends StatefulWidget {
  const TourScreen({super.key});

  @override
  State<TourScreen> createState() => _TourScreenState();
}

class _TourScreenState extends State<TourScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

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
    final systemLocale = View.of(context).platformDispatcher.locale.languageCode;
    final currentLang = settings.languageCode == 'system' ? systemLocale : settings.languageCode;
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
                  onPageChanged: (index) => setState(() => _currentPage = index),
                  children: [
                    _buildPage1(context),
                    _buildPage2(context),
                    _buildPage3(context),
                    _buildPage4(context),
                    _buildPage5(context),
                    _buildPage6(context),
                    _buildPage7(context),
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

  Widget _buildPage1(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _TourPage(
      icon: Icons.edit_note,
      title: l10n.tourPage1Title,
      description: l10n.tourPage1Desc,
      features: [
        _FeatureItem(icon: Icons.note_outlined, text: '${l10n.simpleNote}: ${l10n.simpleNoteDesc}'),
        _FeatureItem(icon: Icons.code, text: '${l10n.proEditor}: ${l10n.proEditorDesc}'),
        _FeatureItem(icon: Icons.alarm, text: '${l10n.reminder}: ${l10n.reminderDesc}'),
        _FeatureItem(icon: Icons.check_box, text: l10n.checklists),
      ],
    );
  }

  Widget _buildPage2(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _TourPage(
      icon: Icons.calculate,
      title: l10n.tourPage2Title,
      description: l10n.tourPage2Desc,
      features: [
        _FeatureItem(icon: Icons.add, text: '50 + 20 ='),
        _FeatureItem(icon: Icons.auto_awesome, text: '= 70'),
        _FeatureItem(icon: Icons.functions, text: '+, -, ×, ÷'),
        _FeatureItem(icon: Icons.analytics_outlined, text: l10n.approximateSum),
      ],
    );
  }

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

  Widget _buildPage5(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _TourPage(
      icon: Icons.sync,
      title: l10n.tourPage5Title,
      description: l10n.tourPage5Desc,
      features: [
        if (FlavorConfig.hasTransferFeature) _FeatureItem(icon: Icons.phone_android, text: l10n.localNetworkTransfer),
        _FeatureItem(icon: Icons.upload_file, text: l10n.exportJson),
        _FeatureItem(icon: Icons.download, text: l10n.importJson),
        _FeatureItem(icon: Icons.restore, text: l10n.restoreFromBackup),
      ],
    );
  }

  Widget _buildPage6(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _TourPage(
      icon: Icons.color_lens,
      title: l10n.tourPage6Title,
      description: l10n.tourPage6Desc,
      features: [
        _FeatureItem(icon: Icons.palette, text: l10n.noteColors),
        _FeatureItem(icon: Icons.dark_mode, text: l10n.theme),
        _FeatureItem(icon: Icons.filter_list, text: l10n.filter),
        _FeatureItem(icon: Icons.archive, text: l10n.archive),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              7,
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
          const SizedBox(height: 24),
          if (_currentPage < 6)
            ElevatedButton(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: const Color(0xFF0A1929),
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: Text(
                l10n.next,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          if (_currentPage < 6)
            TextButton(
              onPressed: () {
                _pageController.jumpToPage(6);
              },
              child: Text(
                l10n.skip,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ),
        ],
      ),
    );
  }

  void _navigateToTransfer() async {
    await Provider.of<SettingsProvider>(context, listen: false).completeSetup();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const TransferScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _navigateToHome() async {
    await Provider.of<SettingsProvider>(context, listen: false).completeSetup();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const MainLayoutScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
      (route) => false,
    );
  }

  Widget _buildPage7(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.sync_alt, size: 80, color: Color(0xFFFFD700)),
          const SizedBox(height: 32),
          Text(
            l10n.haveSavedNotes,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.transferFromOldPhone,
            style: const TextStyle(fontSize: 16, color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          if (FlavorConfig.hasTransferFeature)
            ElevatedButton(
              onPressed: _navigateToTransfer,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: const Color(0xFF0A1929),
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              ),
              child: Text(
                l10n.yesRestoreNow,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          if (FlavorConfig.hasTransferFeature)
            const SizedBox(height: 16),
          OutlinedButton(
            onPressed: _navigateToHome,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white30),
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            ),
            child: Text(
              l10n.noStartFresh,
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    );
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
    return SafeArea(
      child: Column(
        children: [
          // 🟢 FIXED HEADER
          Container(
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
          // 🟡 SCROLLABLE BODY
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    description,
                    style: const TextStyle(fontSize: 16, color: Colors.white70, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  ...features.map((feature) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Icon(feature.icon, size: 20, color: const Color(0xFFFFD700)),
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
        ],
      ),
    );
  }
}



class _FeatureItem {
  final IconData icon;
  final String text;

  const _FeatureItem({required this.icon, required this.text});
}
