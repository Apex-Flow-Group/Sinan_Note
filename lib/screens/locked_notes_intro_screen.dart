// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import '../services/settings_provider.dart';
import '../services/biometric_service.dart';
import 'locked_notes_screen.dart';

class LockedNotesIntroScreen extends StatefulWidget {
  const LockedNotesIntroScreen({super.key});

  @override
  State<LockedNotesIntroScreen> createState() => _LockedNotesIntroScreenState();
}

class _LockedNotesIntroScreenState extends State<LockedNotesIntroScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  List<_IntroSlide> _getSlides(AppLocalizations l10n) => [
        _IntroSlide(
          icon: Icons.lock_outline,
          title: l10n.secureVault,
          description: 'مساحة مشفرة بالكامل لا يمكن الوصول إليها إلا ببصمتك.',
          color: Colors.orange,
        ),
        _IntroSlide(
          icon: Icons.file_download_outlined,
          title: l10n.importFromInside,
          description: l10n.noLockButtonsOutside,
          color: Colors.blue,
        ),
        _IntroSlide(
          icon: Icons.security,
          title: l10n.sessionProtection,
          description: l10n.dataEncryptedOnExit,
          color: Colors.green,
        ),
      ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _handleAuthenticate() async {
    final authenticated = await BiometricService.authenticate();

    if (authenticated) {
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      await settings.setLockedIntroSeen(true);

      if (mounted) {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LockedNotesScreen()),
        );
      }
    } else {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.authenticationFailed),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _nextPage() {
    final l10n = AppLocalizations.of(context)!;
    final slides = _getSlides(l10n);
    if (_currentPage < slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final slides = _getSlides(l10n);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: slides.length,
                itemBuilder: (context, index) =>
                    _buildSlide(slides[index], isDark),
              ),
            ),
            _buildIndicators(),
            _buildBottomButton(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide(_IntroSlide slide, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: slide.color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              slide.icon,
              size: 60,
              color: slide.color,
            ),
          ),
          const SizedBox(height: 40),
          Text(
            slide.title,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            slide.description,
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildIndicators() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          _getSlides(AppLocalizations.of(context)!).length,
          (index) => AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: _currentPage == index ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: _currentPage == index ? Colors.orange : Colors.grey[400],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomButton(bool isDark) {
    final slides = _getSlides(AppLocalizations.of(context)!);
    final isLastPage = _currentPage == slides.length - 1;
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton.icon(
          onPressed: isLastPage ? _handleAuthenticate : _nextPage,
          icon: Icon(isLastPage ? Icons.fingerprint : Icons.arrow_forward),
          label: Text(
            isLastPage ? l10n.authenticateAndEnter : l10n.next,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 2,
          ),
        ),
      ),
    );
  }
}

class _IntroSlide {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  _IntroSlide({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}
