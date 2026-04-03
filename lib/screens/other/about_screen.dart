// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = '...';
  bool _isLaunching = false;

  @override
  void initState() {
    super.initState();
    _loadInfo();
  }

  Future<void> _loadInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _version = 'v${info.version}';
        });
      }
    } catch (e) {
      // Failed to load info
    }
  }

  static const _channel = MethodChannel('com.apexflow.app.sinan/launcher');

  Future<void> _launchUrl(String url) async {
    if (_isLaunching) return;
    setState(() => _isLaunching = true);
    try {
      await _channel.invokeMethod('launch', url);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLaunching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(title: Text(l10n.aboutApp)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // App Info
                Center(
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(
                          'assets/images/app_icon.png',
                          width: 100,
                          height: 100,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.note_rounded,
                                size: 80, color: Colors.blue);
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Sinan Note | سنان نوت',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _version,
                        style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.green.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified,
                                size: 14, color: Colors.green),
                            const SizedBox(width: 4),
                            Text(
                              l10n.officialVersion,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isArabic ? l10n.appTaglineAr : l10n.appTagline,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isArabic ? l10n.appTagline : l10n.appTaglineAr,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Links Section
                _buildSection(l10n.importantLinks, [
                  _buildLink(
                    l10n.appPageGooglePlay,
                    'https://play.google.com/store/apps/dev?id=5409981776310932919',
                  ),
                  _buildLink(
                    l10n.sinanAiNet,
                    'https://sinanai.net',
                  ),
                  _buildLink(
                    l10n.githubRepository,
                    'https://github.com/apexflow/sinan-note',
                  ),
                  _buildLink(
                    l10n.privacyPolicy,
                    isArabic
                        ? 'https://apexflow.now/ar/projects/sinan-note/privacy'
                        : 'https://apexflow.now/en/projects/sinan-note/privacy',
                  ),
                  _buildLink(
                    l10n.termsOfService,
                    isArabic
                        ? 'https://apexflow.now/ar/projects/sinan-note/terms'
                        : 'https://apexflow.now/en/projects/sinan-note/terms',
                  ),
                  _buildLink(l10n.licenses, null, onTap: _showLicenses),
                ]),
                const SizedBox(height: 24),

                // Legal Section
                _buildSection(l10n.legalInfo, [
                  _buildLegalText(
                    l10n.copyright,
                    l10n.copyrightText,
                  ),
                  _buildLegalText(
                    l10n.disclaimerTitle,
                    l10n.disclaimerText,
                  ),
                  _buildLegalText(
                    l10n.officialVersionTitle,
                    l10n.officialVersionText,
                  ),
                ]),
                const SizedBox(height: 24),

                // Credits Section
                _buildSection(l10n.librariesUsed, [
                  _buildCredit('Flutter', l10n.flutterFramework),
                  _buildCredit('Dart', l10n.dartLanguage),
                  _buildCredit('Provider', l10n.providerStateManagement),
                  _buildCredit('Isar', l10n.isarDatabase),
                ]),
                const SizedBox(height: 24),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    border:
                        Border.all(color: Colors.green.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified, color: Colors.green, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.officialGooglePlay,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[700],
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Footer
                Center(
                  child: Column(
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l10n.madeWithLove,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.favorite,
                              size: 14, color: Colors.red[400]),
                          const SizedBox(width: 4),
                          Text(
                            l10n.inArabWorld,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.contactEmail,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildLink(String title, String? url, {VoidCallback? onTap}) {
    final color = Theme.of(context).colorScheme.primary;
    final effectiveOnTap = onTap ?? (url != null ? () => _launchUrl(url) : null);
    return InkWell(
      onTap: _isLaunching ? null : effectiveOnTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Icon(Icons.link, size: 18, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: color,
                  decoration: TextDecoration.underline,
                  decorationColor: color,
                ),
              ),
            ),
            Icon(Icons.arrow_outward, size: 16, color: color),
          ],
        ),
      ),
    );
  }

  Widget _buildLegalText(String title, String content) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCredit(String name, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 16, color: Colors.green),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLicenses() {
    showLicensePage(
      context: context,
      applicationName: 'Sinan Note',
      applicationVersion: _version,
      applicationIcon: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.asset(
          'assets/images/app_icon.png',
          width: 64,
          height: 64,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.note_rounded, size: 64, color: Colors.blue),
        ),
      ),
    );
  }
}
